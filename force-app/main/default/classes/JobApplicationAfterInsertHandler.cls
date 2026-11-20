public class JobApplicationAfterInsertHandler {

    public static void afterInsert(
        List<Job_Application__c> newRecords
    ) {

        // Collect Job Application IDs
        List<Id> applicationIds = new List<Id>();

        for (Job_Application__c application : newRecords) {

            if (application.Id != null) {
                applicationIds.add(application.Id);
            }
        }

        // Call asynchronous email notification
        if (!applicationIds.isEmpty()) {

            TalentHubApplicationNotification.sendApplicationConfirmationEmail(applicationIds);
        }
    }
}