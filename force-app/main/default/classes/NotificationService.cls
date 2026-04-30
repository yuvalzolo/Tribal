public class NotificationService {

    /**
     * Invocable method to notify record owners about data quality issues
     * Supports multi-channel delivery (Email, Slack, Teams)
     */
    @InvocableMethod(label='Notify Record Owner' description='Sends notification to record owner about data quality issue')
    public static List<NotificationResult> notifyRecordOwner(List<NotificationRequest> requests) {
        List<NotificationResult> results = new List<NotificationResult>();

        for (NotificationRequest request : requests) {
            NotificationResult result = new NotificationResult();

            try {
                // Validate input
                if (request.issueId == null) {
                    result.notificationStatus = 'Failure';
                    result.channelUsed = 'Error: Issue ID is required';
                    results.add(result);
                    continue;
                }

                // Query the Data Quality Issue record
                List<Data_Quality_Issue__c> issues = [
                    SELECT Id, Record_ID__c, Object_Type__c, Field_Name__c,
                           Rule_Name__c, Error_Message__c, Suggested_Fix__c,
                           Priority__c, Status__c, Owner_User__c,
                           Owner_User__r.Email, Owner_User__r.Name
                    FROM Data_Quality_Issue__c
                    WHERE Id = :request.issueId
                    LIMIT 1
                ];

                if (issues.isEmpty()) {
                    result.notificationStatus = 'Failure';
                    result.channelUsed = 'Error: Issue record not found';
                    results.add(result);
                    continue;
                }

                Data_Quality_Issue__c issue = issues[0];

                // Validate that owner is assigned
                if (issue.Owner_User__c == null) {
                    result.notificationStatus = 'Failure';
                    result.channelUsed = 'Error: No owner assigned to this issue';
                    results.add(result);
                    continue;
                }

                // Get record details for notification
                String recordName = getRecordName(issue.Record_ID__c, issue.Object_Type__c);

                // Determine notification channel (default to Email for now)
                String channel = getNotificationChannel(issue.Owner_User__c);

                // Send notification based on channel
                Boolean notificationSent = false;
                if (channel == 'Email') {
                    notificationSent = sendEmailNotification(issue, recordName);
                } else if (channel == 'Slack') {
                    // Future enhancement: Slack integration
                    notificationSent = sendEmailNotification(issue, recordName); // Fallback to email
                    channel = 'Email';
                } else if (channel == 'Teams') {
                    // Future enhancement: Teams integration
                    notificationSent = sendEmailNotification(issue, recordName); // Fallback to email
                    channel = 'Email';
                } else {
                    notificationSent = sendEmailNotification(issue, recordName);
                    channel = 'Email';
                }

                if (notificationSent) {
                    // Update issue status to Notified
                    issue.Status__c = 'Notified';
                    update issue;

                    result.notificationStatus = 'Success';
                    result.channelUsed = channel;
                } else {
                    result.notificationStatus = 'Failure';
                    result.channelUsed = 'Error: Failed to send notification';
                }

            } catch (Exception e) {
                result.notificationStatus = 'Failure';
                result.channelUsed = 'Error: ' + e.getMessage();
            }

            results.add(result);
        }

        return results;
    }

    /**
     * Get the record name for the notification
     */
    private static String getRecordName(String recordId, String objectType) {
        try {
            String query = 'SELECT Name FROM ' + String.escapeSingleQuotes(objectType) + ' WHERE Id = :recordId LIMIT 1';
            List<SObject> records = Database.query(query);
            if (!records.isEmpty()) {
                return String.valueOf(records[0].get('Name'));
            }
        } catch (Exception e) {
            System.debug('Error retrieving record name: ' + e.getMessage());
        }
        return 'Unknown Record';
    }

    /**
     * Determine the preferred notification channel for a user
     * Currently defaults to Email - can be extended to check user preferences
     */
    private static String getNotificationChannel(Id userId) {
        // Future enhancement: Query User.Preferred_Notification_Channel__c
        return 'Email';
    }

    /**
     * Send email notification to record owner
     */
    private static Boolean sendEmailNotification(Data_Quality_Issue__c issue, String recordName) {
        try {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

            // Set recipient
            mail.setTargetObjectId(issue.Owner_User__c);
            mail.setSaveAsActivity(false);

            // Set subject
            mail.setSubject('Action Required: Data Quality Issue on ' + issue.Object_Type__c + ' - ' + recordName);

            // Build email body
            String emailBody = buildEmailBody(issue, recordName);
            mail.setHtmlBody(emailBody);

            // Send email
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });

            return true;
        } catch (Exception e) {
            System.debug('Error sending email notification: ' + e.getMessage());
            return false;
        }
    }

    /**
     * Build HTML email body with issue details
     */
    private static String buildEmailBody(Data_Quality_Issue__c issue, String recordName) {
        String body = '<html><body>';
        body += '<h2>Data Quality Issue Detected</h2>';
        body += '<p>A data quality issue has been detected on one of your records. Please review and take action.</p>';
        body += '<hr/>';
        body += '<p><strong>Record:</strong> ' + recordName + '</p>';
        body += '<p><strong>Object Type:</strong> ' + issue.Object_Type__c + '</p>';
        body += '<p><strong>Field:</strong> ' + issue.Field_Name__c + '</p>';
        body += '<p><strong>Rule:</strong> ' + issue.Rule_Name__c + '</p>';
        body += '<p><strong>Priority:</strong> ' + issue.Priority__c + '</p>';
        body += '<hr/>';
        body += '<p><strong>Issue Description:</strong><br/>' + issue.Error_Message__c + '</p>';

        if (String.isNotBlank(issue.Suggested_Fix__c)) {
            body += '<p><strong>Suggested Fix:</strong><br/>' + issue.Suggested_Fix__c + '</p>';
        }

        body += '<hr/>';
        body += '<p><a href="' + URL.getOrgDomainUrl().toExternalForm() + '/' + issue.Record_ID__c + '">View Record in Salesforce</a></p>';
        body += '<p><a href="' + URL.getOrgDomainUrl().toExternalForm() + '/' + issue.Id + '">View Data Quality Issue</a></p>';
        body += '</body></html>';

        return body;
    }

    /**
     * Inner class for invocable method input
     */
    public class NotificationRequest {
        @InvocableVariable(label='Issue ID' description='ID of the Data Quality Issue record' required=true)
        public String issueId;
    }

    /**
     * Inner class for invocable method output
     */
    public class NotificationResult {
        @InvocableVariable(label='Notification Status' description='Status of the notification (Success or Failure)')
        public String notificationStatus;

        @InvocableVariable(label='Channel Used' description='Notification channel used (Email, Slack, Teams) or error message')
        public String channelUsed;
    }
}
