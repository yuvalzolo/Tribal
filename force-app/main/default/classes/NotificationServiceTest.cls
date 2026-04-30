@isTest
private class NotificationServiceTest {

    @isTest
    static void testNotifyRecordOwnerSuccess() {
        User testUser = [SELECT Id, Email FROM User WHERE IsActive = true LIMIT 1];

        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company',
            OwnerId = testUser.Id
        );
        insert testLead;

        Data_Quality_Issue__c issue = new Data_Quality_Issue__c(
            Record_ID__c = testLead.Id,
            Object_Type__c = 'Lead',
            Field_Name__c = 'Company',
            Rule_Name__c = 'Test Rule',
            Error_Message__c = 'Test error message',
            Suggested_Fix__c = 'Test fix',
            Priority__c = 'High',
            Status__c = 'Open',
            Owner_User__c = testUser.Id,
            Detected_Date__c = System.now()
        );
        insert issue;

        NotificationService.NotificationRequest request = new NotificationService.NotificationRequest();
        request.issueId = issue.Id;

        Test.startTest();
        List<NotificationService.NotificationResult> results = NotificationService.notifyRecordOwner(
            new List<NotificationService.NotificationRequest>{ request }
        );
        Test.stopTest();

        System.assertNotEquals(null, results, 'Results should not be null');
        System.assertEquals(1, results.size(), 'Should have one result');
        System.assertEquals('Success', results[0].notificationStatus, 'Notification should succeed');
        System.assertEquals('Email', results[0].channelUsed, 'Should use email channel');

        Data_Quality_Issue__c updatedIssue = [SELECT Status__c FROM Data_Quality_Issue__c WHERE Id = :issue.Id];
        System.assertEquals('Notified', updatedIssue.Status__c, 'Issue status should be updated to Notified');
    }

    @isTest
    static void testNotifyRecordOwnerInvalidIssueId() {
        NotificationService.NotificationRequest request = new NotificationService.NotificationRequest();
        request.issueId = null;

        Test.startTest();
        List<NotificationService.NotificationResult> results = NotificationService.notifyRecordOwner(
            new List<NotificationService.NotificationRequest>{ request }
        );
        Test.stopTest();

        System.assertNotEquals(null, results, 'Results should not be null');
        System.assertEquals(1, results.size(), 'Should have one result');
        System.assertEquals('Failure', results[0].notificationStatus, 'Notification should fail');
        System.assert(results[0].channelUsed.contains('Error'), 'Should contain error message');
    }

    @isTest
    static void testNotifyRecordOwnerIssueNotFound() {
        NotificationService.NotificationRequest request = new NotificationService.NotificationRequest();
        request.issueId = 'a00000000000000AAA';

        Test.startTest();
        List<NotificationService.NotificationResult> results = NotificationService.notifyRecordOwner(
            new List<NotificationService.NotificationRequest>{ request }
        );
        Test.stopTest();

        System.assertNotEquals(null, results, 'Results should not be null');
        System.assertEquals(1, results.size(), 'Should have one result');
        System.assertEquals('Failure', results[0].notificationStatus, 'Notification should fail');
    }

    @isTest
    static void testNotifyRecordOwnerNoOwner() {
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
            Error_Message__c = 'Test error message',
            Suggested_Fix__c = 'Test fix',
            Priority__c = 'High',
            Status__c = 'Open',
            Owner_User__c = null,
            Detected_Date__c = System.now()
        );
        insert issue;

        NotificationService.NotificationRequest request = new NotificationService.NotificationRequest();
        request.issueId = issue.Id;

        Test.startTest();
        List<NotificationService.NotificationResult> results = NotificationService.notifyRecordOwner(
            new List<NotificationService.NotificationRequest>{ request }
        );
        Test.stopTest();

        System.assertNotEquals(null, results, 'Results should not be null');
        System.assertEquals(1, results.size(), 'Should have one result');
        System.assertEquals('Failure', results[0].notificationStatus, 'Notification should fail');
        System.assert(results[0].channelUsed.contains('No owner'), 'Should indicate no owner assigned');
    }
}
