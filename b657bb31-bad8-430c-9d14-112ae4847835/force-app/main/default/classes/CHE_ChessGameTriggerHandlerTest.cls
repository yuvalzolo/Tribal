/**
 * Test class for CHE_ChessGameTriggerHandler
 * Tests ELO calculations, player statistics updates, and ranking snapshots
 */
@isTest
private with sharing class CHE_ChessGameTriggerHandlerTest {

    /**
     * Creates test data for multiple test methods
     */
    @TestSetup
    static void setupTestData() {
        // Create test players
        List<CHE_Player__c> players = new List<CHE_Player__c>();

        CHE_Player__c player1 = new CHE_Player__c(
            CHE_Player_Name__c = 'Magnus Carlsen',
            CHE_Email__c = 'magnus@chess.com',
            CHE_ELO_Rating__c = 2850,
            CHE_K_Factor__c = 16,
            CHE_Active_Player__c = true,
            CHE_Registration_Date__c = Date.today().addDays(-365),
            CHE_Wins__c = 50,
            CHE_Losses__c = 10,
            CHE_Draws__c = 20,
            CHE_Total_Games_Played__c = 80
        );
        players.add(player1);

        CHE_Player__c player2 = new CHE_Player__c(
            CHE_Player_Name__c = 'Hikaru Nakamura',
            CHE_Email__c = 'hikaru@chess.com',
            CHE_ELO_Rating__c = 2800,
            CHE_K_Factor__c = 16,
            CHE_Active_Player__c = true,
            CHE_Registration_Date__c = Date.today().addDays(-300),
            CHE_Wins__c = 40,
            CHE_Losses__c = 15,
            CHE_Draws__c = 25,
            CHE_Total_Games_Played__c = 80
        );
        players.add(player2);

        CHE_Player__c player3 = new CHE_Player__c(
            CHE_Player_Name__c = 'Fabiano Caruana',
            CHE_Email__c = 'fabiano@chess.com',
            CHE_ELO_Rating__c = 2750,
            CHE_K_Factor__c = 32,
            CHE_Active_Player__c = true,
            CHE_Registration_Date__c = Date.today().addDays(-180)
        );
        players.add(player3);

        insert players;
    }

    /**
     * Tests white player winning scenario
     */
    @isTest
    static void testWhitePlayerWins() {
        // Get test players
        CHE_Player__c whitePlayer = [SELECT Id, CHE_ELO_Rating__c, CHE_Wins__c, CHE_Total_Games_Played__c
                                      FROM CHE_Player__c WHERE CHE_Player_Name__c = 'Magnus Carlsen' LIMIT 1];
        CHE_Player__c blackPlayer = [SELECT Id, CHE_ELO_Rating__c, CHE_Losses__c, CHE_Total_Games_Played__c
                                      FROM CHE_Player__c WHERE CHE_Player_Name__c = 'Hikaru Nakamura' LIMIT 1];

        Decimal whiteEloBefore = whitePlayer.CHE_ELO_Rating__c;
        Decimal blackEloBefore = blackPlayer.CHE_ELO_Rating__c;
        Decimal whiteWinsBefore = whitePlayer.CHE_Wins__c;
        Decimal blackLossesBefore = blackPlayer.CHE_Losses__c;

        Test.startTest();

        // Create and complete a game
        CHE_Chess_Game__c game = new CHE_Chess_Game__c(
            CHE_White_Player__c = whitePlayer.Id,
            CHE_Black_Player__c = blackPlayer.Id,
            CHE_Game_Status__c = 'Scheduled',
            CHE_Start_Date_Time__c = DateTime.now().addHours(-2)
        );
        insert game;

        // Complete the game with white win
        game.CHE_Game_Status__c = 'Completed';
        game.CHE_Game_Result__c = 'White_Wins';
        game.CHE_Winner__c = whitePlayer.Id;
        update game;

        Test.stopTest();

        // Verify game record updates
        CHE_Chess_Game__c updatedGame = [SELECT Id, CHE_White_Player_ELO_Before__c, CHE_Black_Player_ELO_Before__c,
                                         CHE_White_Player_ELO_After__c, CHE_Black_Player_ELO_After__c,
                                         CHE_ELO_Change__c, CHE_End_Date_Time__c
                                         FROM CHE_Chess_Game__c WHERE Id = :game.Id];

        System.assertEquals(whiteEloBefore, updatedGame.CHE_White_Player_ELO_Before__c, 'White ELO before should be captured');
        System.assertEquals(blackEloBefore, updatedGame.CHE_Black_Player_ELO_Before__c, 'Black ELO before should be captured');
        System.assertNotEquals(null, updatedGame.CHE_White_Player_ELO_After__c, 'White ELO after should be set');
        System.assertNotEquals(null, updatedGame.CHE_Black_Player_ELO_After__c, 'Black ELO after should be set');
        System.assert(updatedGame.CHE_ELO_Change__c >= 0, 'ELO change should be non-negative');
        System.assertNotEquals(null, updatedGame.CHE_End_Date_Time__c, 'End date time should be set');

        // Verify player statistics
        CHE_Player__c updatedWhite = [SELECT CHE_ELO_Rating__c, CHE_Wins__c, CHE_Total_Games_Played__c, CHE_Win_Rate__c
                                      FROM CHE_Player__c WHERE Id = :whitePlayer.Id];
        CHE_Player__c updatedBlack = [SELECT CHE_ELO_Rating__c, CHE_Losses__c, CHE_Total_Games_Played__c
                                      FROM CHE_Player__c WHERE Id = :blackPlayer.Id];

        System.assert(updatedWhite.CHE_ELO_Rating__c > whiteEloBefore, 'White ELO should increase');
        System.assert(updatedBlack.CHE_ELO_Rating__c < blackEloBefore, 'Black ELO should decrease');
        System.assertEquals(whiteWinsBefore + 1, updatedWhite.CHE_Wins__c, 'White wins should increment');
        System.assertEquals(blackLossesBefore + 1, updatedBlack.CHE_Losses__c, 'Black losses should increment');
        System.assertNotEquals(null, updatedWhite.CHE_Win_Rate__c, 'Win rate should be calculated');

        // Verify ranking snapshots were created
        List<CHE_Player_Rank__c> rankings = [SELECT Id, CHE_Player__c, CHE_Rank_Position__c, CHE_ELO_Rating__c
                                             FROM CHE_Player_Rank__c
                                             WHERE CHE_Rank_Date__c = TODAY];

        System.assertEquals(2, rankings.size(), 'Two ranking snapshots should be created');
    }

    /**
     * Tests black player winning scenario
     */
    @isTest
    static void testBlackPlayerWins() {
        CHE_Player__c whitePlayer = [SELECT Id, CHE_ELO_Rating__c FROM CHE_Player__c
                                      WHERE CHE_Player_Name__c = 'Hikaru Nakamura' LIMIT 1];
        CHE_Player__c blackPlayer = [SELECT Id, CHE_ELO_Rating__c FROM CHE_Player__c
                                      WHERE CHE_Player_Name__c = 'Magnus Carlsen' LIMIT 1];

        Decimal whiteEloBefore = whitePlayer.CHE_ELO_Rating__c;
        Decimal blackEloBefore = blackPlayer.CHE_ELO_Rating__c;

        Test.startTest();

        CHE_Chess_Game__c game = new CHE_Chess_Game__c(
            CHE_White_Player__c = whitePlayer.Id,
            CHE_Black_Player__c = blackPlayer.Id,
            CHE_Game_Status__c = 'Completed',
            CHE_Game_Result__c = 'Black_Wins',
            CHE_Winner__c = blackPlayer.Id,
            CHE_Start_Date_Time__c = DateTime.now().addHours(-1)
        );
        insert game;

        Test.stopTest();

        // Verify player ELO changes
        CHE_Player__c updatedWhite = [SELECT CHE_ELO_Rating__c, CHE_Losses__c FROM CHE_Player__c WHERE Id = :whitePlayer.Id];
        CHE_Player__c updatedBlack = [SELECT CHE_ELO_Rating__c, CHE_Wins__c FROM CHE_Player__c WHERE Id = :blackPlayer.Id];

        System.assert(updatedWhite.CHE_ELO_Rating__c < whiteEloBefore, 'White ELO should decrease');
        System.assert(updatedBlack.CHE_ELO_Rating__c > blackEloBefore, 'Black ELO should increase');
        System.assertEquals(51, updatedBlack.CHE_Wins__c, 'Black wins should increment');
        System.assertEquals(16, updatedWhite.CHE_Losses__c, 'White losses should increment');
    }

    /**
     * Tests draw scenario
     */
    @isTest
    static void testDrawGame() {
        CHE_Player__c whitePlayer = [SELECT Id, CHE_ELO_Rating__c FROM CHE_Player__c
                                      WHERE CHE_Player_Name__c = 'Magnus Carlsen' LIMIT 1];
        CHE_Player__c blackPlayer = [SELECT Id, CHE_ELO_Rating__c FROM CHE_Player__c
                                      WHERE CHE_Player_Name__c = 'Hikaru Nakamura' LIMIT 1];

        Decimal whiteEloBefore = whitePlayer.CHE_ELO_Rating__c;
        Decimal blackEloBefore = blackPlayer.CHE_ELO_Rating__c;

        Test.startTest();

        CHE_Chess_Game__c game = new CHE_Chess_Game__c(
            CHE_White_Player__c = whitePlayer.Id,
            CHE_Black_Player__c = blackPlayer.Id,
            CHE_Game_Status__c = 'Completed',
            CHE_Game_Result__c = 'Draw',
            CHE_Start_Date_Time__c = DateTime.now().addHours(-3)
        );
        insert game;

        Test.stopTest();

        // Verify game record
        CHE_Chess_Game__c updatedGame = [SELECT CHE_ELO_Change__c FROM CHE_Chess_Game__c WHERE Id = :game.Id];
        System.assertEquals(0, updatedGame.CHE_ELO_Change__c, 'ELO change should be 0 for draw');

        // Verify player statistics
        CHE_Player__c updatedWhite = [SELECT CHE_Draws__c FROM CHE_Player__c WHERE Id = :whitePlayer.Id];
        CHE_Player__c updatedBlack = [SELECT CHE_Draws__c FROM CHE_Player__c WHERE Id = :blackPlayer.Id];

        System.assertEquals(21, updatedWhite.CHE_Draws__c, 'White draws should increment');
        System.assertEquals(26, updatedBlack.CHE_Draws__c, 'Black draws should increment');
    }

    /**
     * Tests abandoned game does not affect ELO
     */
    @isTest
    static void testAbandonedGameNoEloChange() {
        CHE_Player__c whitePlayer = [SELECT Id, CHE_ELO_Rating__c, CHE_Total_Games_Played__c
                                      FROM CHE_Player__c WHERE CHE_Player_Name__c = 'Magnus Carlsen' LIMIT 1];
        CHE_Player__c blackPlayer = [SELECT Id, CHE_ELO_Rating__c, CHE_Total_Games_Played__c
                                      FROM CHE_Player__c WHERE CHE_Player_Name__c = 'Hikaru Nakamura' LIMIT 1];

        Decimal whiteEloBefore = whitePlayer.CHE_ELO_Rating__c;
        Decimal whiteTotalGamesBefore = whitePlayer.CHE_Total_Games_Played__c;

        Test.startTest();

        CHE_Chess_Game__c game = new CHE_Chess_Game__c(
            CHE_White_Player__c = whitePlayer.Id,
            CHE_Black_Player__c = blackPlayer.Id,
            CHE_Game_Status__c = 'Completed',
            CHE_Game_Result__c = 'Abandoned',
            CHE_Start_Date_Time__c = DateTime.now().addHours(-1)
        );
        insert game;

        Test.stopTest();

        // Verify no ELO changes
        CHE_Player__c updatedWhite = [SELECT CHE_ELO_Rating__c, CHE_Total_Games_Played__c
                                      FROM CHE_Player__c WHERE Id = :whitePlayer.Id];

        System.assertEquals(whiteEloBefore, updatedWhite.CHE_ELO_Rating__c, 'ELO should not change for abandoned game');
        System.assertEquals(whiteTotalGamesBefore, updatedWhite.CHE_Total_Games_Played__c, 'Total games should not change');

        // Verify game record has no ELO data
        CHE_Chess_Game__c updatedGame = [SELECT CHE_White_Player_ELO_Before__c FROM CHE_Chess_Game__c WHERE Id = :game.Id];
        System.assertEquals(null, updatedGame.CHE_White_Player_ELO_Before__c, 'ELO before should not be set for abandoned game');
    }

    /**
     * Tests new player with default values
     */
    @isTest
    static void testNewPlayerWithDefaults() {
        CHE_Player__c existingPlayer = [SELECT Id FROM CHE_Player__c WHERE CHE_Player_Name__c = 'Magnus Carlsen' LIMIT 1];

        // Create new player with minimal data
        CHE_Player__c newPlayer = new CHE_Player__c(
            CHE_Player_Name__c = 'Bobby Fischer',
            CHE_Active_Player__c = true
        );
        insert newPlayer;

        Test.startTest();

        CHE_Chess_Game__c game = new CHE_Chess_Game__c(
            CHE_White_Player__c = newPlayer.Id,
            CHE_Black_Player__c = existingPlayer.Id,
            CHE_Game_Status__c = 'Completed',
            CHE_Game_Result__c = 'White_Wins',
            CHE_Winner__c = newPlayer.Id
        );
        insert game;

        Test.stopTest();

        // Verify defaults were applied
        CHE_Player__c updatedNewPlayer = [SELECT CHE_ELO_Rating__c, CHE_K_Factor__c, CHE_Wins__c, CHE_Total_Games_Played__c
                                          FROM CHE_Player__c WHERE Id = :newPlayer.Id];

        System.assertNotEquals(null, updatedNewPlayer.CHE_ELO_Rating__c, 'ELO should be set');
        System.assertEquals(1, updatedNewPlayer.CHE_Wins__c, 'Wins should be 1');
        System.assertEquals(1, updatedNewPlayer.CHE_Total_Games_Played__c, 'Total games should be 1');
    }

    /**
     * Tests bulk game processing
     */
    @isTest
    static void testBulkGameProcessing() {
        List<CHE_Player__c> players = [SELECT Id FROM CHE_Player__c LIMIT 3];

        Test.startTest();

        List<CHE_Chess_Game__c> games = new List<CHE_Chess_Game__c>();

        // Create multiple games
        for (Integer i = 0; i < 50; i++) {
            CHE_Chess_Game__c game = new CHE_Chess_Game__c(
                CHE_White_Player__c = players[0].Id,
                CHE_Black_Player__c = players[1].Id,
                CHE_Game_Status__c = 'Completed',
                CHE_Game_Result__c = Math.mod(i, 2) == 0 ? 'White_Wins' : 'Black_Wins',
                CHE_Winner__c = Math.mod(i, 2) == 0 ? players[0].Id : players[1].Id
            );
            games.add(game);
        }

        insert games;

        Test.stopTest();

        // Verify all games processed
        List<CHE_Chess_Game__c> processedGames = [SELECT Id, CHE_White_Player_ELO_After__c
                                                   FROM CHE_Chess_Game__c
                                                   WHERE Id IN :games];

        System.assertEquals(50, processedGames.size(), 'All games should be processed');

        for (CHE_Chess_Game__c game : processedGames) {
            System.assertNotEquals(null, game.CHE_White_Player_ELO_After__c, 'ELO should be calculated for each game');
        }
    }

    /**
     * Tests rank position calculation
     */
    @isTest
    static void testRankPositionCalculation() {
        List<CHE_Player__c> players = [SELECT Id FROM CHE_Player__c ORDER BY CHE_ELO_Rating__c DESC];

        Test.startTest();

        // Create games to generate rankings
        CHE_Chess_Game__c game = new CHE_Chess_Game__c(
            CHE_White_Player__c = players[0].Id,
            CHE_Black_Player__c = players[1].Id,
            CHE_Game_Status__c = 'Completed',
            CHE_Game_Result__c = 'Draw'
        );
        insert game;

        Test.stopTest();

        // Verify rank positions are assigned
        List<CHE_Player_Rank__c> rankings = [SELECT Id, CHE_Rank_Position__c, CHE_Player__c
                                             FROM CHE_Player_Rank__c
                                             WHERE CHE_Rank_Date__c = TODAY
                                             ORDER BY CHE_Rank_Position__c];

        System.assertEquals(2, rankings.size(), 'Two rankings should exist');
        System.assertNotEquals(null, rankings[0].CHE_Rank_Position__c, 'Rank position should be set');
        System.assert(rankings[0].CHE_Rank_Position__c < rankings[1].CHE_Rank_Position__c, 'Ranks should be ordered');
    }

    /**
     * Tests updating existing completed game (should not reprocess)
     */
    @isTest
    static void testUpdateExistingCompletedGame() {
        CHE_Player__c whitePlayer = [SELECT Id, CHE_ELO_Rating__c FROM CHE_Player__c
                                      WHERE CHE_Player_Name__c = 'Magnus Carlsen' LIMIT 1];
        CHE_Player__c blackPlayer = [SELECT Id, CHE_ELO_Rating__c FROM CHE_Player__c
                                      WHERE CHE_Player_Name__c = 'Hikaru Nakamura' LIMIT 1];

        // Create completed game
        CHE_Chess_Game__c game = new CHE_Chess_Game__c(
            CHE_White_Player__c = whitePlayer.Id,
            CHE_Black_Player__c = blackPlayer.Id,
            CHE_Game_Status__c = 'Completed',
            CHE_Game_Result__c = 'White_Wins',
            CHE_Winner__c = whitePlayer.Id
        );
        insert game;

        Decimal whiteEloAfterFirstComplete = [SELECT CHE_ELO_Rating__c FROM CHE_Player__c WHERE Id = :whitePlayer.Id].CHE_ELO_Rating__c;

        Test.startTest();

        // Update the game (but status already completed)
        game.CHE_Number_of_Moves__c = 45;
        update game;

        Test.stopTest();

        // Verify ELO did not change again
        Decimal whiteEloAfterUpdate = [SELECT CHE_ELO_Rating__c FROM CHE_Player__c WHERE Id = :whitePlayer.Id].CHE_ELO_Rating__c;
        System.assertEquals(whiteEloAfterFirstComplete, whiteEloAfterUpdate, 'ELO should not change on subsequent updates');
    }
}
