@IsTest
public class JobApplicationTriggerHandlerTest {

    // Get a valid picklist value
    private static String getActivePicklistValue(
        Schema.SObjectField fieldToken,
        Set<String> excludedValues
    ) {
        for (Schema.PicklistEntry entry :
             fieldToken.getDescribe().getPicklistValues()) {

            if (entry.isActive() &&
                !excludedValues.contains(entry.getValue())) {

                return entry.getValue();
            }
        }

        return null;
    }

    // Create Candidate
    private static Candidate__c createCandidate(String email) {

        String qualification = getActivePicklistValue(
            Candidate__c.Highest_Qualification__c,
            new Set<String>()
        );

        return new Candidate__c(
            First_Name__c = 'John',
            Last_Name__c = 'Smith',
            Email__c = email,
            Highest_Qualification__c = qualification
        );
    }

    // Create Job
    private static Job__c createJob(String jobName) {

        return new Job__c(
            Name = jobName,
            Location__c = 'Hyderabad',
            Employment_Type__c = 'Full Time',
            Department__c = 'IT Department',
            Experience_Required__c = 2,
            Open_Date__c = Date.today(),
            Status__c = 'Open'
        );
    }

    // Create Job Application
    private static Job_Application__c createApplication(
        Id candidateId,
        Id jobId
    ) {

        return new Job_Application__c(
            Candidate__c = candidateId,
            Job__c = jobId,
            Application_Date__c = Date.today(),
            Interview_Date__c = Date.today().addDays(10),
            Status__c = 'Applied'
        );
    }


    // TEST 1: Valid Application Insert
    @IsTest
    static void testValidApplicationInsert() {

        Candidate__c candidate =
            createCandidate('john1@example.com');
        insert candidate;

        Job__c job = createJob('Salesforce Developer');
        insert job;

        Job_Application__c app =
            createApplication(candidate.Id, job.Id);

        Test.startTest();
        insert app;
        Test.stopTest();

        System.assertNotEquals(
            null,
            app.Id,
            'Valid application should be inserted.'
        );
    }


    // TEST 2: Application for Closed Job
    @IsTest
    static void testInsertToClosedJob() {

        Candidate__c candidate =
            createCandidate('john2@example.com');
        insert candidate;

        Job__c job = createJob('Java Developer');
        job.Status__c = 'Closed';
        insert job;

        Job_Application__c app =
            createApplication(candidate.Id, job.Id);

        Test.startTest();

        Database.SaveResult result =
            Database.insert(app, false);

        Test.stopTest();

        System.assertEquals(false, result.isSuccess());

        System.assert(
            result.getErrors()[0].getMessage().contains(
                'Applications can only be submitted for Open jobs.'
            ),
            'Expected closed Job validation error.'
        );
    }


    // TEST 3: Prevent Duplicate Application
    @IsTest
    static void testDuplicateApplication() {

        Candidate__c candidate =
            createCandidate('john3@example.com');
        insert candidate;

        Job__c job = createJob('Apex Developer');
        insert job;

        Job_Application__c app1 =
            createApplication(candidate.Id, job.Id);
        insert app1;

        Job_Application__c app2 =
            createApplication(candidate.Id, job.Id);

        Test.startTest();

        Database.SaveResult result =
            Database.insert(app2, false);

        Test.stopTest();

        System.assertEquals(false, result.isSuccess());

        System.assert(
            result.getErrors()[0].getMessage().contains(
                'already has an active application'
            ),
            'Expected duplicate application validation error.'
        );
    }


    // TEST 4: Valid Application Update
    @IsTest
    static void testValidApplicationUpdate() {

        Candidate__c candidate =
            createCandidate('john4@example.com');
        insert candidate;

        Job__c job = createJob('Python Developer');
        insert job;

        Job_Application__c app =
            createApplication(candidate.Id, job.Id);
        insert app;

        // Re-query only the required fields
        Job_Application__c appToUpdate = [
            SELECT Id, Interview_Date__c
            FROM Job_Application__c
            WHERE Id = :app.Id
        ];

        appToUpdate.Interview_Date__c =
            Date.today().addDays(15);

        Test.startTest();
        update appToUpdate;
        Test.stopTest();

        Job_Application__c updatedApp = [
            SELECT Id, Interview_Date__c
            FROM Job_Application__c
            WHERE Id = :app.Id
        ];

        System.assertEquals(
            Date.today().addDays(15),
            updatedApp.Interview_Date__c
        );
    }


    // TEST 5: Bulk Application Insert
    @IsTest
    static void testBulkApplicationInsert() {

        List<Candidate__c> candidates =
            new List<Candidate__c>();

        for (Integer i = 0; i < 10; i++) {

            candidates.add(
                createCandidate('bulk' + i + '@example.com')
            );
        }

        insert candidates;

        Job__c job = createJob('Bulk Developer');
        insert job;

        List<Job_Application__c> applications =
            new List<Job_Application__c>();

        for (Candidate__c candidate : candidates) {

            applications.add(
                createApplication(candidate.Id, job.Id)
            );
        }

        Test.startTest();
        insert applications;
        Test.stopTest();

        System.assertEquals(
            10,
            [SELECT COUNT()
             FROM Job_Application__c
             WHERE Job__c = :job.Id],
            'All 10 applications should be inserted.'
        );
    }


    // TEST 6: Allow Status Update When Job Is Closed
    @IsTest
    static void testStatusUpdateWhenJobClosed() {

        Candidate__c candidate =
            createCandidate('john8@example.com');
        insert candidate;

        Job__c job = createJob('Salesforce Admin');
        insert job;

        Job_Application__c app =
            createApplication(candidate.Id, job.Id);
        insert app;

        // Close the Job
        job.Status__c = 'Closed';
        update job;

        // Re-query only Id and Status__c
        Job_Application__c appToUpdate = [
            SELECT Id, Status__c
            FROM Job_Application__c
            WHERE Id = :app.Id
        ];

        // Update only application status
        appToUpdate.Status__c = 'Screening';

        Test.startTest();

        Database.SaveResult result =
            Database.update(appToUpdate, false);

        Test.stopTest();

        // Display exact error if update fails
        if (!result.isSuccess()) {

            for (Database.Error err : result.getErrors()) {

                System.debug(
                    'UPDATE ERROR: ' + err.getMessage()
                );

                System.debug(
                    'ERROR FIELDS: ' + err.getFields()
                );
            }
        }

        System.assertEquals(
            true,
            result.isSuccess(),
            'Status update failed: ' +
            (result.getErrors().isEmpty()
                ? 'Unknown error'
                : result.getErrors()[0].getMessage())
        );

        Job_Application__c updatedApp = [
            SELECT Status__c
            FROM Job_Application__c
            WHERE Id = :app.Id
        ];

        System.assertEquals(
            'Screening',
            updatedApp.Status__c,
            'Application status should be Screening.'
        );
    }
}