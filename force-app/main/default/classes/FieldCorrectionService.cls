public with sharing class FieldCorrectionService {

    @InvocableMethod(label='Update or Verify Record Field' description='Updates the target field with approved fix value or verifies manual fix')
    public static List<UpdateResult> updateRecordField(List<UpdateRequest> requests) {
        List<UpdateResult> results = new List<UpdateResult>();

        if (requests == null || requests.isEmpty()) {
            return results;
        }

        UpdateRequest request = requests[0];
        UpdateResult result = new UpdateResult();
        result.updateStatus = 'Failure';
        result.newValue = '';
        result.errorMessage = '';

        try {
            Id issueId = request.issueId;
            String approvalStatus = request.approvalStatus;

            if (String.isBlank(issueId)) {
                result.errorMessage = 'Issue ID is required';
                results.add(result);
                return results;
            }

            List<Data_Quality_Issue__c> issues = [
                SELECT Id, Record_ID__c, Object_Type__c, Field_Name__c, Suggested_Fix__c, Status__c
                FROM Data_Quality_Issue__c
                WHERE Id = :issueId
                LIMIT 1
            ];

            if (issues.isEmpty()) {
                result.errorMessage = 'Issue not found';
                results.add(result);
                return results;
            }

            Data_Quality_Issue__c issue = issues[0];

            if (approvalStatus == 'Rejected' || approvalStatus == 'Manual') {
                issue.Status__c = 'Owner_Responded';
                update issue;

                result.updateStatus = 'Success';
                result.newValue = 'Owner will handle manually';
                result.errorMessage = '';
            } else if (approvalStatus == 'Approved') {
                Boolean updateSuccess = applyFieldUpdate(issue, result);

                if (updateSuccess) {
                    issue.Status__c = 'Fixed';
                    issue.Resolved_Date__c = System.now();
                    update issue;

                    result.updateStatus = 'Success';
                } else {
                    result.updateStatus = 'Failure';
                }
            } else {
                result.errorMessage = 'Invalid approval status: ' + approvalStatus;
            }

        } catch (Exception e) {
            result.updateStatus = 'Failure';
            result.errorMessage = 'Error: ' + e.getMessage();
        }

        results.add(result);
        return results;
    }

    public static Boolean verifyManualFix(Id issueId) {
        try {
            if (String.isBlank(issueId)) {
                return false;
            }

            List<Data_Quality_Issue__c> issues = [
                SELECT Id, Status__c
                FROM Data_Quality_Issue__c
                WHERE Id = :issueId
                LIMIT 1
            ];

            if (issues.isEmpty()) {
                return false;
            }

            return (issues[0].Status__c == 'Fixed');

        } catch (Exception e) {
            System.debug('Verify manual fix error: ' + e.getMessage());
            return false;
        }
    }

    private static Boolean applyFieldUpdate(Data_Quality_Issue__c issue, UpdateResult result) {
        try {
            String recordId = issue.Record_ID__c;
            String objectType = issue.Object_Type__c;
            String fieldName = issue.Field_Name__c;
            String suggestedFix = issue.Suggested_Fix__c;

            if (String.isBlank(suggestedFix) || suggestedFix == '[Requires manual input]') {
                result.errorMessage = 'Suggested fix requires manual input';
                return false;
            }

            SObject recordToUpdate = null;

            if (objectType == 'Lead') {
                recordToUpdate = [SELECT Id FROM Lead WHERE Id = :recordId LIMIT 1];
            } else if (objectType == 'Account') {
                recordToUpdate = [SELECT Id FROM Account WHERE Id = :recordId LIMIT 1];
            } else if (objectType == 'Opportunity') {
                recordToUpdate = [SELECT Id FROM Opportunity WHERE Id = :recordId LIMIT 1];
            }

            if (recordToUpdate == null) {
                result.errorMessage = 'Record not found';
                return false;
            }

            if (fieldName == 'CloseDate') {
                recordToUpdate.put(fieldName, Date.valueOf(suggestedFix));
            } else if (fieldName == 'Status') {
                recordToUpdate.put(fieldName, suggestedFix);
            } else {
                recordToUpdate.put(fieldName, suggestedFix);
            }

            update recordToUpdate;

            result.newValue = suggestedFix;
            result.errorMessage = '';
            return true;

        } catch (Exception e) {
            result.errorMessage = 'Field update failed: ' + e.getMessage();
            return false;
        }
    }

    public class UpdateRequest {
        @InvocableVariable(label='Issue ID' description='The ID of the Data_Quality_Issue__c record' required=true)
        public String issueId;

        @InvocableVariable(label='Approval Status' description='Owner approval status: Approved, Rejected, or Manual' required=true)
        public String approvalStatus;
    }

    public class UpdateResult {
        @InvocableVariable(label='Update Status' description='Status of the field update')
        public String updateStatus;

        @InvocableVariable(label='New Field Value' description='The new value set on the field')
        public String newValue;

        @InvocableVariable(label='Error Message' description='Error details if update failed')
        public String errorMessage;
    }

}
