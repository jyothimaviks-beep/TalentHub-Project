@IsTest
private class TalentHubEligibilityServiceTest {

    // Create test data
    @TestSetup
    static void setupTestData() {

        List<Candidate__c> candidates = new List<Candidate__c>{

            new Candidate__c(
                First_Name__c = 'Eligible',
                Last_Name__c = 'Candidate',
                Email__c = 'eligible@test.com',
                Highest_Qualification__c = 'B.Tech',
                Total_Experience__c = 5.0
            ),

            new Candidate__c(
                First_Name__c = 'Ineligible',
                Last_Name__c = 'Candidate',
                Email__c = 'ineligible@test.com',
                Highest_Qualification__c = 'B.Tech',
                Total_Experience__c = 1.0
            ),

            new Candidate__c(
                First_Name__c = 'Equal',
                Last_Name__c = 'Candidate',
                Email__c = 'equal@test.com',
                Highest_Qualification__c = 'B.Tech',
                Total_Experience__c = 2.0
            )
        };

        insert candidates;

        Job__c job = new Job__c(
            Name = 'Salesforce Developer',
            Department__c = 'IT Department',
            Location__c = 'Hyderabad',
            Employment_Type__c = 'Full Time',
            Open_Date__c = Date.today(),
            Status__c = 'Open',
            Experience_Required__c = 2
        );

        insert job;
    }

    // 1. Eligible candidate
    @IsTest
    static void testEligibleCandidate() {

        Candidate__c candidate = [
            SELECT Id FROM Candidate__c
            WHERE Email__c = 'eligible@test.com'
            LIMIT 1
        ];

        Job__c job = [SELECT Id FROM Job__c LIMIT 1];

        Test.startTest();

        Boolean result =
            TalentHubEligibilityService.checkEligibility(
                candidate.Id, job.Id
            );

        Test.stopTest();

        System.assertEquals(true, result);
    }

    // 2. Ineligible candidate
    @IsTest
    static void testIneligibleCandidate() {

        Candidate__c candidate = [
            SELECT Id FROM Candidate__c
            WHERE Email__c = 'ineligible@test.com'
            LIMIT 1
        ];

        Job__c job = [SELECT Id FROM Job__c LIMIT 1];

        Test.startTest();

        Boolean result =
            TalentHubEligibilityService.checkEligibility(
                candidate.Id, job.Id
            );

        Test.stopTest();

        System.assertEquals(false, result);
    }

    // 3. Equal experience
    @IsTest
    static void testEqualExperienceCandidate() {

        Candidate__c candidate = [
            SELECT Id FROM Candidate__c
            WHERE Email__c = 'equal@test.com'
            LIMIT 1
        ];

        Job__c job = [SELECT Id FROM Job__c LIMIT 1];

        Test.startTest();

        Boolean result =
            TalentHubEligibilityService.checkEligibility(
                candidate.Id, job.Id
            );

        Test.stopTest();

        System.assertEquals(true, result);
    }

    // 4. Null candidate ID
    @IsTest
    static void testNullCandidateId() {

        Job__c job = [SELECT Id FROM Job__c LIMIT 1];

        Boolean exceptionThrown = false;

        Test.startTest();

        try {
            TalentHubEligibilityService.checkEligibility(
                null, job.Id
            );
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }

        Test.stopTest();

        System.assertEquals(true, exceptionThrown);
    }

    // 5. Null job ID
    @IsTest
    static void testNullJobId() {

        Candidate__c candidate = [
            SELECT Id FROM Candidate__c LIMIT 1
        ];

        Boolean exceptionThrown = false;

        Test.startTest();

        try {
            TalentHubEligibilityService.checkEligibility(
                candidate.Id, null
            );
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }

        Test.stopTest();

        System.assertEquals(true, exceptionThrown);
    }

    // 6. Candidate record does not exist
    @IsTest
    static void testCandidateDoesNotExist() {

        Candidate__c candidate = [
            SELECT Id FROM Candidate__c
            WHERE Email__c = 'eligible@test.com'
            LIMIT 1
        ];

        Job__c job = [SELECT Id FROM Job__c LIMIT 1];

        delete candidate;

        Boolean exceptionThrown = false;

        Test.startTest();

        try {
            TalentHubEligibilityService.checkEligibility(
                candidate.Id, job.Id
            );
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }

        Test.stopTest();

        System.assertEquals(true, exceptionThrown);
    }

    // 7. Job record does not exist
    @IsTest
    static void testJobDoesNotExist() {

        Candidate__c candidate = [
            SELECT Id FROM Candidate__c
            WHERE Email__c = 'eligible@test.com'
            LIMIT 1
        ];

        Job__c job = [SELECT Id FROM Job__c LIMIT 1];

        delete job;

        Boolean exceptionThrown = false;

        Test.startTest();

        try {
            TalentHubEligibilityService.checkEligibility(
                candidate.Id, job.Id
            );
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }

        Test.stopTest();

        System.assertEquals(true, exceptionThrown);
    }

    // 8. Candidate experience is missing
    @IsTest
    static void testMissingCandidateExperience() {

        Candidate__c candidate = [
            SELECT Id, Total_Experience__c
            FROM Candidate__c
            WHERE Email__c = 'eligible@test.com'
            LIMIT 1
        ];

        candidate.Total_Experience__c = null;
        update candidate;

        Job__c job = [SELECT Id FROM Job__c LIMIT 1];

        Boolean exceptionThrown = false;

        Test.startTest();

        try {
            TalentHubEligibilityService.checkEligibility(
                candidate.Id, job.Id
            );
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }

        Test.stopTest();

        System.assertEquals(true, exceptionThrown);
    }
}