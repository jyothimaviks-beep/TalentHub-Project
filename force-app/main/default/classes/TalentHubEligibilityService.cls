public with sharing class TalentHubEligibilityService {
	@AuraEnabled
    public static Boolean checkEligibility(
        Id candidateId,
        Id jobId
    ) {

        // 1. Validate input IDs
        if (candidateId == null || jobId == null) {
            throw new AuraHandledException(
                'Candidate ID and Job ID are required.'
            );
        }

        // 2. Get Candidate
        List<Candidate__c> candidates = [
            SELECT Id, Total_Experience__c
            FROM Candidate__c
            WHERE Id = :candidateId
            WITH USER_MODE
            LIMIT 1
        ];

        if (candidates.isEmpty()) {
            throw new AuraHandledException(
                'Candidate record not found.'
            );
        }

        // 3. Get Job
        List<Job__c> jobs = [
            SELECT Id, Experience_Required__c
            FROM Job__c
            WHERE Id = :jobId
            WITH USER_MODE
            LIMIT 1
        ];

        if (jobs.isEmpty()) {
            throw new AuraHandledException(
                'Job record not found.'
            );
        }

        // 4. Get experience values
        Candidate__c candidate = candidates[0];
        Job__c job = jobs[0];

        // 5. Validate experience
        if (candidate.Total_Experience__c == null ||
            job.Experience_Required__c == null) {

            throw new AuraHandledException(
                'Experience information is missing.'
            );
        }

        // 6. Check eligibility
        return candidate.Total_Experience__c >=
               job.Experience_Required__c;
    }
}