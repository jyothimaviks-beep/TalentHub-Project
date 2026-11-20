public class JobTriggerHandler {

    // BEFORE INSERT
    public static void beforeInsert(List<Job__c> newRecords) {

        validateJobDates(newRecords);
    }

    // BEFORE UPDATE
    public static void beforeUpdate(List<Job__c> newRecords) {

        validateJobDates(newRecords);
    }

    // COMMON VALIDATION METHOD
    private static void validateJobDates(List<Job__c> jobs) {

        for (Job__c job : jobs) {

            // Check whether Open Date is in the past
            if (job.Open_Date__c != null &&
                job.Open_Date__c < Date.today()) {

                job.Open_Date__c.addError(
                    'Open Date cannot be earlier than today.'
                );
            }
        }
    }
}