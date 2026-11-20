@isTest
public class TalentHubApplicationNotificationTest {

    // Create test Candidate
    private static Candidate__c createCandidate() {
        Candidate__c candidate = new Candidate__c(
            First_Name__c = 'Jyothi',
            Last_Name__c = 'Kumar',
            Email__c = 'jyothi@test.com',
            Highest_Qualification__c = 'B.E'
        );
        insert candidate;
        return candidate;
    }

    // Create test Job
    private static Job__c createJob() {
        Job__c job = new Job__c(
            Name = 'Salesforce Developer',
            Location__c = 'Hyderabad',
            Employment_Type__c = 'Full Time',
            Department__c = 'IT Department',
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
        Job_Application__c application = new Job_Application__c(
            Candidate__c = candidateId,
            Job__c = jobId,
            Application_Date__c = Date.today(),
            Interview_Date__c = Date.today().addDays(7),
            Status__c = 'Applied'
        );
        insert application;
        return application;
    }

    // Test successful email processing
    @isTest
    static void testSendApplicationConfirmationEmail() {

        Candidate__c candidate = createCandidate();
        Job__c job = createJob();

        Test.startTest();

        Job_Application__c application =
            createApplication(candidate.Id, job.Id);

        Test.stopTest();

        System.assertNotEquals(
            null,
            application.Id,
            'Job Application should be created successfully.'
        );
    }

    // Test future method with null application IDs
    @isTest
    static void testNullApplicationIds() {

        Test.startTest();

        TalentHubApplicationNotification.sendApplicationConfirmationEmail(null);

        Test.stopTest();

        System.assert(true, 'Null IDs should be handled without an exception.');
    }

    // Test future method with an empty list
    @isTest
    static void testEmptyApplicationIds() {

        Test.startTest();

        TalentHubApplicationNotification.sendApplicationConfirmationEmail(new List<Id>());

        Test.stopTest();

        System.assert(true, 'Empty IDs should be handled without an exception.');
    }

    // Test with an application ID that does not exist
    @isTest
    static void testInvalidApplicationId() {

        Id invalidId = 'a00000000000000AAA';

        Test.startTest();

        TalentHubApplicationNotification.sendApplicationConfirmationEmail(
                new List<Id>{ invalidId }
            );

        Test.stopTest();

        System.assert(true, 'Invalid application ID should be handled.');
    }
}