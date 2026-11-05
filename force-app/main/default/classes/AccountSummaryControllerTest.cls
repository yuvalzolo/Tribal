/**
 * Test class for AccountSummaryController
 */
@IsTest
private class AccountSummaryControllerTest {

    @TestSetup
    static void setupTestData() {
        // Create test account
        Account testAccount = new Account(
            Name = 'Test Account',
            Industry = 'Technology',
            Type = 'Customer'
        );
        insert testAccount;

        // Create test opportunities
        List<Opportunity> opportunities = new List<Opportunity>();
        for (Integer i = 1; i <= 3; i++) {
            opportunities.add(new Opportunity(
                Name = 'Test Opportunity ' + i,
                AccountId = testAccount.Id,
                StageName = 'Prospecting',
                CloseDate = Date.today().addDays(30),
                Amount = 10000 * i
            ));
        }
        insert opportunities;

        // Create test cases
        List<Case> cases = new List<Case>();
        for (Integer i = 1; i <= 3; i++) {
            cases.add(new Case(
                Subject = 'Test Case ' + i,
                AccountId = testAccount.Id,
                Status = 'New',
                Priority = 'Medium'
            ));
        }
        insert cases;

        // Create test contacts
        List<Contact> contacts = new List<Contact>();
        for (Integer i = 1; i <= 3; i++) {
            contacts.add(new Contact(
                FirstName = 'Test',
                LastName = 'Contact ' + i,
                AccountId = testAccount.Id,
                Title = 'Manager',
                Email = 'test' + i + '@example.com',
                Phone = '555-000' + i
            ));
        }
        insert contacts;

        // Create test tasks
        List<Task> tasks = new List<Task>();
        for (Integer i = 1; i <= 2; i++) {
            tasks.add(new Task(
                Subject = 'Test Task ' + i,
                WhatId = testAccount.Id,
                Status = 'Not Started',
                ActivityDate = Date.today().addDays(i)
            ));
        }
        insert tasks;

        // Create test events
        List<Event> events = new List<Event>();
        for (Integer i = 1; i <= 2; i++) {
            events.add(new Event(
                Subject = 'Test Event ' + i,
                WhatId = testAccount.Id,
                StartDateTime = DateTime.now().addDays(i),
                EndDateTime = DateTime.now().addDays(i).addHours(1),
                ActivityDate = Date.today().addDays(i)
            ));
        }
        insert events;
    }

    @IsTest
    static void testGetAccountSummaryByName() {
        // Query test account
        Account testAccount = [SELECT Id, Name FROM Account WHERE Name = 'Test Account' LIMIT 1];

        // Create request
        AccountSummaryController.AccountSummaryRequest request = new AccountSummaryController.AccountSummaryRequest();
        request.accountIdentifier = testAccount.Name;

        // Call method
        Test.startTest();
        List<AccountSummaryController.AccountSummaryResponse> results = AccountSummaryController.getAccountSummary(
            new List<AccountSummaryController.AccountSummaryRequest>{ request }
        );
        Test.stopTest();

        // Verify results
        System.assertEquals(1, results.size(), 'Should return one result');
        AccountSummaryDTO dto = results[0].summary;

        System.assertEquals(false, dto.hasError, 'Should not have error');
        System.assertEquals(testAccount.Name, dto.accountName, 'Account name should match');
        System.assertEquals('Technology', dto.industry, 'Industry should match');
        System.assertEquals('Customer', dto.accountType, 'Type should match');
        System.assertNotEquals(null, dto.ownerName, 'Owner name should be populated');

        System.assertEquals(3, dto.totalOpportunities, 'Should have 3 opportunities');
        System.assertEquals(60000, dto.totalOpportunityAmount, 'Total amount should be 60000');
        System.assertEquals(3, dto.openCases, 'Should have 3 open cases');
        System.assertEquals(3, dto.contactCount, 'Should have 3 contacts');

        System.assertEquals(3, dto.opportunities.size(), 'Should return 3 opportunities');
        System.assertEquals(3, dto.cases.size(), 'Should return 3 cases');
        System.assertEquals(3, dto.contacts.size(), 'Should return 3 contacts');
        System.assertNotEquals(0, dto.activities.size(), 'Should have activities');
    }

    @IsTest
    static void testGetAccountSummaryById() {
        // Query test account
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];

        // Create request
        AccountSummaryController.AccountSummaryRequest request = new AccountSummaryController.AccountSummaryRequest();
        request.accountIdentifier = testAccount.Id;

