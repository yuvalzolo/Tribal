/**
 * Handler class for Chess Game trigger that implements ELO rating calculations
 * Formula: New Rating = Old Rating + K × (Actual Score - Expected Score)
 * Updates player statistics and creates Player Rank snapshots after game completion
 */
public with sharing class CHE_ChessGameTriggerHandler {

    /**
     * Main entry point for trigger processing
     */
    public void run() {
        if (Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)) {
            handleAfterInsertUpdate(Trigger.new, Trigger.oldMap);
        }
    }

    /**
     * Processes completed games to calculate ELO ratings and update player statistics
     */
    private void handleAfterInsertUpdate(List<CHE_Chess_Game__c> newGames, Map<Id, CHE_Chess_Game__c> oldMap) {
        List<CHE_Chess_Game__c> completedGames = new List<CHE_Chess_Game__c>();

        // Collect newly completed games
        for (CHE_Chess_Game__c game : newGames) {
            Boolean isNewlyCompleted = game.CHE_Game_Status__c == 'Completed' &&
                                      (oldMap == null || oldMap.get(game.Id).CHE_Game_Status__c != 'Completed');

            if (isNewlyCompleted && game.CHE_Game_Result__c != null &&
                game.CHE_Game_Result__c != 'Abandoned' &&
                game.CHE_White_Player__c != null && game.CHE_Black_Player__c != null) {
                completedGames.add(game);
            }
        }

        if (!completedGames.isEmpty()) {
            processCompletedGames(completedGames);
        }
    }

    /**
     * Main processing logic for completed games
     */
    private void processCompletedGames(List<CHE_Chess_Game__c> completedGames) {
        // Collect all player IDs
        Set<Id> playerIds = new Set<Id>();
        for (CHE_Chess_Game__c game : completedGames) {
            playerIds.add(game.CHE_White_Player__c);
            playerIds.add(game.CHE_Black_Player__c);
        }

        // Query player records
        Map<Id, CHE_Player__c> playerMap = new Map<Id, CHE_Player__c>([
            SELECT Id, CHE_ELO_Rating__c, CHE_K_Factor__c, CHE_Wins__c,
                   CHE_Losses__c, CHE_Draws__c, CHE_Total_Games_Played__c, CHE_Win_Rate__c
            FROM CHE_Player__c
            WHERE Id IN :playerIds
        ]);

        List<CHE_Chess_Game__c> gamesToUpdate = new List<CHE_Chess_Game__c>();
        List<CHE_Player_Rank__c> rankingsToCreate = new List<CHE_Player_Rank__c>();

        // Process each completed game
        for (CHE_Chess_Game__c game : completedGames) {
            CHE_Player__c whitePlayer = playerMap.get(game.CHE_White_Player__c);
            CHE_Player__c blackPlayer = playerMap.get(game.CHE_Black_Player__c);

            if (whitePlayer == null || blackPlayer == null) {
                continue;
            }

            // Initialize default values if null
            initializePlayerDefaults(whitePlayer);
            initializePlayerDefaults(blackPlayer);

            // Capture ELO before
            Decimal whiteEloBefore = whitePlayer.CHE_ELO_Rating__c;
            Decimal blackEloBefore = blackPlayer.CHE_ELO_Rating__c;

            // Calculate ELO changes
            EloCalculationResult result = calculateEloChanges(
                whitePlayer,
                blackPlayer,
                game.CHE_Game_Result__c
            );

            // Update player ELO ratings
            whitePlayer.CHE_ELO_Rating__c = result.whiteEloAfter;
            blackPlayer.CHE_ELO_Rating__c = result.blackEloAfter;

            // Update player statistics
            updatePlayerStatistics(whitePlayer, blackPlayer, game.CHE_Game_Result__c);

            // Update game record with ELO information
            game.CHE_White_Player_ELO_Before__c = whiteEloBefore;
            game.CHE_Black_Player_ELO_Before__c = blackEloBefore;
            game.CHE_White_Player_ELO_After__c = result.whiteEloAfter;
            game.CHE_Black_Player_ELO_After__c = result.blackEloAfter;
            game.CHE_ELO_Change__c = result.eloChange;
            game.CHE_End_Date_Time__c = DateTime.now();

            gamesToUpdate.add(game);

            // Create ranking snapshots
            rankingsToCreate.add(createRankingSnapshot(whitePlayer));
            rankingsToCreate.add(createRankingSnapshot(blackPlayer));
        }

        // DML operations
        if (!playerMap.isEmpty()) {
            update playerMap.values();
        }

        if (!gamesToUpdate.isEmpty()) {
            update gamesToUpdate;
        }

        if (!rankingsToCreate.isEmpty()) {
            insert rankingsToCreate;
        }

        // Update rank positions after all rankings are created
        if (!rankingsToCreate.isEmpty()) {
            updateRankPositions();
        }
    }

    /**
     * Initializes default values for player fields if null
     */
    private void initializePlayerDefaults(CHE_Player__c player) {
        if (player.CHE_ELO_Rating__c == null) {
            player.CHE_ELO_Rating__c = 1200;
        }
        if (player.CHE_K_Factor__c == null) {
            player.CHE_K_Factor__c = 32;
        }
        if (player.CHE_Wins__c == null) {
            player.CHE_Wins__c = 0;
        }
        if (player.CHE_Losses__c == null) {
            player.CHE_Losses__c = 0;
        }
        if (player.CHE_Draws__c == null) {
            player.CHE_Draws__c = 0;
        }
        if (player.CHE_Total_Games_Played__c == null) {
            player.CHE_Total_Games_Played__c = 0;
        }
    }

    /**
     * Calculates ELO rating changes for both players
     * Formula: New Rating = Old Rating + K × (Actual Score - Expected Score)
     * Expected Score: E = 1 / (1 + 10^((opponent_rating - player_rating)/400))
     */
    private EloCalculationResult calculateEloChanges(CHE_Player__c whitePlayer, CHE_Player__c blackPlayer, String gameResult) {
        Decimal whiteElo = whitePlayer.CHE_ELO_Rating__c;
        Decimal blackElo = blackPlayer.CHE_ELO_Rating__c;
        Decimal whiteK = whitePlayer.CHE_K_Factor__c;
        Decimal blackK = blackPlayer.CHE_K_Factor__c;

        // Calculate expected scores
        Decimal whiteExpected = calculateExpectedScore(whiteElo, blackElo);
        Decimal blackExpected = calculateExpectedScore(blackElo, whiteElo);

        // Determine actual scores
        Decimal whiteActual = 0;
        Decimal blackActual = 0;

        if (gameResult == 'White_Wins') {
            whiteActual = 1;
            blackActual = 0;
        } else if (gameResult == 'Black_Wins') {
            whiteActual = 0;
            blackActual = 1;
        } else if (gameResult == 'Draw') {
            whiteActual = 0.5;
            blackActual = 0.5;
        }

        // Calculate new ELO ratings
        Decimal whiteChange = whiteK * (whiteActual - whiteExpected);
        Decimal blackChange = blackK * (blackActual - blackExpected);

        Decimal whiteEloAfter = whiteElo + whiteChange;
        Decimal blackEloAfter = blackElo + blackChange;

        // Round to nearest integer
        whiteEloAfter = whiteEloAfter.round(System.RoundingMode.HALF_UP);
        blackEloAfter = blackEloAfter.round(System.RoundingMode.HALF_UP);

        // Calculate ELO change (positive value for winner or 0 for draw)
        Decimal eloChange = 0;
        if (gameResult == 'White_Wins') {
            eloChange = Math.abs(whiteChange.round(System.RoundingMode.HALF_UP));
        } else if (gameResult == 'Black_Wins') {
            eloChange = Math.abs(blackChange.round(System.RoundingMode.HALF_UP));
        }

        EloCalculationResult result = new EloCalculationResult();
        result.whiteEloAfter = whiteEloAfter;
        result.blackEloAfter = blackEloAfter;
        result.eloChange = eloChange;

        return result;
    }

    /**
     * Calculates expected score for a player
     * Formula: E = 1 / (1 + 10^((opponent_rating - player_rating)/400))
     */
    private Decimal calculateExpectedScore(Decimal playerElo, Decimal opponentElo) {
        Decimal exponent = (opponentElo - playerElo) / 400;
        Decimal powerResult = Math.pow(10, exponent);
        return 1 / (1 + powerResult);
    }

    /**
     * Updates player statistics (wins, losses, draws, total games, win rate)
     */
    private void updatePlayerStatistics(CHE_Player__c whitePlayer, CHE_Player__c blackPlayer, String gameResult) {
        // Update white player statistics
        whitePlayer.CHE_Total_Games_Played__c += 1;
        if (gameResult == 'White_Wins') {
            whitePlayer.CHE_Wins__c += 1;
        } else if (gameResult == 'Black_Wins') {
            whitePlayer.CHE_Losses__c += 1;
        } else if (gameResult == 'Draw') {
            whitePlayer.CHE_Draws__c += 1;
        }

        // Update black player statistics
        blackPlayer.CHE_Total_Games_Played__c += 1;
        if (gameResult == 'Black_Wins') {
            blackPlayer.CHE_Wins__c += 1;
        } else if (gameResult == 'White_Wins') {
            blackPlayer.CHE_Losses__c += 1;
        } else if (gameResult == 'Draw') {
            blackPlayer.CHE_Draws__c += 1;
        }

        // Calculate win rates
        if (whitePlayer.CHE_Total_Games_Played__c > 0) {
            whitePlayer.CHE_Win_Rate__c = (whitePlayer.CHE_Wins__c / whitePlayer.CHE_Total_Games_Played__c);
        }

        if (blackPlayer.CHE_Total_Games_Played__c > 0) {
            blackPlayer.CHE_Win_Rate__c = (blackPlayer.CHE_Wins__c / blackPlayer.CHE_Total_Games_Played__c);
        }
    }

    /**
     * Creates a ranking snapshot for a player
     */
    private CHE_Player_Rank__c createRankingSnapshot(CHE_Player__c player) {
        CHE_Player_Rank__c ranking = new CHE_Player_Rank__c();
        ranking.CHE_Player__c = player.Id;
        ranking.CHE_ELO_Rating__c = player.CHE_ELO_Rating__c;
        ranking.CHE_Rank_Date__c = Date.today();
        ranking.CHE_Games_Played__c = player.CHE_Total_Games_Played__c;
        ranking.CHE_Win_Rate__c = player.CHE_Win_Rate__c;

        return ranking;
    }

    /**
     * Updates rank positions for all rankings created today
     */
    private void updateRankPositions() {
        // Get all active players with their latest rankings
        List<CHE_Player__c> activePlayers = [
            SELECT Id, CHE_ELO_Rating__c, CHE_Active_Player__c
            FROM CHE_Player__c
            WHERE CHE_Active_Player__c = true
            ORDER BY CHE_ELO_Rating__c DESC NULLS LAST
        ];

        // Get today's rankings
        List<CHE_Player_Rank__c> todaysRankings = [
            SELECT Id, CHE_Player__c
            FROM CHE_Player_Rank__c
            WHERE CHE_Rank_Date__c = TODAY
        ];

        // Create map for quick lookup
        Map<Id, CHE_Player_Rank__c> playerToRankingMap = new Map<Id, CHE_Player_Rank__c>();
        for (CHE_Player_Rank__c ranking : todaysRankings) {
            playerToRankingMap.put(ranking.CHE_Player__c, ranking);
        }

        // Assign rank positions
        List<CHE_Player_Rank__c> rankingsToUpdate = new List<CHE_Player_Rank__c>();
        Integer position = 1;

        for (CHE_Player__c player : activePlayers) {
            if (playerToRankingMap.containsKey(player.Id)) {
                CHE_Player_Rank__c ranking = playerToRankingMap.get(player.Id);
                ranking.CHE_Rank_Position__c = position;
                rankingsToUpdate.add(ranking);
            }
            position++;
        }

        if (!rankingsToUpdate.isEmpty()) {
            update rankingsToUpdate;
        }
    }

    /**
     * Wrapper class to hold ELO calculation results
     */
    private class EloCalculationResult {
        public Decimal whiteEloAfter;
        public Decimal blackEloAfter;
        public Decimal eloChange;
    }
}
