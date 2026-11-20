public with sharing class TalentHubExpiredJobBatch
    implements Database.Batchable<SObject>, Database.Stateful {

    // Jobs with a Close Date earlier than this date are treated as expired.
    // Defaults to today; the test class passes a later date.
    private Date cutoffDate;

    // Database.Stateful keeps these counters across all batches of one run
    private Integer successCount = 0;
    private Integer failureCount = 0;
    private List<String> errorMessages = new List<String>();

    public TalentHubExpiredJobBatch() {
        this(Date.today());
    }

    public TalentHubExpiredJobBatch(Date cutoffDate) {
        this.cutoffDate = cutoffDate;
    }

    // 1. Select only Open jobs whose Close Date is earlier than the cutoff (today)
    public Database.QueryLocator start(Database.BatchableContext bc) {
        Date cutoff = cutoffDate;
        return Database.getQueryLocator([
            SELECT Id, Status__c, Close_Date__c
            FROM Job__c
            WHERE Status__c = 'Open'
            AND Close_Date__c < :cutoff
        ]);
    }

    // 2. Called once per batch of records (scope)
    public void execute(Database.BatchableContext bc, List<Job__c> scope) {
        for (Job__c job : scope) {
            job.Status__c = 'Closed';
        }

        try {
            // allOrNone = false: one bad record does not roll back the others
            List<Database.SaveResult> results = Database.update(scope, false);

            for (Integer i = 0; i < results.size(); i++) {
                if (results[i].isSuccess()) {
                    successCount++;
                } else {
                    failureCount++;
                    errorMessages.add(scope[i].Id + ': '
                        + results[i].getErrors()[0].getMessage());
                }
            }
        } catch (Exception e) {
            failureCount += scope.size();
            errorMessages.add('Batch failed: ' + e.getMessage());
        }
    }

    // 3. Called once after all batches finish
    public void finish(Database.BatchableContext bc) {
        System.debug('Expired jobs closed: ' + successCount);
        System.debug('Expired jobs failed: ' + failureCount);
        for (String msg : errorMessages) {
            System.debug(LoggingLevel.ERROR, 'Expired job error: ' + msg);
        }
    }
}