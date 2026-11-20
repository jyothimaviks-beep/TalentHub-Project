public class JobApplicationTriggerHandler {

    // ==========================================
    // BEFORE INSERT
    // ==========================================
    public static void beforeInsert(
        List<Job_Application__c> newRecords
    ) {

        validateApplications(newRecords, null);
    }


    // ==========================================
    // BEFORE UPDATE
    // ==========================================
    public static void beforeUpdate(
        List<Job_Application__c> newRecords,
        Map<Id, Job_Application__c> oldMap
    ) {

        validateApplications(newRecords, oldMap);
    }


    // ==========================================
    // COMMON VALIDATION METHOD
    // ==========================================
    private static void validateApplications(
        List<Job_Application__c> newRecords,
        Map<Id, Job_Application__c> oldMap
    ) {

        Set<Id> candidateIds = new Set<Id>();
        Set<Id> jobIds = new Set<Id>();

        // Collect Candidate and Job IDs
        for (Job_Application__c app : newRecords) {

            if (app.Candidate__c != null) {
                candidateIds.add(app.Candidate__c);
            }

            if (app.Job__c != null) {
                jobIds.add(app.Job__c);
            }
        }

        // Retrieve Jobs
        Map<Id, Job__c> jobMap = new Map<Id, Job__c>();

        if (!jobIds.isEmpty()) {

            jobMap = new Map<Id, Job__c>([
                SELECT Id, Name, Status__c
                FROM Job__c
                WHERE Id IN :jobIds
            ]);
        }

        // Check whether Job is Open
        // Only during insert or when Job is changed
        for (Job_Application__c app : newRecords) {

            Boolean shouldCheckJob = (oldMap == null);

            if (oldMap != null) {
                Job_Application__c oldApp = oldMap.get(app.Id);

                if (oldApp != null &&
                    app.Job__c != oldApp.Job__c) {

                    shouldCheckJob = true;
                }
            }

            if (shouldCheckJob &&
                app.Job__c != null &&
                jobMap.containsKey(app.Job__c)) {

                Job__c relatedJob = jobMap.get(app.Job__c);

                if (relatedJob.Status__c != 'Open') {

                    app.Job__c.addError(
                        'Applications can only be submitted for Open jobs.'
                    );
                }
            }
        }

        // Find existing applications
        if (!candidateIds.isEmpty() && !jobIds.isEmpty()) {

            List<Job_Application__c> existingApplications = [
                SELECT Id, Candidate__c, Job__c, Status__c
                FROM Job_Application__c
                WHERE Candidate__c IN :candidateIds
                AND Job__c IN :jobIds
            ];

            for (Job_Application__c app : newRecords) {

                // Skip duplicate validation if only status is updated
                if (oldMap != null) {

                    Job_Application__c oldApp = oldMap.get(app.Id);

                    if (oldApp != null &&
                        app.Candidate__c == oldApp.Candidate__c &&
                        app.Job__c == oldApp.Job__c) {

                        continue;
                    }
                }

                for (Job_Application__c existingApp : existingApplications) {

                    // Ignore the same record during update
                    if (app.Id != null &&
                        app.Id == existingApp.Id) {
                        continue;
                    }

                    // Prevent duplicate applications
                    if (app.Candidate__c == existingApp.Candidate__c &&
                        app.Job__c == existingApp.Job__c &&
                        existingApp.Status__c != 'Rejected' &&
                        existingApp.Status__c != 'Withdrawn') {

                        app.addError(
                            'This candidate already has an active application for this job.'
                        );
                    }
                }
            }
        }
    }
}