public with sharing class ChessGameHelper {

    public static List<Chess_Game__c> getActiveGames(Id playerId) {
        return [
            SELECT Id, Name, White_Player__c, Black_Player__c, Status__c, Current_Turn__c
            FROM Chess_Game__c
            WHERE (White_Player__c = :playerId OR Black_Player__c = :playerId)
            AND Status__c = 'Active'
            ORDER BY CreatedDate DESC
        ];
    }

    public static Chess_Game__c createGame(Id whitePlayerId, Id blackPlayerId) {
        Chess_Game__c game = new Chess_Game__c(
            White_Player__c = whitePlayerId,
            Black_Player__c = blackPlayerId,
            Status__c = 'Active',
            Current_Turn__c = 'White'
        );
        insert game;
        return game;
    }

    public static void recordMove(Id gameId, String fromSquare, String toSquare, String piece) {
        Chess_Move__c move = new Chess_Move__c(
            Game__c = gameId,
            From_Square__c = fromSquare,
            To_Square__c = toSquare,
            Piece__c = piece,
            Move_Time__c = DateTime.now()
        );
        insert move;
    }

    public static void endGame(Id gameId, String result) {
        Chess_Game__c game = new Chess_Game__c(
            Id = gameId,
            Status__c = 'Completed',
            Result__c = result
        );
        update game;
    }
}