        // Call method
        Test.startTest();
        List<AccountSummaryController.AccountSummaryResponse> results = AccountSummaryController.getAccountSummary(
            new List<AccountSummaryController.AccountSummaryRequest>{ request }
        );
        Test.stopTest();

        // Verify results
        System.assertEquals(1, results.size(), 'Should return one result');
        AccountSummaryDTO dto = results[0].summary;

        System.assertEquals(false, dto.hasError, 'Should not have error');
        System.assertEquals(testAccount.Id, dto.accountId, 'Account ID should match');
        System.assertEquals('Test Account', dto.accountName, 'Account name should match');
    }

    @IsTest
    static void testGetAccountSummaryNotFound() {
        // Create request for non-existent account
        AccountSummaryController.AccountSummaryRequest request = new AccountSummaryController.AccountSummaryRequest();
        request.accountIdentifier = 'Nonexistent Account';

        // Call method
        Test.startTest();
        List<AccountSummaryController.AccountSummaryResponse> results = AccountSummaryController.getAccountSummary(
            new List<AccountSummaryController.AccountSummaryRequest>{ request }
        );
        Test.stopTest();

        // Verify error handling
        System.assertEquals(1, results.size(), 'Should return one result');
        AccountSummaryDTO dto = results[0].summary;

        System.assertEquals(true, dto.hasError, 'Should have error');
        System.assertNotEquals(null, dto.errorMessage, 'Error message should be populated');
        System.assert(dto.errorMessage.contains('not found'), 'Error message should mention not found');
    }

    @IsTest
    static void testGetAccountSummaryMultipleRequests() {
        // Query test account
        Account testAccount = [SELECT Id, Name FROM Account WHERE Name = 'Test Account' LIMIT 1];

        // Create multiple requests
        List<AccountSummaryController.AccountSummaryRequest> requests = new List<AccountSummaryController.AccountSummaryRequest>();

        AccountSummaryController.AccountSummaryRequest req1 = new AccountSummaryController.AccountSummaryRequest();
        req1.accountIdentifier = testAccount.Name;
        requests.add(req1);

        AccountSummaryController.AccountSummaryRequest req2 = new AccountSummaryController.AccountSummaryRequest();
        req2.accountIdentifier = testAccount.Id;
        requests.add(req2);

        // Call method
        Test.startTest();
        List<AccountSummaryController.AccountSummaryResponse> results = AccountSummaryController.getAccountSummary(requests);
        Test.stopTest();

        // Verify results
        System.assertEquals(2, results.size(), 'Should return two results');
        for (AccountSummaryController.AccountSummaryResponse result : results) {
            AccountSummaryDTO dto = result.summary;
            System.assertEquals(false, dto.hasError, 'Should not have error');
            System.assertEquals(testAccount.Name, dto.accountName, 'Account name should match');
        }
    }

    @IsTest
    static void testAccountWithNoRelatedRecords() {
        // Create account with no related records
        Account emptyAccount = new Account(
            Name = 'Empty Account',
            Industry = 'Finance',
            Type = 'Prospect'
        );
        insert emptyAccount;

        // Create request
        AccountSummaryController.AccountSummaryRequest request = new AccountSummaryController.AccountSummaryRequest();
        request.accountIdentifier = emptyAccount.Name;

        // Call method
        Test.startTest();
        List<AccountSummaryController.AccountSummaryResponse> results = AccountSummaryController.getAccountSummary(
            new List<AccountSummaryController.AccountSummaryRequest>{ request }
        );
        Test.stopTest();

        // Verify results
        System.assertEquals(1, results.size(), 'Should return one result');
        AccountSummaryDTO dto = results[0].summary;

        System.assertEquals(false, dto.hasError, 'Should not have error');
        System.assertEquals('Empty Account', dto.accountName, 'Account name should match');
        System.assertEquals(0, dto.totalOpportunities, 'Should have 0 opportunities');
        System.assertEquals(0, dto.totalOpportunityAmount, 'Total amount should be 0');
        System.assertEquals(0, dto.openCases, 'Should have 0 open cases');
        System.assertEquals(0, dto.contactCount, 'Should have 0 contacts');
        System.assertEquals(0, dto.opportunities.size(), 'Opportunities list should be empty');
        System.assertEquals(0, dto.cases.size(), 'Cases list should be empty');
        System.assertEquals(0, dto.contacts.size(), 'Contacts list should be empty');
        System.assertEquals(0, dto.activities.size(), 'Activities list should be empty');
    }
}
