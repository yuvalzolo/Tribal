/**
 * Trigger on Chess Game object that delegates to ChessGameTriggerHandler
 * Processes game completions, calculates ELO ratings, updates player statistics,
 * and creates ranking snapshots
 */
trigger CHE_ChessGameTrigger on CHE_Chess_Game__c (after insert, after update) {
    new CHE_ChessGameTriggerHandler().run();
}
