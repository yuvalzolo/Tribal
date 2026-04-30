@isTest
private class DQIssueControllerTest {

    @testSetup
    static void setup() {
        User testUser = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];

        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company',
            OwnerId = testUser.Id
        );
        insert testLead;

        List<Data_Quality_Issue__c> issues = new List<Data_Quality_Issue__c>();

        issues.add(new Data_Quality_Issue__c(
            Record_ID__c = testLead.Id,
            Object_Type__c = 'Lead',
            Field_Name__c = 'Company',
            Rule_Name__c = 'Test Rule 1',
            Error_Message__c = 'Test error 1',
            Suggested_Fix__c = 'Test fix 1',
            Priority__c = 'High',
            Status__c = 'Open',
            Owner_User__c = testUser.Id,
            Detected_Date__c = System.now()
        ));

        issues.add(new Data_Quality_Issue__c(
            Record_ID__c = testLead.Id,
            Object_Type__c = 'Account',
            Field_Name__c = 'BillingAddress',
            Rule_Name__c = 'Test Rule 2',
            Error_Message__c = 'Test error 2',
            Suggested_Fix__c = 'Test fix 2',
            Priority__c = 'Medium',
            Status__c = 'Notified',
            Owner_User__c = testUser.Id,
            Detected_Date__c = System.now()
        ));

        issues.add(new Data_Quality_Issue__c(
            Record_ID__c = testLead.Id,
            Object_Type__c = 'Opportunity',
            Field_Name__c = 'Amount',
            Rule_Name__c = 'Test Rule 3',
            Error_Message__c = 'Test error 3',
            Suggested_Fix__c = 'Test fix 3',
            Priority__c = 'Critical',
            Status__c = 'Fixed',
            Owner_User__c = testUser.Id,
            Detected_Date__c = System.now()
        ));

        insert issues;
    }

    @isTest
    static void testGetIssuesNoFilters() {
        Test.startTest();
        List<Data_Quality_Issue__c> issues = DQIssueController.getIssues(null, null, null);
        Test.stopTest();

        System.assertNotEquals(null, issues, 'Issues list should not be null');
        System.assertEquals(3, issues.size(), 'Should return all 3 issues');
    }

    @isTest
    static void testGetIssuesWithObjectFilter() {
        Test.startTest();
        List<Data_Quality_Issue__c> issues = DQIssueController.getIssues('Lead', null, null);
        Test.stopTest();

        System.assertNotEquals(null, issues, 'Issues list should not be null');
        System.assertEquals(1, issues.size(), 'Should return 1 Lead issue');
        System.assertEquals('Lead', issues[0].Object_Type__c, 'Issue should be for Lead');
    }

    @isTest
    static void testGetIssuesWithPriorityFilter() {
        Test.startTest();
        List<Data_Quality_Issue__c> issues = DQIssueController.getIssues(null, 'High', null);
        Test.stopTest();

        System.assertNotEquals(null, issues, 'Issues list should not be null');
        System.assertEquals(1, issues.size(), 'Should return 1 High priority issue');
        System.assertEquals('High', issues[0].Priority__c, 'Issue should be High priority');
    }

    @isTest
    static void testGetIssuesWithStatusFilter() {
        Test.startTest();
        List<Data_Quality_Issue__c> issues = DQIssueController.getIssues(null, null, 'Fixed');
        Test.stopTest();

        System.assertNotEquals(null, issues, 'Issues list should not be null');
        System.assertEquals(1, issues.size(), 'Should return 1 Fixed issue');
        System.assertEquals('Fixed', issues[0].Status__c, 'Issue should be Fixed');
    }

    @isTest
    static void testGetIssuesWithAllFilters() {
        Test.startTest();
        List<Data_Quality_Issue__c> issues = DQIssueController.getIssues('Account', 'Medium', 'Notified');
        Test.stopTest();

        System.assertNotEquals(null, issues, 'Issues list should not be null');
        System.assertEquals(1, issues.size(), 'Should return 1 issue matching all filters');
        System.assertEquals('Account', issues[0].Object_Type__c, 'Issue should be for Account');
        System.assertEquals('Medium', issues[0].Priority__c, 'Issue should be Medium priority');
        System.assertEquals('Notified', issues[0].Status__c, 'Issue should be Notified');
    }

    @isTest
    static void testGetIssueStatistics() {
        Test.startTest();
        Map<String, Integer> stats = DQIssueController.getIssueStatistics();
        Test.stopTest();

        System.assertNotEquals(null, stats, 'Statistics should not be null');
        System.assert(stats.containsKey('Lead'), 'Stats should include Lead count');
        System.assert(stats.containsKey('Priority_High'), 'Stats should include High priority count');
        System.assert(stats.containsKey('Status_Open'), 'Stats should include Open status count');
    }

    @isTest
    static void testGetPriorityPicklistValues() {
        Test.startTest();
        List<Map<String, String>> options = DQIssueController.getPriorityPicklistValues();
        Test.stopTest();

        System.assertNotEquals(null, options, 'Options should not be null');
        System.assert(options.size() > 0, 'Should have priority options');
        System.assertEquals('label', new List<String>(options[0].keySet())[0], 'Should have label key');
    }

    @isTest
    static void testGetStatusPicklistValues() {
        Test.startTest();
        List<Map<String, String>> options = DQIssueController.getStatusPicklistValues();
        Test.stopTest();

        System.assertNotEquals(null, options, 'Options should not be null');
        System.assert(options.size() > 0, 'Should have status options');
    }

    @isTest
    static void testApproveMultipleFixes() {
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        Opportunity testOpp = new Opportunity(
            Name = 'Test Opp',
            AccountId = testAccount.Id,
            StageName = 'Closed Won',
            CloseDate = Date.today().addDays(10),
            Amount = 1000
        );
        insert testOpp;

        Data_Quality_Issue__c issue = new Data_Quality_Issue__c(
            Record_ID__c = testOpp.Id,
            Object_Type__c = 'Opportunity',
            Field_Name__c = 'CloseDate',
            Rule_Name__c = 'Test Rule',
            Error_Message__c = 'Test error',
            Suggested_Fix__c = String.valueOf(Date.today()),
            Priority__c = 'Critical',
            Status__c = 'Notified',
            Detected_Date__c = System.now()
        );
        insert issue;

        Test.startTest();
        String result = DQIssueController.approveMultipleFixes(new List<String>{ issue.Id });
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.contains('Approved'), 'Result should indicate approval');

        Data_Quality_Issue__c updatedIssue = [SELECT Status__c FROM Data_Quality_Issue__c WHERE Id = :issue.Id];
        System.assertEquals('Fixed', updatedIssue.Status__c, 'Issue should be marked as Fixed');
    }

    @isTest
    static void testApproveMultipleFixesWithFailures() {
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = null
        );
        insert testLead;

        Data_Quality_Issue__c issue = new Data_Quality_Issue__c(
            Record_ID__c = testLead.Id,
            Object_Type__c = 'Lead',
            Field_Name__c = 'Company',
            Rule_Name__c = 'Test Rule',
            Error_Message__c = 'Test error',
            Suggested_Fix__c = '[Requires manual input]',
            Priority__c = 'High',
            Status__c = 'Notified',
            Detected_Date__c = System.now()
        );
        insert issue;

        Test.startTest();
        String result = DQIssueController.approveMultipleFixes(new List<String>{ issue.Id });
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.contains('failed'), 'Result should indicate failures');
    }
}
