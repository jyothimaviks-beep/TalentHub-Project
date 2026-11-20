public with sharing class talentHubApplicationManager {

    // Retrieve applications related to a Job or Candidate
    @AuraEnabled(cacheable=true)
    public static List<Job_Application__c> getApplications(Id recordId) {

        if (recordId == null) {
            throw new AuraHandledException('Record ID is required.');
        }

        try {
            if (recordId.getSObjectType() == Job__c.SObjectType) {

                return [
                    SELECT Id,
                           Name,
                           Application_Date__c,
                           Status__c,
                           Interview_Date__c,
                           Candidate__c,
                           Candidate__r.First_Name__c,
                           Candidate__r.Last_Name__c,
                           Candidate__r.Email__c,
                           Job__c,
                           Job__r.Name
                    FROM Job_Application__c
                    WHERE Job__c = :recordId
                    WITH USER_MODE
                    ORDER BY Application_Date__c DESC
                ];

            } else if (recordId.getSObjectType() ==
                       Candidate__c.SObjectType) {

                return [
                    SELECT Id,
                           Name,
                           Application_Date__c,
                           Status__c,
                           Interview_Date__c,
                           Candidate__c,
                           Candidate__r.First_Name__c,
                           Candidate__r.Last_Name__c,
                           Candidate__r.Email__c,
                           Job__c,
                           Job__r.Name
                    FROM Job_Application__c
                    WHERE Candidate__c = :recordId
                    WITH USER_MODE
                    ORDER BY Application_Date__c DESC
                ];
            }

            throw new AuraHandledException(
                'Please provide a valid Job or Candidate record ID.'
            );

        } catch (Exception e) {
            throw new AuraHandledException(
                'Unable to retrieve applications: ' + e.getMessage()
            );
        }
    }

    // Update permitted application fields
    @AuraEnabled
    public static void updateApplication(
        Id applicationId,
        String status,
        Date interviewDate
    ) {

        if (applicationId == null) {
            throw new AuraHandledException(
                'Application ID is required.'
            );
        }

        if (!Job_Application__c.SObjectType.getDescribe().isUpdateable()
            || !Job_Application__c.Status__c.getDescribe().isUpdateable()
            || !Job_Application__c.Interview_Date__c.getDescribe().isUpdateable()) {

            throw new AuraHandledException(
                'You do not have permission to update these application fields.'
            );
        }

        try {
            Job_Application__c application =
                new Job_Application__c(
                    Id = applicationId,
                    Status__c = status,
                    Interview_Date__c = interviewDate
                );

            // Enforce field-level security
            SObjectAccessDecision decision =
                Security.stripInaccessible(
                    AccessType.UPDATABLE,
                    new List<Job_Application__c>{ application }
                );

            if (!decision.getRemovedFields().isEmpty()) {
                throw new AuraHandledException(
                    'You are not authorized to update these fields.'
                );
            }

            // Enforce record sharing through with sharing
            update (List<Job_Application__c>) decision.getRecords();

        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            throw new AuraHandledException(
                'Unable to update application: ' + e.getMessage()
            );
        }
    }
}