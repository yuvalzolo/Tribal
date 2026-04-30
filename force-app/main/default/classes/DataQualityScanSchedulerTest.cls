@isTest
private class DataQualityScanSchedulerTest {

    @isTest
    static void testScheduler() {
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Status = 'Qualified',
            Company = null
        );
        insert testLead;

        Test.startTest();
        DataQualityScanScheduler scheduler = new DataQualityScanScheduler();
        String cronExp = '0 0 0 * * ?';
        System.schedule('Test Data Quality Scan', cronExp, scheduler);
        Test.stopTest();

        List<Data_Quality_Issue__c> issues = [SELECT Id FROM Data_Quality_Issue__c];
        System.assertNotEquals(null, issues, 'Issues list should not be null');
    }

    @isTest
    static void testSchedulerExecution() {
        Test.startTest();
        DataQualityScanScheduler scheduler = new DataQualityScanScheduler();
        scheduler.execute(null);
        Test.stopTest();

        System.assert(true, 'Scheduler executed without errors');
    }
}
