/**
 * Controller class for Chess Game Viewer Lightning Web Component
 * Provides methods to retrieve game records with player information, ELO ratings,
 * PGN notation, FEN positions, and move history for rendering on the interactive chess board UI
 */
public with sharing class CHE_ChessGameViewerController {

    /**
     * Wrapper class for game data returned to the UI
     */
    public class GameData {
        @AuraEnabled public String gameId;
        @AuraEnabled public String gameName;
        @AuraEnabled public String whitePlayerName;
        @AuraEnabled public String blackPlayerName;
        @AuraEnabled public Decimal whitePlayerElo;
        @AuraEnabled public Decimal blackPlayerElo;
        @AuraEnabled public String gameStatus;
        @AuraEnabled public String gameResult;
        @AuraEnabled public String gameNotation;
        @AuraEnabled public String currentPositionFEN;
        @AuraEnabled public Decimal numberOfMoves;
        @AuraEnabled public DateTime startDateTime;
        @AuraEnabled public DateTime endDateTime;
        @AuraEnabled public String winnerName;
    }

    /**
     * Wrapper class for list of games
     */
    public class GameListItem {
        @AuraEnabled public String gameId;
        @AuraEnabled public String gameName;
        @AuraEnabled public String whitePlayerName;
        @AuraEnabled public String blackPlayerName;
        @AuraEnabled public String gameStatus;
        @AuraEnabled public String gameResult;
        @AuraEnabled public DateTime startDateTime;
    }

    /**
     * Retrieves a specific game by ID with full details
     */
    @AuraEnabled(cacheable=false)
    public static GameData getGameById(String gameId) {
        try {
            List<CHE_Chess_Game__c> games = [
                SELECT Id, Name, CHE_Game_Status__c, CHE_Game_Result__c,
                       CHE_Game_Notation__c, CHE_Current_Position_FEN__c,
                       CHE_Number_of_Moves__c, CHE_Start_Date_Time__c, CHE_End_Date_Time__c,
                       CHE_White_Player__c, CHE_White_Player__r.CHE_Player_Name__c,
                       CHE_White_Player__r.CHE_ELO_Rating__c,
                       CHE_Black_Player__c, CHE_Black_Player__r.CHE_Player_Name__c,
                       CHE_Black_Player__r.CHE_ELO_Rating__c,
                       CHE_Winner__c, CHE_Winner__r.CHE_Player_Name__c
                FROM CHE_Chess_Game__c
                WHERE Id = :gameId
                LIMIT 1
            ];

            if (games.isEmpty()) {
                return null;
            }

            return mapGameToData(games[0]);
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving game: ' + e.getMessage());
        }
    }

    /**
     * Retrieves all games with basic information
     */
    @AuraEnabled(cacheable=false)
    public static List<GameListItem> getAllGames() {
        try {
            List<CHE_Chess_Game__c> games = [
                SELECT Id, Name, CHE_Game_Status__c, CHE_Game_Result__c,
                       CHE_Start_Date_Time__c,
                       CHE_White_Player__r.CHE_Player_Name__c,
                       CHE_Black_Player__r.CHE_Player_Name__c
                FROM CHE_Chess_Game__c
                ORDER BY CreatedDate DESC
                LIMIT 100
            ];

            List<GameListItem> gameList = new List<GameListItem>();
            for (CHE_Chess_Game__c game : games) {
                gameList.add(mapGameToListItem(game));
            }

            return gameList;
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving games: ' + e.getMessage());
        }
    }

    /**
     * Retrieves completed games only
     */
    @AuraEnabled(cacheable=false)
    public static List<GameListItem> getCompletedGames() {
        try {
            List<CHE_Chess_Game__c> games = [
                SELECT Id, Name, CHE_Game_Status__c, CHE_Game_Result__c,
                       CHE_Start_Date_Time__c,
                       CHE_White_Player__r.CHE_Player_Name__c,
                       CHE_Black_Player__r.CHE_Player_Name__c
                FROM CHE_Chess_Game__c
                WHERE CHE_Game_Status__c = 'Completed'
                ORDER BY CHE_End_Date_Time__c DESC
                LIMIT 100
            ];

            List<GameListItem> gameList = new List<GameListItem>();
            for (CHE_Chess_Game__c game : games) {
                gameList.add(mapGameToListItem(game));
            }

            return gameList;
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving completed games: ' + e.getMessage());
        }
    }

    /**
     * Retrieves recent games (last 30 days)
     */
    @AuraEnabled(cacheable=false)
    public static List<GameListItem> getRecentGames() {
        try {
            Date thirtyDaysAgo = Date.today().addDays(-30);

            List<CHE_Chess_Game__c> games = [
                SELECT Id, Name, CHE_Game_Status__c, CHE_Game_Result__c,
                       CHE_Start_Date_Time__c,
                       CHE_White_Player__r.CHE_Player_Name__c,
                       CHE_Black_Player__r.CHE_Player_Name__c
                FROM CHE_Chess_Game__c
                WHERE DAY_ONLY(CHE_Start_Date_Time__c) >= :thirtyDaysAgo
                ORDER BY CHE_Start_Date_Time__c DESC
                LIMIT 100
            ];

            List<GameListItem> gameList = new List<GameListItem>();
            for (CHE_Chess_Game__c game : games) {
                gameList.add(mapGameToListItem(game));
            }

            return gameList;
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving recent games: ' + e.getMessage());
        }
    }

    /**
     * Retrieves games for a specific player
     */
    @AuraEnabled(cacheable=false)
    public static List<GameListItem> getGamesByPlayer(String playerId) {
        try {
            List<CHE_Chess_Game__c> games = [
                SELECT Id, Name, CHE_Game_Status__c, CHE_Game_Result__c,
                       CHE_Start_Date_Time__c,
                       CHE_White_Player__r.CHE_Player_Name__c,
                       CHE_Black_Player__r.CHE_Player_Name__c
                FROM CHE_Chess_Game__c
                WHERE CHE_White_Player__c = :playerId OR CHE_Black_Player__c = :playerId
                ORDER BY CHE_Start_Date_Time__c DESC
                LIMIT 100
            ];

            List<GameListItem> gameList = new List<GameListItem>();
            for (CHE_Chess_Game__c game : games) {
                gameList.add(mapGameToListItem(game));
            }

            return gameList;
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving player games: ' + e.getMessage());
        }
    }

    /**
     * Retrieves game status picklist values
     */
    @AuraEnabled(cacheable=false)
    public static List<Map<String, String>> getGameStatusPicklistValues() {
        List<Map<String, String>> options = new List<Map<String, String>>();

        Schema.DescribeFieldResult fieldResult = CHE_Chess_Game__c.CHE_Game_Status__c.getDescribe();
        List<Schema.PicklistEntry> entries = fieldResult.getPicklistValues();

        for (Schema.PicklistEntry entry : entries) {
            if (entry.isActive()) {
                options.add(new Map<String, String>{
                    'label' => entry.getLabel(),
                    'value' => entry.getValue()
                });
            }
        }

        return options;
    }

    /**
     * Retrieves game result picklist values
     */
    @AuraEnabled(cacheable=false)
    public static List<Map<String, String>> getGameResultPicklistValues() {
        List<Map<String, String>> options = new List<Map<String, String>>();

        Schema.DescribeFieldResult fieldResult = CHE_Chess_Game__c.CHE_Game_Result__c.getDescribe();
        List<Schema.PicklistEntry> entries = fieldResult.getPicklistValues();

        for (Schema.PicklistEntry entry : entries) {
            if (entry.isActive()) {
                options.add(new Map<String, String>{
                    'label' => entry.getLabel(),
                    'value' => entry.getValue()
                });
            }
        }

        return options;
    }

    /**
     * Private helper method to map game to GameData wrapper
     */
    private static GameData mapGameToData(CHE_Chess_Game__c game) {
        GameData data = new GameData();
        data.gameId = game.Id;
        data.gameName = game.Name;
        data.whitePlayerName = game.CHE_White_Player__r.CHE_Player_Name__c;
        data.blackPlayerName = game.CHE_Black_Player__r.CHE_Player_Name__c;
        data.whitePlayerElo = game.CHE_White_Player__r.CHE_ELO_Rating__c;
        data.blackPlayerElo = game.CHE_Black_Player__r.CHE_ELO_Rating__c;
        data.gameStatus = game.CHE_Game_Status__c;
        data.gameResult = game.CHE_Game_Result__c;
        data.gameNotation = game.CHE_Game_Notation__c;
        data.currentPositionFEN = game.CHE_Current_Position_FEN__c;
        data.numberOfMoves = game.CHE_Number_of_Moves__c;
        data.startDateTime = game.CHE_Start_Date_Time__c;
        data.endDateTime = game.CHE_End_Date_Time__c;
        data.winnerName = game.CHE_Winner__c != null ? game.CHE_Winner__r.CHE_Player_Name__c : null;

        return data;
    }

    /**
     * Private helper method to map game to GameListItem wrapper
     */
    private static GameListItem mapGameToListItem(CHE_Chess_Game__c game) {
        GameListItem item = new GameListItem();
        item.gameId = game.Id;
        item.gameName = game.Name;
        item.whitePlayerName = game.CHE_White_Player__r.CHE_Player_Name__c;
        item.blackPlayerName = game.CHE_Black_Player__r.CHE_Player_Name__c;
        item.gameStatus = game.CHE_Game_Status__c;
        item.gameResult = game.CHE_Game_Result__c;
        item.startDateTime = game.CHE_Start_Date_Time__c;

        return item;
    }
}
