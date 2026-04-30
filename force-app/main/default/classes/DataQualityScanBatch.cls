public class DataQualityScanBatch implements Database.Batchable<SObject> {

    private String objectType;

    public DataQualityScanBatch(String objectType) {
        this.objectType = objectType;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        String query = '';

        if (objectType == 'Lead') {
            query = 'SELECT Id, OwnerId, Status, Company, LastActivityDate FROM Lead';
        } else if (objectType == 'Account') {
            query = 'SELECT Id, OwnerId, BillingStreet, BillingCity FROM Account';
        } else if (objectType == 'Opportunity') {
            query = 'SELECT Id, OwnerId, StageName, CloseDate, Amount FROM Opportunity';
        } else {
            query = 'SELECT Id FROM Lead LIMIT 0';
        }

        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        List<String> recordIds = new List<String>();

        for (SObject record : scope) {
            recordIds.add((String)record.get('Id'));
        }

        DataQualityRuleEngine.DetectionRequest request = new DataQualityRuleEngine.DetectionRequest();
        request.objectType = objectType;
        request.recordIds = recordIds;

        DataQualityRuleEngine.detectDataQualityIssues(new List<DataQualityRuleEngine.DetectionRequest>{ request });
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('Data quality scan batch completed for object type: ' + objectType);
    }
}
