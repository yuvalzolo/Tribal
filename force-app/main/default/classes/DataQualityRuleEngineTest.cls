@isTest
private class DataQualityRuleEngineTest {

    @isTest
    static void testDetectLeadIssues() {
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Status = 'Qualified',
            Company = null
        );
        insert testLead;

        DataQualityRuleEngine.DetectionRequest request = new DataQualityRuleEngine.DetectionRequest();
        request.objectType = 'Lead';
        request.recordIds = new List<String>{ testLead.Id };

        Test.startTest();
        List<DataQualityRuleEngine.DetectionResult> results = DataQualityRuleEngine.detectDataQualityIssues(
            new List<DataQualityRuleEngine.DetectionRequest>{ request }
        );
        Test.stopTest();

        System.assertNotEquals(null, results, 'Results should not be null');
        System.assertEquals(1, results.size(), 'Should have one result');
        System.assertEquals(1, results[0].issuesFound, 'Should find one issue');

        List<Data_Quality_Issue__c> issues = [SELECT Id, Field_Name__c, Rule_Name__c FROM Data_Quality_Issue__c];
        System.assertEquals(1, issues.size(), 'Should have created one issue record');
        System.assertEquals('Company', issues[0].Field_Name__c, 'Issue should be for Company field');
    }

    @isTest
    static void testDetectOpportunityIssues() {
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        Opportunity testOpp = new Opportunity(
            Name = 'Test Opp',
            AccountId = testAccount.Id,
            StageName = 'Closed Won',
            CloseDate = Date.today().addDays(10),
            Amount = null
        );
        insert testOpp;

        DataQualityRuleEngine.DetectionRequest request = new DataQualityRuleEngine.DetectionRequest();
        request.objectType = 'Opportunity';
        request.recordIds = new List<String>{ testOpp.Id };

        Test.startTest();
        List<DataQualityRuleEngine.DetectionResult> results = DataQualityRuleEngine.detectDataQualityIssues(
            new List<DataQualityRuleEngine.DetectionRequest>{ request }
        );
        Test.stopTest();

        System.assertNotEquals(null, results, 'Results should not be null');
        System.assertEquals(1, results.size(), 'Should have one result');
        System.assertEquals(2, results[0].issuesFound, 'Should find two issues');

        List<Data_Quality_Issue__c> issues = [SELECT Id, Field_Name__c FROM Data_Quality_Issue__c];
        System.assertEquals(2, issues.size(), 'Should have created two issue records');
    }

    @isTest
    static void testDetectAccountIssues() {
        Account testAccount = new Account(
            Name = 'Test Account',
            BillingStreet = null,
            BillingCity = null
        );
        insert testAccount;

        DataQualityRuleEngine.DetectionRequest request = new DataQualityRuleEngine.DetectionRequest();
        request.objectType = 'Account';
        request.recordIds = new List<String>{ testAccount.Id };

        Test.startTest();
        List<DataQualityRuleEngine.DetectionResult> results = DataQualityRuleEngine.detectDataQualityIssues(
            new List<DataQualityRuleEngine.DetectionRequest>{ request }
        );
        Test.stopTest();

        System.assertNotEquals(null, results, 'Results should not be null');
        System.assertEquals(1, results.size(), 'Should have one result');
        System.assertEquals(1, results[0].issuesFound, 'Should find one issue');

        List<Data_Quality_Issue__c> issues = [SELECT Id, Field_Name__c FROM Data_Quality_Issue__c];
        System.assertEquals(1, issues.size(), 'Should have created one issue record');
        System.assertEquals('BillingAddress', issues[0].Field_Name__c, 'Issue should be for BillingAddress');
    }

    @isTest
    static void testNoIssuesFound() {
        Lead testLead = new Lead(
            FirstName = 'Good',
            LastName = 'Lead',
            Status = 'Open',
            Company = 'Test Company'
        );
        insert testLead;

        DataQualityRuleEngine.DetectionRequest request = new DataQualityRuleEngine.DetectionRequest();
        request.objectType = 'Lead';
        request.recordIds = new List<String>{ testLead.Id };

        Test.startTest();
        List<DataQualityRuleEngine.DetectionResult> results = DataQualityRuleEngine.detectDataQualityIssues(
            new List<DataQualityRuleEngine.DetectionRequest>{ request }
        );
        Test.stopTest();

        System.assertNotEquals(null, results, 'Results should not be null');
        System.assertEquals(1, results.size(), 'Should have one result');
        System.assertEquals(0, results[0].issuesFound, 'Should find zero issues');
        System.assert(results[0].issueDetails.contains('No data quality issues detected'), 'Should indicate no issues found');
    }

    @isTest
    static void testInvalidObjectType() {
        DataQualityRuleEngine.DetectionRequest request = new DataQualityRuleEngine.DetectionRequest();
        request.objectType = null;

        Test.startTest();
        List<DataQualityRuleEngine.DetectionResult> results = DataQualityRuleEngine.detectDataQualityIssues(
            new List<DataQualityRuleEngine.DetectionRequest>{ request }
        );
        Test.stopTest();

        System.assertNotEquals(null, results, 'Results should not be null');
        System.assertEquals(1, results.size(), 'Should have one result');
        System.assert(results[0].issueDetails.contains('Error'), 'Should contain error message');
    }

    @isTest
    static void testBulkDetection() {
        List<Lead> testLeads = new List<Lead>();
        for (Integer i = 0; i < 5; i++) {
            testLeads.add(new Lead(
                FirstName = 'Test',
                LastName = 'Lead ' + i,
                Status = 'Qualified',
                Company = null
            ));
        }
        insert testLeads;

        DataQualityRuleEngine.DetectionRequest request = new DataQualityRuleEngine.DetectionRequest();
        request.objectType = 'Lead';

        Test.startTest();
        List<DataQualityRuleEngine.DetectionResult> results = DataQualityRuleEngine.detectDataQualityIssues(
            new List<DataQualityRuleEngine.DetectionRequest>{ request }
        );
        Test.stopTest();

        System.assertNotEquals(null, results, 'Results should not be null');
        System.assertEquals(1, results.size(), 'Should have one result');
        System.assertEquals(5, results[0].issuesFound, 'Should find five issues');

        List<Data_Quality_Issue__c> issues = [SELECT Id FROM Data_Quality_Issue__c];
        System.assertEquals(5, issues.size(), 'Should have created five issue records');
    }
}
