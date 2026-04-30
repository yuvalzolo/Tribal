public with sharing class DQIssueController {

    @AuraEnabled(cacheable=false)
    public static List<Data_Quality_Issue__c> getIssues(String objectType, String priority, String status) {
        try {
            List<Data_Quality_Issue__c> results;

            // Build query with explicit bind variables to avoid SOQL injection
            if (String.isNotBlank(objectType) && String.isNotBlank(priority) && String.isNotBlank(status)) {
                results = [
                    SELECT Id, Name, Record_ID__c, Object_Type__c, Field_Name__c, Rule_Name__c,
                           Error_Message__c, Suggested_Fix__c, Priority__c, Status__c, Owner_User__c,
                           Owner_User__r.Name, Detected_Date__c, Resolved_Date__c
                    FROM Data_Quality_Issue__c
                    WHERE Object_Type__c = :objectType AND Priority__c = :priority AND Status__c = :status
                    ORDER BY Detected_Date__c DESC
                    LIMIT 1000
                ];
            } else if (String.isNotBlank(objectType) && String.isNotBlank(priority)) {
                results = [
                    SELECT Id, Name, Record_ID__c, Object_Type__c, Field_Name__c, Rule_Name__c,
                           Error_Message__c, Suggested_Fix__c, Priority__c, Status__c, Owner_User__c,
                           Owner_User__r.Name, Detected_Date__c, Resolved_Date__c
                    FROM Data_Quality_Issue__c
                    WHERE Object_Type__c = :objectType AND Priority__c = :priority
                    ORDER BY Detected_Date__c DESC
                    LIMIT 1000
                ];
            } else if (String.isNotBlank(objectType) && String.isNotBlank(status)) {
                results = [
                    SELECT Id, Name, Record_ID__c, Object_Type__c, Field_Name__c, Rule_Name__c,
                           Error_Message__c, Suggested_Fix__c, Priority__c, Status__c, Owner_User__c,
                           Owner_User__r.Name, Detected_Date__c, Resolved_Date__c
                    FROM Data_Quality_Issue__c
                    WHERE Object_Type__c = :objectType AND Status__c = :status
                    ORDER BY Detected_Date__c DESC
                    LIMIT 1000
                ];
            } else if (String.isNotBlank(priority) && String.isNotBlank(status)) {
                results = [
                    SELECT Id, Name, Record_ID__c, Object_Type__c, Field_Name__c, Rule_Name__c,
                           Error_Message__c, Suggested_Fix__c, Priority__c, Status__c, Owner_User__c,
                           Owner_User__r.Name, Detected_Date__c, Resolved_Date__c
                    FROM Data_Quality_Issue__c
                    WHERE Priority__c = :priority AND Status__c = :status
                    ORDER BY Detected_Date__c DESC
                    LIMIT 1000
                ];
            } else if (String.isNotBlank(objectType)) {
                results = [
                    SELECT Id, Name, Record_ID__c, Object_Type__c, Field_Name__c, Rule_Name__c,
                           Error_Message__c, Suggested_Fix__c, Priority__c, Status__c, Owner_User__c,
                           Owner_User__r.Name, Detected_Date__c, Resolved_Date__c
                    FROM Data_Quality_Issue__c
                    WHERE Object_Type__c = :objectType
                    ORDER BY Detected_Date__c DESC
                    LIMIT 1000
                ];
            } else if (String.isNotBlank(priority)) {
                results = [
                    SELECT Id, Name, Record_ID__c, Object_Type__c, Field_Name__c, Rule_Name__c,
                           Error_Message__c, Suggested_Fix__c, Priority__c, Status__c, Owner_User__c,
                           Owner_User__r.Name, Detected_Date__c, Resolved_Date__c
                    FROM Data_Quality_Issue__c
                    WHERE Priority__c = :priority
                    ORDER BY Detected_Date__c DESC
                    LIMIT 1000
                ];
            } else if (String.isNotBlank(status)) {
                results = [
                    SELECT Id, Name, Record_ID__c, Object_Type__c, Field_Name__c, Rule_Name__c,
                           Error_Message__c, Suggested_Fix__c, Priority__c, Status__c, Owner_User__c,
                           Owner_User__r.Name, Detected_Date__c, Resolved_Date__c
                    FROM Data_Quality_Issue__c
                    WHERE Status__c = :status
                    ORDER BY Detected_Date__c DESC
                    LIMIT 1000
                ];
            } else {
                results = [
                    SELECT Id, Name, Record_ID__c, Object_Type__c, Field_Name__c, Rule_Name__c,
                           Error_Message__c, Suggested_Fix__c, Priority__c, Status__c, Owner_User__c,
                           Owner_User__r.Name, Detected_Date__c, Resolved_Date__c
                    FROM Data_Quality_Issue__c
                    WHERE Id != null
                    ORDER BY Detected_Date__c DESC
                    LIMIT 1000
                ];
            }

            return results;
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving issues: ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=false)
    public static Map<String, Integer> getIssueStatistics() {
        Map<String, Integer> stats = new Map<String, Integer>();

        try {
            List<AggregateResult> totalByObject = [
                SELECT Object_Type__c objType, COUNT(Id) cnt
                FROM Data_Quality_Issue__c
                GROUP BY Object_Type__c
            ];

            for (AggregateResult ar : totalByObject) {
                String objType = (String)ar.get('objType');
                Integer count = (Integer)ar.get('cnt');
                stats.put(objType, count);
            }

            List<AggregateResult> totalByPriority = [
                SELECT Priority__c priority, COUNT(Id) cnt
                FROM Data_Quality_Issue__c
                GROUP BY Priority__c
            ];

            for (AggregateResult ar : totalByPriority) {
                String priority = (String)ar.get('priority');
                Integer count = (Integer)ar.get('cnt');
                stats.put('Priority_' + priority, count);
            }

            List<AggregateResult> totalByStatus = [
                SELECT Status__c status, COUNT(Id) cnt
                FROM Data_Quality_Issue__c
                GROUP BY Status__c
            ];

            for (AggregateResult ar : totalByStatus) {
                String status = (String)ar.get('status');
                Integer count = (Integer)ar.get('cnt');
                stats.put('Status_' + status, count);
            }

        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving statistics: ' + e.getMessage());
        }

        return stats;
    }

    @AuraEnabled(cacheable=false)
    public static List<Map<String, String>> getPriorityPicklistValues() {
        List<Map<String, String>> options = new List<Map<String, String>>();

        try {
            Schema.DescribeFieldResult fieldResult = Data_Quality_Issue__c.Priority__c.getDescribe();
            List<Schema.PicklistEntry> entries = fieldResult.getPicklistValues();

            for (Schema.PicklistEntry entry : entries) {
                if (entry.isActive()) {
                    options.add(new Map<String, String>{
                        'label' => entry.getLabel(),
                        'value' => entry.getValue()
                    });
                }
            }
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving priority values: ' + e.getMessage());
        }

        return options;
    }

    @AuraEnabled(cacheable=false)
    public static List<Map<String, String>> getStatusPicklistValues() {
        List<Map<String, String>> options = new List<Map<String, String>>();

        try {
            Schema.DescribeFieldResult fieldResult = Data_Quality_Issue__c.Status__c.getDescribe();
            List<Schema.PicklistEntry> entries = fieldResult.getPicklistValues();

            for (Schema.PicklistEntry entry : entries) {
                if (entry.isActive()) {
                    options.add(new Map<String, String>{
                        'label' => entry.getLabel(),
                        'value' => entry.getValue()
                    });
                }
            }
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving status values: ' + e.getMessage());
        }

        return options;
    }

    @AuraEnabled(cacheable=false)
    public static String approveMultipleFixes(List<String> issueIds) {
        try {
            Integer successCount = 0;
            Integer failureCount = 0;

            for (String issueId : issueIds) {
                FieldCorrectionService.UpdateRequest request = new FieldCorrectionService.UpdateRequest();
                request.issueId = issueId;
                request.approvalStatus = 'Approved';

                List<FieldCorrectionService.UpdateResult> results = FieldCorrectionService.updateRecordField(
                    new List<FieldCorrectionService.UpdateRequest>{ request }
                );

                if (!results.isEmpty() && results[0].updateStatus == 'Success') {
                    successCount++;
                } else {
                    failureCount++;
                }
            }

            return 'Approved ' + successCount + ' fix(es). ' + failureCount + ' failed.';

        } catch (Exception e) {
            throw new AuraHandledException('Error approving fixes: ' + e.getMessage());
        }
    }
}
