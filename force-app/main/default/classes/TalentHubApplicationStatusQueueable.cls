public with sharing class TalentHubApplicationStatusQueueable implements Queueable {

    private Set<Id> applicationIds;

    public TalentHubApplicationStatusQueueable(Set<Id> applicationIds) {
        this.applicationIds = applicationIds;
    }

    public void execute(QueueableContext context) {
        if (applicationIds == null || applicationIds.isEmpty()) {
            return;
        }

        List<Job_Application__c> toUpdate = new List<Job_Application__c>();
        for (Job_Application__c app : [
            SELECT Id, Status__c
            FROM Job_Application__c
            WHERE Id IN :applicationIds
            AND Status__c = 'Applied'
        ]) {
            app.Status__c = 'Screening';
            toUpdate.add(app);
        }

        if (!toUpdate.isEmpty()) {
            List<Database.SaveResult> results = Database.update(toUpdate, false);
            for (Database.SaveResult sr : results) {
                if (!sr.isSuccess()) {
                    System.debug(LoggingLevel.ERROR,
                        'Status update failed: ' + sr.getErrors()[0].getMessage());
                }
            }
        }
    }
}