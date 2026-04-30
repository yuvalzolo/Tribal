@isTest
private class DataQualityScanBatchTest {

    @isTest
    static void testBatchLeadScan() {
        List<Lead> testLeads = new List<Lead>();
        for (Integer i = 0; i < 10; i++) {
            testLeads.add(new Lead(
                FirstName = 'Test',
                LastName = 'Lead ' + i,
                Status = 'Qualified',
                Company = null
            ));
        }
        insert testLeads;

        Test.startTest();
        DataQualityScanBatch batch = new DataQualityScanBatch('Lead');
        Database.executeBatch(batch, 200);
        Test.stopTest();

        List<Data_Quality_Issue__c> issues = [SELECT Id, Object_Type__c FROM Data_Quality_Issue__c];
        System.assertEquals(10, issues.size(), 'Should have created 10 issue records');
        System.assertEquals('Lead', issues[0].Object_Type__c, 'Issues should be for Lead object');
    }

    @isTest
    static void testBatchOpportunityScan() {
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        List<Opportunity> testOpps = new List<Opportunity>();
        for (Integer i = 0; i < 5; i++) {
            testOpps.add(new Opportunity(
                Name = 'Test Opp ' + i,
                AccountId = testAccount.Id,
                StageName = 'Closed Won',
                CloseDate = Date.today().addDays(10),
                Amount = null
            ));
        }
        insert testOpps;

        Test.startTest();
        DataQualityScanBatch batch = new DataQualityScanBatch('Opportunity');
        Database.executeBatch(batch, 200);
        Test.stopTest();

        List<Data_Quality_Issue__c> issues = [SELECT Id, Object_Type__c FROM Data_Quality_Issue__c];
        System.assertEquals(10, issues.size(), 'Should have created 10 issue records (2 per opp)');
        System.assertEquals('Opportunity', issues[0].Object_Type__c, 'Issues should be for Opportunity object');
    }

    @isTest
    static void testBatchAccountScan() {
        List<Account> testAccounts = new List<Account>();
        for (Integer i = 0; i < 3; i++) {
            testAccounts.add(new Account(
                Name = 'Test Account ' + i,
                BillingStreet = null,
                BillingCity = null
            ));
        }
        insert testAccounts;

        Test.startTest();
        DataQualityScanBatch batch = new DataQualityScanBatch('Account');
        Database.executeBatch(batch, 200);
        Test.stopTest();

        List<Data_Quality_Issue__c> issues = [SELECT Id, Object_Type__c FROM Data_Quality_Issue__c];
        System.assertEquals(3, issues.size(), 'Should have created 3 issue records');
        System.assertEquals('Account', issues[0].Object_Type__c, 'Issues should be for Account object');
    }

    @isTest
    static void testBatchWithInvalidObjectType() {
        Test.startTest();
        DataQualityScanBatch batch = new DataQualityScanBatch('InvalidObject');
        Database.executeBatch(batch, 200);
        Test.stopTest();

        List<Data_Quality_Issue__c> issues = [SELECT Id FROM Data_Quality_Issue__c];
        System.assertEquals(0, issues.size(), 'Should not create any issue records for invalid object type');
    }
}
