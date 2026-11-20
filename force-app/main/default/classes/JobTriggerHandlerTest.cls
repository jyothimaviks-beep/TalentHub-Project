@isTest
public class JobTriggerHandlerTest {

    // Common method to create Job test records
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

    // TEST 1: Successful Job Insert
    @isTest
    static void testValidJobInsert() {

        Job__c job = createJob('Salesforce Developer');

        Test.startTest();
        insert job;
        Test.stopTest();

        Job__c insertedJob = [
            SELECT Id, Name, Open_Date__c
            FROM Job__c
            WHERE Id = :job.Id
        ];

        System.assertNotEquals(null, insertedJob.Id);
        System.assertEquals(Date.today(), insertedJob.Open_Date__c);
    }

    // TEST 2: Invalid Job Insert - Past Date
    @isTest
    static void testInvalidJobInsert() {

        Job__c job = createJob('Java Developer');
        job.Open_Date__c = Date.today().addDays(-1);

        Test.startTest();

        Database.SaveResult result = Database.insert(job, false);

        Test.stopTest();

        System.assertEquals(false, result.isSuccess());
        System.assert(
            result.getErrors()[0].getMessage().contains(
                'Open Date cannot be earlier than today.'
            )
        );
    }

    // TEST 3: Successful Job Update
    @isTest
    static void testValidJobUpdate() {

        Job__c job = createJob('Python Developer');
        insert job;

        job.Open_Date__c = Date.today().addDays(5);

        Test.startTest();

        update job;

        Test.stopTest();

        Job__c updatedJob = [
            SELECT Open_Date__c
            FROM Job__c
            WHERE Id = :job.Id
        ];

        System.assertEquals(
            Date.today().addDays(5),
            updatedJob.Open_Date__c
        );
    }

    // TEST 4: Invalid Job Update - Past Date
    @isTest
    static void testInvalidJobUpdate() {

        Job__c job = createJob('Apex Developer');
        insert job;

        job.Open_Date__c = Date.today().addDays(-2);

        Test.startTest();

        Database.SaveResult result = Database.update(job, false);

        Test.stopTest();

        System.assertEquals(false, result.isSuccess());

        System.assert(
            result.getErrors()[0].getMessage().contains(
                'Open Date cannot be earlier than today.'
            )
        );
    }

    // TEST 5: Bulk Job Insert
    @isTest
    static void testBulkJobInsert() {

        List<Job__c> jobs = new List<Job__c>();

        for (Integer i = 1; i <= 10; i++) {

            jobs.add(createJob('Developer ' + i));
        }

        Test.startTest();

        insert jobs;

        Test.stopTest();

        System.assertEquals(
            10,
            [SELECT COUNT() FROM Job__c WHERE Name LIKE 'Developer %']
        );
    }

    // TEST 6: Bulk Job Update
    @isTest
    static void testBulkJobUpdate() {

        List<Job__c> jobs = new List<Job__c>();

        for (Integer i = 1; i <= 10; i++) {

            jobs.add(createJob('Tester ' + i));
        }

        insert jobs;

        for (Job__c job : jobs) {

            job.Open_Date__c = Date.today().addDays(10);
        }

        Test.startTest();

        update jobs;

        Test.stopTest();

        List<Job__c> updatedJobs = [
            SELECT Id, Open_Date__c
            FROM Job__c
            WHERE Name LIKE 'Tester %'
        ];

        System.assertEquals(10, updatedJobs.size());

        for (Job__c job : updatedJobs) {

            System.assertEquals(
                Date.today().addDays(10),
                job.Open_Date__c
            );
        }
    }
}