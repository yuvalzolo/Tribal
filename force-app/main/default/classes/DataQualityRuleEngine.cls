public with sharing class DataQualityRuleEngine {

    @InvocableMethod(label='Detect Data Quality Issues' description='Scans records for data quality issues based on configured validation rules')
    public static List<DetectionResult> detectDataQualityIssues(List<DetectionRequest> requests) {
        List<DetectionResult> results = new List<DetectionResult>();

        if (requests == null || requests.isEmpty()) {
            return results;
        }

        DetectionRequest request = requests[0];
        DetectionResult result = new DetectionResult();
        result.issuesFound = 0;
        result.issueDetails = '';

        try {
            String objectType = request.objectType;
            List<String> recordIds = request.recordIds;

            if (String.isBlank(objectType)) {
                result.issueDetails = 'Error: Object type is required';
                results.add(result);
                return results;
            }

            List<SObject> recordsToScan = queryRecords(objectType, recordIds);

            if (recordsToScan.isEmpty()) {
                result.issueDetails = 'No records found to scan for object type: ' + objectType;
                results.add(result);
                return results;
            }

            List<Data_Quality_Issue__c> detectedIssues = new List<Data_Quality_Issue__c>();

            for (SObject record : recordsToScan) {
                List<Data_Quality_Issue__c> recordIssues = evaluateRecord(record, objectType);
                detectedIssues.addAll(recordIssues);
            }

            if (!detectedIssues.isEmpty()) {
                insert detectedIssues;
                result.issuesFound = detectedIssues.size();
                result.issueDetails = buildIssueSummary(detectedIssues);
            } else {
                result.issueDetails = 'No data quality issues detected for ' + recordsToScan.size() + ' records scanned';
            }

        } catch (Exception e) {
            result.issueDetails = 'Error during scanning: ' + e.getMessage();
        }

        results.add(result);
        return results;
    }

    private static List<SObject> queryRecords(String objectType, List<String> recordIds) {
        List<SObject> records = new List<SObject>();

        String query = '';

        if (objectType == 'Lead') {
            query = 'SELECT Id, OwnerId, Status, Company, LastActivityDate FROM Lead';
        } else if (objectType == 'Account') {
            query = 'SELECT Id, OwnerId, BillingStreet, BillingCity FROM Account';
        } else if (objectType == 'Opportunity') {
            query = 'SELECT Id, OwnerId, StageName, CloseDate, Amount FROM Opportunity';
        } else {
            return records;
        }

        if (recordIds != null && !recordIds.isEmpty()) {
            query += ' WHERE Id IN :recordIds';
        }

        query += ' LIMIT 1000';

        try {
            records = Database.query(query);
        } catch (Exception e) {
            System.debug('Error querying records: ' + e.getMessage());
        }

        return records;
    }

    private static List<Data_Quality_Issue__c> evaluateRecord(SObject record, String objectType) {
        List<Data_Quality_Issue__c> issues = new List<Data_Quality_Issue__c>();

        Map<String, Object> fieldMap = record.getPopulatedFieldsAsMap();
        Id recordId = (Id)record.get('Id');
        Id ownerId = (Id)record.get('OwnerId');

        if (objectType == 'Lead') {
            issues.addAll(evaluateLeadRules(record, recordId, ownerId));
        } else if (objectType == 'Account') {
            issues.addAll(evaluateAccountRules(record, recordId, ownerId));
        } else if (objectType == 'Opportunity') {
            issues.addAll(evaluateOpportunityRules(record, recordId, ownerId));
        }

        return issues;
    }

    private static List<Data_Quality_Issue__c> evaluateLeadRules(SObject record, Id recordId, Id ownerId) {
        List<Data_Quality_Issue__c> issues = new List<Data_Quality_Issue__c>();

        String status = (String)record.get('Status');
        String company = (String)record.get('Company');
        Date lastActivityDate = (Date)record.get('LastActivityDate');

        if (status == 'Qualified' && String.isBlank(company)) {
            Data_Quality_Issue__c issue = new Data_Quality_Issue__c(
                Record_ID__c = recordId,
                Object_Type__c = 'Lead',
                Field_Name__c = 'Company',
                Rule_Name__c = 'Qualified Lead Requires Company',
                Error_Message__c = 'Qualified leads must have a Company name populated',
                Suggested_Fix__c = '[Requires manual input]',
                Priority__c = 'High',
                Status__c = 'Open',
                Owner_User__c = ownerId,
                Detected_Date__c = System.now()
            );
            issues.add(issue);
        }

        if (lastActivityDate != null && lastActivityDate.daysBetween(Date.today()) > 30 &&
            status != 'Nurture' && status != 'Disqualified') {
            Data_Quality_Issue__c issue = new Data_Quality_Issue__c(
                Record_ID__c = recordId,
                Object_Type__c = 'Lead',
                Field_Name__c = 'Status',
                Rule_Name__c = 'Stale Lead Status Update',
                Error_Message__c = 'Leads inactive for more than 30 days should be marked as Nurture or Disqualified',
                Suggested_Fix__c = 'Nurture',
                Priority__c = 'Medium',
                Status__c = 'Open',
                Owner_User__c = ownerId,
                Detected_Date__c = System.now()
            );
            issues.add(issue);
        }

        return issues;
    }

    private static List<Data_Quality_Issue__c> evaluateAccountRules(SObject record, Id recordId, Id ownerId) {
        List<Data_Quality_Issue__c> issues = new List<Data_Quality_Issue__c>();

        String billingStreet = (String)record.get('BillingStreet');
        String billingCity = (String)record.get('BillingCity');

        if (String.isBlank(billingStreet) && String.isBlank(billingCity)) {
            Data_Quality_Issue__c issue = new Data_Quality_Issue__c(
                Record_ID__c = recordId,
                Object_Type__c = 'Account',
                Field_Name__c = 'BillingAddress',
                Rule_Name__c = 'Active Account Requires Billing Address',
                Error_Message__c = 'Active accounts must have a valid billing address',
                Suggested_Fix__c = '[Requires manual input]',
                Priority__c = 'High',
                Status__c = 'Open',
                Owner_User__c = ownerId,
                Detected_Date__c = System.now()
            );
            issues.add(issue);
        }

        return issues;
    }

    private static List<Data_Quality_Issue__c> evaluateOpportunityRules(SObject record, Id recordId, Id ownerId) {
        List<Data_Quality_Issue__c> issues = new List<Data_Quality_Issue__c>();

        String stageName = (String)record.get('StageName');
        Date closeDate = (Date)record.get('CloseDate');
        Decimal amount = (Decimal)record.get('Amount');

        if (stageName == 'Closed Won') {
            if (closeDate != null && closeDate > Date.today()) {
                Data_Quality_Issue__c issue = new Data_Quality_Issue__c(
                    Record_ID__c = recordId,
                    Object_Type__c = 'Opportunity',
                    Field_Name__c = 'CloseDate',
                    Rule_Name__c = 'Closed Won Date Validation',
                    Error_Message__c = 'Closed Won opportunities must have a close date of today or in the past',
                    Suggested_Fix__c = String.valueOf(Date.today()),
                    Priority__c = 'Critical',
                    Status__c = 'Open',
                    Owner_User__c = ownerId,
                    Detected_Date__c = System.now()
                );
                issues.add(issue);
            }

            if (amount == null || amount <= 0) {
                Data_Quality_Issue__c issue = new Data_Quality_Issue__c(
                    Record_ID__c = recordId,
                    Object_Type__c = 'Opportunity',
                    Field_Name__c = 'Amount',
                    Rule_Name__c = 'Closed Won Requires Amount',
                    Error_Message__c = 'Closed Won opportunities must have an Amount greater than zero',
                    Suggested_Fix__c = '[Requires manual input]',
                    Priority__c = 'Critical',
                    Status__c = 'Open',
                    Owner_User__c = ownerId,
                    Detected_Date__c = System.now()
                );
                issues.add(issue);
            }
        }

        return issues;
    }

    private static String buildIssueSummary(List<Data_Quality_Issue__c> issues) {
        Map<String, Integer> issuesByObject = new Map<String, Integer>();
        Map<String, Integer> issuesByPriority = new Map<String, Integer>();

        for (Data_Quality_Issue__c issue : issues) {
            String objType = issue.Object_Type__c;
            String priority = issue.Priority__c;

            issuesByObject.put(objType, issuesByObject.containsKey(objType) ? issuesByObject.get(objType) + 1 : 1);
            issuesByPriority.put(priority, issuesByPriority.containsKey(priority) ? issuesByPriority.get(priority) + 1 : 1);
        }

        String summary = 'Found ' + issues.size() + ' data quality issue(s). ';
        summary += 'By Object: ';

        for (String objType : issuesByObject.keySet()) {
            summary += objType + ' (' + issuesByObject.get(objType) + ') ';
        }

        summary += '| By Priority: ';

        for (String priority : issuesByPriority.keySet()) {
            summary += priority + ' (' + issuesByPriority.get(priority) + ') ';
        }

        return summary;
    }

    public class DetectionRequest {
        @InvocableVariable(label='Object Type' description='The type of object to scan: Lead, Account, or Opportunity' required=true)
        public String objectType;

        @InvocableVariable(label='Record IDs' description='Optional list of specific record IDs to scan')
        public List<String> recordIds;
    }

    public class DetectionResult {
        @InvocableVariable(label='Issues Found' description='Number of data quality issues detected')
        public Integer issuesFound;

        @InvocableVariable(label='Issue Details' description='Summary of detected issues')
        public String issueDetails;
    }
}
