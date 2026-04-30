public class DataQualityScanScheduler implements Schedulable {

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new DataQualityScanBatch('Lead'), 200);
        Database.executeBatch(new DataQualityScanBatch('Account'), 200);
        Database.executeBatch(new DataQualityScanBatch('Opportunity'), 200);
    }
}
