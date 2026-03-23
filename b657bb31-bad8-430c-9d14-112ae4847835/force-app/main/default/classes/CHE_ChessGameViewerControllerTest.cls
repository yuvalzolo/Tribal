/**
 * Test class for CHE_ChessGameViewerController
 * Tests data retrieval methods for the Chess Game Viewer LWC
 */
@isTest
private with sharing class CHE_ChessGameViewerControllerTest {

    @TestSetup
    static void setupTestData() {
        // Create test players
        CHE_Player__c player1 = new CHE_Player__c(
            CHE_Player_Name__c = 'Garry Kasparov',
            CHE_Email__c = 'garry@chess.com',
            CHE_ELO_Rating__c = 2900,
            CHE_Active_Player__c = true
        );
        insert player1;

        CHE_Player__c player2 = new CHE_Player__c(
            CHE_Player_Name__c = 'Anatoly Karpov',
            CHE_Email__c = 'anatoly@chess.com',
            CHE_ELO_Rating__c = 2850,
            CHE_Active_Player__c = true
        );
        insert player2;

        // Create test games
        List<CHE_Chess_Game__c> games = new List<CHE_Chess_Game__c>();

        CHE_Chess_Game__c game1 = new CHE_Chess_Game__c(
            CHE_White_Player__c = player1.Id,
            CHE_Black_Player__c = player2.Id,
            CHE_Game_Status__c = 'Completed',
            CHE_Game_Result__c = 'White_Wins',
            CHE_Winner__c = player1.Id,
            CHE_Start_Date_Time__c = DateTime.now().addDays(-1),
            CHE_End_Date_Time__c = DateTime.now().addDays(-1).addHours(2),
            CHE_Game_Notation__c = '1. e4 e5 2. Nf3 Nc6 3. Bb5',
            CHE_Current_Position_FEN__c = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
            CHE_Number_of_Moves__c = 45
        );
        games.add(game1);

        CHE_Chess_Game__c game2 = new CHE_Chess_Game__c(
            CHE_White_Player__c = player2.Id,
            CHE_Black_Player__c = player1.Id,
            CHE_Game_Status__c = 'In_Progress',
            CHE_Start_Date_Time__c = DateTime.now().addHours(-3),
            CHE_Game_Notation__c = '1. d4 d5 2. c4',
            CHE_Current_Position_FEN__c = 'rnbqkbnr/ppp1pppp/8/3p4/2PP4/8/PP2PPPP/RNBQKBNR b KQkq c3 0 2',
            CHE_Number_of_Moves__c = 10
        );
        games.add(game2);

        CHE_Chess_Game__c game3 = new CHE_Chess_Game__c(
            CHE_White_Player__c = player1.Id,
            CHE_Black_Player__c = player2.Id,
            CHE_Game_Status__c = 'Completed',
            CHE_Game_Result__c = 'Draw',
            CHE_Start_Date_Time__c = DateTime.now().addDays(-40),
            CHE_End_Date_Time__c = DateTime.now().addDays(-40).addHours(4),
            CHE_Game_Notation__c = '1. e4 e5 2. Nf3 Nf6',
            CHE_Number_of_Moves__c = 60
        );
        games.add(game3);

        insert games;
    }

    @isTest
    static void testGetGameById() {
        CHE_Chess_Game__c game = [SELECT Id FROM CHE_Chess_Game__c LIMIT 1];

        Test.startTest();
        CHE_ChessGameViewerController.GameData result = CHE_ChessGameViewerController.getGameById(game.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Game data should be returned');
        System.assertNotEquals(null, result.gameId, 'Game ID should be set');
        System.assertNotEquals(null, result.whitePlayerName, 'White player name should be set');
        System.assertNotEquals(null, result.blackPlayerName, 'Black player name should be set');
        System.assertNotEquals(null, result.whitePlayerElo, 'White player ELO should be set');
        System.assertNotEquals(null, result.blackPlayerElo, 'Black player ELO should be set');
    }

    @isTest
    static void testGetGameByIdNotFound() {
        Test.startTest();
        CHE_ChessGameViewerController.GameData result = CHE_ChessGameViewerController.getGameById('001000000000000');
        Test.stopTest();

        System.assertEquals(null, result, 'Should return null for non-existent game');
    }

    @isTest
    static void testGetAllGames() {
        Test.startTest();
        List<CHE_ChessGameViewerController.GameListItem> result = CHE_ChessGameViewerController.getAllGames();
        Test.stopTest();

        System.assertNotEquals(null, result, 'Game list should be returned');
        System.assertEquals(3, result.size(), 'Should return all 3 games');

        for (CHE_ChessGameViewerController.GameListItem item : result) {
            System.assertNotEquals(null, item.gameId, 'Game ID should be set');
            System.assertNotEquals(null, item.gameName, 'Game name should be set');
        }
    }

    @isTest
    static void testGetCompletedGames() {
        Test.startTest();
        List<CHE_ChessGameViewerController.GameListItem> result = CHE_ChessGameViewerController.getCompletedGames();
        Test.stopTest();

        System.assertNotEquals(null, result, 'Game list should be returned');
        System.assertEquals(2, result.size(), 'Should return only completed games');

        for (CHE_ChessGameViewerController.GameListItem item : result) {
            System.assertEquals('Completed', item.gameStatus, 'All games should be completed');
        }
    }

    @isTest
    static void testGetRecentGames() {
        Test.startTest();
        List<CHE_ChessGameViewerController.GameListItem> result = CHE_ChessGameViewerController.getRecentGames();
        Test.stopTest();

        System.assertNotEquals(null, result, 'Game list should be returned');
        System.assertEquals(2, result.size(), 'Should return only recent games (last 30 days)');
    }

    @isTest
    static void testGetGamesByPlayer() {
        CHE_Player__c player = [SELECT Id FROM CHE_Player__c WHERE CHE_Player_Name__c = 'Garry Kasparov' LIMIT 1];

        Test.startTest();
        List<CHE_ChessGameViewerController.GameListItem> result = CHE_ChessGameViewerController.getGamesByPlayer(player.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Game list should be returned');
        System.assertEquals(3, result.size(), 'Should return all games for this player');
    }

    @isTest
    static void testGetGameStatusPicklistValues() {
        Test.startTest();
        List<Map<String, String>> result = CHE_ChessGameViewerController.getGameStatusPicklistValues();
        Test.stopTest();

        System.assertNotEquals(null, result, 'Picklist values should be returned');
        System.assert(result.size() > 0, 'Should have at least one status value');

        Boolean hasCompletedStatus = false;
        for (Map<String, String> option : result) {
            if (option.get('value') == 'Completed') {
                hasCompletedStatus = true;
                System.assertNotEquals(null, option.get('label'), 'Label should be set');
            }
        }
        System.assert(hasCompletedStatus, 'Should include Completed status');
    }

    @isTest
    static void testGetGameResultPicklistValues() {
        Test.startTest();
        List<Map<String, String>> result = CHE_ChessGameViewerController.getGameResultPicklistValues();
        Test.stopTest();

        System.assertNotEquals(null, result, 'Picklist values should be returned');
        System.assert(result.size() > 0, 'Should have at least one result value');

        Boolean hasWhiteWinsResult = false;
        for (Map<String, String> option : result) {
            if (option.get('value') == 'White_Wins') {
                hasWhiteWinsResult = true;
                System.assertNotEquals(null, option.get('label'), 'Label should be set');
            }
        }
        System.assert(hasWhiteWinsResult, 'Should include White Wins result');
    }

    @isTest
    static void testGetGameByIdWithWinner() {
        CHE_Chess_Game__c game = [SELECT Id FROM CHE_Chess_Game__c WHERE CHE_Game_Result__c = 'White_Wins' LIMIT 1];

        Test.startTest();
        CHE_ChessGameViewerController.GameData result = CHE_ChessGameViewerController.getGameById(game.Id);
        Test.stopTest();

        System.assertNotEquals(null, result.winnerName, 'Winner name should be set for completed game with winner');
        System.assertEquals('Garry Kasparov', result.winnerName, 'Winner name should match');
    }

    @isTest
    static void testGetGameByIdWithoutWinner() {
        CHE_Chess_Game__c game = [SELECT Id FROM CHE_Chess_Game__c WHERE CHE_Game_Result__c = 'Draw' LIMIT 1];

        Test.startTest();
        CHE_ChessGameViewerController.GameData result = CHE_ChessGameViewerController.getGameById(game.Id);
        Test.stopTest();

        System.assertEquals(null, result.winnerName, 'Winner name should be null for draw');
    }

    @isTest
    static void testGetGameByIdWithGameNotation() {
        CHE_Chess_Game__c game = [SELECT Id FROM CHE_Chess_Game__c WHERE CHE_Game_Notation__c != null LIMIT 1];

        Test.startTest();
        CHE_ChessGameViewerController.GameData result = CHE_ChessGameViewerController.getGameById(game.Id);
        Test.stopTest();

        System.assertNotEquals(null, result.gameNotation, 'Game notation should be set');
        System.assert(result.gameNotation.contains('e4') || result.gameNotation.contains('d4'), 'Game notation should contain moves');
    }

    @isTest
    static void testGetGameByIdWithFENPosition() {
        CHE_Chess_Game__c game = [SELECT Id FROM CHE_Chess_Game__c WHERE CHE_Current_Position_FEN__c != null LIMIT 1];

        Test.startTest();
        CHE_ChessGameViewerController.GameData result = CHE_ChessGameViewerController.getGameById(game.Id);
        Test.stopTest();

        System.assertNotEquals(null, result.currentPositionFEN, 'FEN position should be set');
    }
}
