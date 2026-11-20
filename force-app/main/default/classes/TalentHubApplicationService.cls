public with sharing class TalentHubApplicationService {

    @AuraEnabled
    public static Id createApplication(
        Id candidateId,
        Id jobId
    ) {

        // Validate Candidate ID
        if (candidateId == null) {
            throw new AuraHandledException(
                'Candidate ID cannot be null.'
            );
        }

        // Validate Job ID
        if (jobId == null) {
            throw new AuraHandledException(
                'Job ID cannot be null.'
            );
        }

        // Check whether Candidate exists
        List<Candidate__c> candidates = [
            SELECT Id
            FROM Candidate__c
            WHERE Id = :candidateId
            LIMIT 1
        ];

        if (candidates.isEmpty()) {
            throw new AuraHandledException(
                'Invalid Candidate ID. Candidate not found.'
            );
        }

        // Check whether Job exists
        List<Job__c> jobs = [
            SELECT Id, Status__c
            FROM Job__c
            WHERE Id = :jobId
            LIMIT 1
        ];

        if (jobs.isEmpty()) {
            throw new AuraHandledException(
                'Invalid Job ID. Job not found.'
            );
        }

        // Only Open jobs can receive applications
        Job__c selectedJob = jobs[0];

        if (selectedJob.Status__c != 'Open') {
            throw new AuraHandledException(
                'Applications can only be submitted for Open jobs.'
            );
        }

        // Prevent duplicate active applications
        List<Job_Application__c> existingApplications = [
            SELECT Id, Status__c
            FROM Job_Application__c
            WHERE Candidate__c = :candidateId
            AND Job__c = :jobId
            AND Status__c NOT IN ('Rejected', 'Withdrawn')
            LIMIT 1
        ];

        if (!existingApplications.isEmpty()) {
            throw new AuraHandledException(
                'An active application already exists for this candidate and job.'
            );
        }

        // Create new Job Application
        Job_Application__c newApplication =
            new Job_Application__c();

        newApplication.Candidate__c = candidateId;
        newApplication.Job__c = jobId;
        newApplication.Application_Date__c = Date.today();
        newApplication.Interview_Date__c =
            Date.today().addDays(7);
        newApplication.Status__c = 'Submitted';

        try {
            insert newApplication;
        } catch (DmlException e) {
            throw new AuraHandledException(
                'Unable to create job application: ' +
                e.getDmlMessage(0)
            );
        }

        return newApplication.Id;
    }
}