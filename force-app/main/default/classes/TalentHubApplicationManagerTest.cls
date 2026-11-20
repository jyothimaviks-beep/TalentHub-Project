@isTest
private class TalentHubApplicationManagerTest {

    // Get an active picklist value
    private static String getPicklistValue(
        Schema.SObjectField fieldToken,
        String preferredValue
    ) {
        for (Schema.PicklistEntry entry :
             fieldToken.getDescribe().getPicklistValues()) {

            if (entry.isActive() &&
                entry.getValue() == preferredValue) {
                return entry.getValue();
            }
        }

        for (Schema.PicklistEntry entry :
             fieldToken.getDescribe().getPicklistValues()) {

            if (entry.isActive()) {
                return entry.getValue();
            }
        }

        return null;
    }

    // Create test Candidate
    private static Candidate__c createCandidate() {

        Candidate__c candidate = new Candidate__c(
            First_Name__c = 'Test',
            Last_Name__c = 'Candidate',
            Email__c = 'testcandidate@example.com',
            Highest_Qualification__c =
                getPicklistValue(
                    Candidate__c.Highest_Qualification__c,
                    'Graduate'
                )
        );

        insert candidate;
        return candidate;
    }

    // Create test Job
    private static Job__c createJob() {

        Job__c job = new Job__c(
            Name = 'Test Salesforce Developer',
            Location__c = 'Hyderabad',
            Employment_Type__c =
                getPicklistValue(
                    Job__c.Employment_Type__c,
                    'Full Time'
                ),
            Department__c =
                getPicklistValue(
                    Job__c.Department__c,
                    'IT Department'
                ),
            Experience_Required__c = 2,
            Open_Date__c = Date.today(),
            Status__c = 'Open'
        );

        insert job;
        return job;
    }

    // Create test Job Application
    private static Job_Application__c createApplication(
        Id candidateId,
        Id jobId
    ) {

        Job_Application__c application =
            new Job_Application__c(
                Candidate__c = candidateId,
                Job__c = jobId,
                Application_Date__c = Date.today(),
                Interview_Date__c = Date.today().addDays(10),
                Status__c =
                    getPicklistValue(
                        Job_Application__c.Status__c,
                        'Applied'
                    )
            );

        insert application;
        return application;
    }

    // Create common test records
    @testSetup
    static void setupTestData() {

        Candidate__c candidate = createCandidate();
        Job__c job = createJob();

        createApplication(candidate.Id, job.Id);
    }

    // TEST 1: Retrieve applications using Job ID
    @isTest
    static void testGetApplicationsByJob() {

        Job__c job = [SELECT Id FROM Job__c LIMIT 1];

        Test.startTest();

        List<Job_Application__c> results =
            TalentHubApplicationManager.getApplications(job.Id);

        Test.stopTest();

        System.assertNotEquals(null, results);
        System.assertEquals(1, results.size());
        System.assertEquals(job.Id, results[0].Job__c);
    }

    // TEST 2: Retrieve applications using Candidate ID
    @isTest
    static void testGetApplicationsByCandidate() {

        Candidate__c candidate =
            [SELECT Id FROM Candidate__c LIMIT 1];

        Test.startTest();

        List<Job_Application__c> results =
            TalentHubApplicationManager.getApplications(candidate.Id);

        Test.stopTest();

        System.assertNotEquals(null, results);
        System.assertEquals(1, results.size());
        System.assertEquals(candidate.Id, results[0].Candidate__c);
    }

    // TEST 3: Handle null record ID
    @isTest
    static void testGetApplicationsWithNullId() {

        Boolean exceptionThrown = false;

        Test.startTest();

        try {
            TalentHubApplicationManager.getApplications(null);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }

        Test.stopTest();

        System.assertEquals(
            true,
            exceptionThrown,
            'An exception should be thrown for a null record ID.'
        );
    }

    // TEST 4: Handle unsupported record ID
    @isTest
    static void testGetApplicationsWithInvalidObjectId() {

        Boolean exceptionThrown = false;

        Test.startTest();

        try {
            TalentHubApplicationManager.getApplications(
                UserInfo.getUserId()
            );
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }

        Test.stopTest();

        System.assertEquals(
            true,
            exceptionThrown,
            'An exception should be thrown for an unsupported record ID.'
        );
    }

    // TEST 5: Successfully update application
    @isTest
    static void testUpdateApplication() {

        Job_Application__c application = [
            SELECT Id, Status__c, Interview_Date__c
            FROM Job_Application__c
            LIMIT 1
        ];

        String newStatus = getPicklistValue(
            Job_Application__c.Status__c,
            'Under Review'
        );

        Date newInterviewDate = Date.today().addDays(15);

        Test.startTest();

        TalentHubApplicationManager.updateApplication(
            application.Id,
            newStatus,
            newInterviewDate
        );

        Test.stopTest();

        Job_Application__c updatedApplication = [
            SELECT Status__c, Interview_Date__c
            FROM Job_Application__c
            WHERE Id = :application.Id
        ];

        System.assertEquals(
            newStatus,
            updatedApplication.Status__c
        );

        System.assertEquals(
            newInterviewDate,
            updatedApplication.Interview_Date__c
        );
    }

    // TEST 6: Handle null application ID
    @isTest
    static void testUpdateApplicationWithNullId() {

        Boolean exceptionThrown = false;

        Test.startTest();

        try {
            TalentHubApplicationManager.updateApplication(
                null,
                'Applied',
                Date.today().addDays(5)
            );
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }

        Test.stopTest();

        System.assertEquals(
            true,
            exceptionThrown,
            'An exception should be thrown for a null application ID.'
        );
    }

    // TEST 7: Reject an unsupported application ID
    @isTest
    static void testUpdateApplicationWithInvalidId() {

        Boolean exceptionThrown = false;

        Test.startTest();

        try {
            TalentHubApplicationManager.updateApplication(
                UserInfo.getUserId(),
                'Applied',
                Date.today().addDays(5)
            );
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }

        Test.stopTest();

        System.assertEquals(
            true,
            exceptionThrown,
            'An exception should be thrown for an invalid application ID.'
        );
    }
}