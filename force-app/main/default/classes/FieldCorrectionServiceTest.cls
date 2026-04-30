@isTest
private class FieldCorrectionServiceTest {

    @isTest
    static void testUpdateFieldApproved() {
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
            Priority__c = 'High',
            Status__c = 'Notified',
            Detected_Date__c = System.now()
        );
        insert issue;

        FieldCorrectionService.UpdateRequest request = new FieldCorrectionService.UpdateRequest();
        request.issueId = issue.Id;
        request.approvalStatus = 'Approved';

        Test.startTest();
        List<FieldCorrectionService.UpdateResult> results = FieldCorrectionService.updateRecordField(
            new List<FieldCorrectionService.UpdateRequest>{ request }
        );
        Test.stopTest();

        System.assertNotEquals(null, results, 'Results should not be null');
        System.assertEquals(1, results.size(), 'Should have one result');
        System.assertEquals('Success', results[0].updateStatus, 'Update should succeed');

        Data_Quality_Issue__c updatedIssue = [SELECT Status__c FROM Data_Quality_Issue__c WHERE Id = :issue.Id];
        System.assertEquals('Fixed', updatedIssue.Status__c, 'Issue status should be Fixed');
    }

    @isTest
    static void testUpdateFieldRejected() {
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company'
        );
        insert testLead;

        Data_Quality_Issue__c issue = new Data_Quality_Issue__c(
            Record_ID__c = testLead.Id,
            Object_Type__c = 'Lead',
            Field_Name__c = 'Status',
            Rule_Name__c = 'Test Rule',
            Error_Message__c = 'Test error',
            Suggested_Fix__c = 'Nurture',
            Priority__c = 'Medium',
            Status__c = 'Notified',
            Detected_Date__c = System.now()
        );
        insert issue;

        FieldCorrectionService.UpdateRequest request = new FieldCorrectionService.UpdateRequest();
        request.issueId = issue.Id;
        request.approvalStatus = 'Manual';

        Test.startTest();
        List<FieldCorrectionService.UpdateResult> results = FieldCorrectionService.updateRecordField(
            new List<FieldCorrectionService.UpdateRequest>{ request }
        );
        Test.stopTest();

        System.assertNotEquals(null, results, 'Results should not be null');
        System.assertEquals(1, results.size(), 'Should have one result');
        System.assertEquals('Success', results[0].updateStatus, 'Should succeed for manual handling');

        Data_Quality_Issue__c updatedIssue = [SELECT Status__c FROM Data_Quality_Issue__c WHERE Id = :issue.Id];
        System.assertEquals('Owner_Responded', updatedIssue.Status__c, 'Issue status should be Owner_Responded');
    }

    @isTest
    static void testUpdateFieldInvalidIssueId() {
        FieldCorrectionService.UpdateRequest request = new FieldCorrectionService.UpdateRequest();
        request.issueId = null;
        request.approvalStatus = 'Approved';

        Test.startTest();
        List<FieldCorrectionService.UpdateResult> results = FieldCorrectionService.updateRecordField(
            new List<FieldCorrectionService.UpdateRequest>{ request }
        );
        Test.stopTest();

        System.assertNotEquals(null, results, 'Results should not be null');
        System.assertEquals(1, results.size(), 'Should have one result');
        System.assertEquals('Failure', results[0].updateStatus, 'Update should fail');
        System.assert(results[0].errorMessage.contains('required'), 'Should contain error message');
    }

    @isTest
    static void testUpdateFieldManualInputRequired() {
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = null,
            Status = 'Qualified'
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

        FieldCorrectionService.UpdateRequest request = new FieldCorrectionService.UpdateRequest();
        request.issueId = issue.Id;
        request.approvalStatus = 'Approved';

        Test.startTest();
        List<FieldCorrectionService.UpdateResult> results = FieldCorrectionService.updateRecordField(
            new List<FieldCorrectionService.UpdateRequest>{ request }
        );
        Test.stopTest();

        System.assertNotEquals(null, results, 'Results should not be null');
        System.assertEquals(1, results.size(), 'Should have one result');
        System.assertEquals('Failure', results[0].updateStatus, 'Update should fail for manual input');
        System.assert(results[0].errorMessage.contains('manual input'), 'Should indicate manual input required');
    }

    @isTest
    static void testVerifyManualFix() {
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company'
        );
        insert testLead;

        Data_Quality_Issue__c issue = new Data_Quality_Issue__c(
            Record_ID__c = testLead.Id,
            Object_Type__c = 'Lead',
            Field_Name__c = 'Company',
            Rule_Name__c = 'Test Rule',
            Error_Message__c = 'Test error',
            Suggested_Fix__c = 'Test Company',
            Priority__c = 'Medium',
            Status__c = 'Fixed',
            Detected_Date__c = System.now()
        );
        insert issue;

        Test.startTest();
        Boolean isFixed = FieldCorrectionService.verifyManualFix(issue.Id);
        Test.stopTest();

        System.assertEquals(true, isFixed, 'Issue should be verified as fixed');
    }

    @isTest
    static void testVerifyManualFixNotFixed() {
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company'
        );
        insert testLead;

        Data_Quality_Issue__c issue = new Data_Quality_Issue__c(
            Record_ID__c = testLead.Id,
            Object_Type__c = 'Lead',
            Field_Name__c = 'Company',
            Rule_Name__c = 'Test Rule',
            Error_Message__c = 'Test error',
            Suggested_Fix__c = 'Test Company',
            Priority__c = 'Medium',
            Status__c = 'Owner_Responded',
            Detected_Date__c = System.now()
        );
        insert issue;

        Test.startTest();
        Boolean isFixed = FieldCorrectionService.verifyManualFix(issue.Id);
        Test.stopTest();

        System.assertEquals(false, isFixed, 'Issue should not be verified as fixed');
    }
}
