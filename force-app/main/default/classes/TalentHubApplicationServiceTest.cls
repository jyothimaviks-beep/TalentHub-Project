@isTest
private class TalentHubApplicationServiceTest {

    // ==========================================
    // HELPER 1: CREATE CANDIDATE
    // ==========================================

    private static Candidate__c createCandidate(
        String suffix
    ) {

        Candidate__c candidate = new Candidate__c(
            First_Name__c = 'John',
            Last_Name__c = suffix,
            Email__c = suffix + '@example.com',
            Highest_Qualification__c = 'B.E'
        );

        insert candidate;

        return candidate;
    }

    // ==========================================
    // HELPER 2: CREATE JOB
    // ==========================================

    private static Job__c createJob(String status) {

        Job__c job = new Job__c(
            Name = 'Software Developer',
            Location__c = 'Hyderabad',
            Employment_Type__c = 'Full Time',
            Department__c = 'IT Department',
            Experience_Required__c = 2,
            Open_Date__c = Date.today(),
            Status__c = status
        );

        insert job;

        return job;
    }

    // ==========================================
    // HELPER 3: GENERATE NON-EXISTING RECORD ID
    // ==========================================

    private static Id generateInvalidId(Id existingId) {

        String prefix = String.valueOf(existingId).substring(0, 3);

        return Id.valueOf(prefix + '000000000000');
    }

    // ==========================================
    // TEST 1: SUCCESSFUL APPLICATION
    // ==========================================

    @isTest
    static void testCreateApplicationSuccess() {

        Candidate__c candidate =
            createCandidate('success');

        Job__c job = createJob('Open');

        Test.startTest();

        Id applicationId =
            TalentHubApplicationService.createApplication(
                candidate.Id,
                job.Id
            );

        Test.stopTest();

        Job_Application__c result = [
            SELECT Id,
                   Candidate__c,
                   Job__c,
                   Application_Date__c,
                   Interview_Date__c,
                   Status__c
            FROM Job_Application__c
            WHERE Id = :applicationId
        ];

        System.assertNotEquals(null, applicationId);

        System.assertEquals(
            candidate.Id,
            result.Candidate__c
        );

        System.assertEquals(
            job.Id,
            result.Job__c
        );

        System.assertEquals(
            Date.today(),
            result.Application_Date__c
        );

        System.assertEquals(
            'Submitted',
            result.Status__c
        );

        System.assertEquals(
            Date.today().addDays(7),
            result.Interview_Date__c
        );
    }

    // ==========================================
    // TEST 2: NULL CANDIDATE ID
    // ==========================================

    @isTest
    static void testNullCandidateId() {

        Job__c job = createJob('Open');

        Boolean exceptionThrown = false;

        try {

            TalentHubApplicationService.createApplication(
                null,
                job.Id
            );

        } catch (AuraHandledException e) {

            exceptionThrown = true;
        }

        System.assertEquals(
            true,
            exceptionThrown,
            'Expected exception for null Candidate ID.'
        );
    }

    // ==========================================
    // TEST 3: NULL JOB ID
    // ==========================================

    @isTest
    static void testNullJobId() {

        Candidate__c candidate =
            createCandidate('nulljob');

        Boolean exceptionThrown = false;

        try {

            TalentHubApplicationService.createApplication(
                candidate.Id,
                null
            );

        } catch (AuraHandledException e) {

            exceptionThrown = true;
        }

        System.assertEquals(
            true,
            exceptionThrown,
            'Expected exception for null Job ID.'
        );
    }

    // ==========================================
    // TEST 4: INVALID CANDIDATE ID
    // ==========================================

    @isTest
    static void testInvalidCandidateId() {

        Candidate__c candidate =
            createCandidate('invalidcandidate');

        Job__c job = createJob('Open');

        Id invalidCandidateId =
            generateInvalidId(candidate.Id);

        Boolean exceptionThrown = false;

        try {

            TalentHubApplicationService.createApplication(
                invalidCandidateId,
                job.Id
            );

        } catch (AuraHandledException e) {

            exceptionThrown = true;
        }

        System.assertEquals(
            true,
            exceptionThrown,
            'Expected exception for invalid Candidate ID.'
        );
    }

    // ==========================================
    // TEST 5: INVALID JOB ID
    // ==========================================

    @isTest
    static void testInvalidJobId() {

        Candidate__c candidate =
            createCandidate('invalidjob');

        Job__c job = createJob('Open');

        Id invalidJobId =
            generateInvalidId(job.Id);

        Boolean exceptionThrown = false;

        try {

            TalentHubApplicationService.createApplication(
                candidate.Id,
                invalidJobId
            );

        } catch (AuraHandledException e) {

            exceptionThrown = true;
        }

        System.assertEquals(
            true,
            exceptionThrown,
            'Expected exception for invalid Job ID.'
        );
    }

    // ==========================================
    // TEST 6: CLOSED JOB
    // ==========================================

    @isTest
    static void testClosedJob() {

        Candidate__c candidate =
            createCandidate('closed');

        Job__c job = createJob('Closed');

        Boolean exceptionThrown = false;

        try {

            TalentHubApplicationService.createApplication(
                candidate.Id,
                job.Id
            );

        } catch (AuraHandledException e) {

            exceptionThrown = true;
        }

        System.assertEquals(
            true,
            exceptionThrown,
            'Expected exception for Closed Job.'
        );
    }

    // ==========================================
    // TEST 7: DUPLICATE APPLICATION
    // ==========================================

    @isTest
    static void testDuplicateApplication() {

        Candidate__c candidate =
            createCandidate('duplicate');

        Job__c job = createJob('Open');

        Test.startTest();

        // First application should succeed

        Id firstApplicationId =
            TalentHubApplicationService.createApplication(
                candidate.Id,
                job.Id
            );

        System.assertNotEquals(
            null,
            firstApplicationId
        );

        // Second application should fail

        Boolean exceptionThrown = false;

        try {

            TalentHubApplicationService.createApplication(
                candidate.Id,
                job.Id
            );

        } catch (AuraHandledException e) {

            exceptionThrown = true;
        }

        Test.stopTest();

        System.assertEquals(
            true,
            exceptionThrown,
            'Duplicate active application should not be allowed.'
        );

        // Verify only one application exists

        Integer applicationCount = [
            SELECT COUNT()
            FROM Job_Application__c
            WHERE Candidate__c = :candidate.Id
            AND Job__c = :job.Id
        ];

        System.assertEquals(
            1,
            applicationCount,
            'Only one application should exist.'
        );
    }
}