/**
 * Test class for TalentHubApplicationStatusQueueable.
 *
 * Verifies that:
 *  - Applications with status 'Applied' are moved to 'Screening'
 *  - Applications that are 'Selected' or 'Rejected' are left unchanged
 *  - Passing an empty set of IDs does nothing
 */
@isTest
private class TalentHubApplicationStatusQueueableTest {

    /**
     * Helper: returns the first active value of a picklist field.
     * This avoids hardcoding values that may not exist in the org
     * (restricted picklists reject any value that isn't defined).
     * If the field has no active values (e.g. it's not a picklist),
     * the fallback string is returned instead.
     */
    private static String pick(Schema.SObjectField field, String fallback) {
        for (Schema.PicklistEntry pe : field.getDescribe().getPicklistValues()) {
            if (pe.isActive()) {
                return pe.getValue();
            }
        }
        return fallback;
    }

    /**
     * Runs once before the test methods. Records created here are
     * available to every test method, and each test gets a fresh copy
     * (changes made in one test are rolled back before the next).
     */
    @TestSetup
    static void setup() {
        // 1. Parent record: Candidate (looked up by Job Application)
        Candidate__c candidate = new Candidate__c(
            First_Name__c            = 'Jyothi',
            Last_Name__c             = 'Kumar',
            Email__c                 = 'jyothi@test.com',
            Highest_Qualification__c = 'B.E'
        );
        insert candidate;

        // 2. Parent record: Job (also looked up by Job Application).
        //    Picklist fields use pick() so valid org values are used.
        //    Name is an auto-number, so it is not set here.
        Job__c job = new Job__c(
            Name                   = 'Salesforce Developer',
            Department__c          = pick(Job__c.Department__c, 'Engineering'),
            Location__c            = 'Hyderabad',
            Employment_Type__c     = pick(Job__c.Employment_Type__c, 'Full-Time'),
            Experience_Required__c = 2,
            Open_Date__c           = Date.today(),
            Status__c              = pick(Job__c.Status__c, 'Open')
        );
        insert job;

        // 3. Job Applications covering each scenario:
        //    2 x Applied (should change), 1 x Selected and 1 x Rejected (should not)
        List<Job_Application__c> apps = new List<Job_Application__c>();
        for (String status : new List<String>{'Applied', 'Applied', 'Selected', 'Rejected'}) {
            Job_Application__c app = new Job_Application__c(
                Candidate__c        = candidate.Id,
                Job__c              = job.Id,
                Application_Date__c = Date.today(),
                Interview_Date__c   = Date.today().addDays(7),
                Status__c           = status
            );

            // A validation rule requires a reason whenever status is Rejected
            if (status == 'Rejected') {
                app.Rejection_Reason__c = pick(Job_Application__c.Rejection_Reason__c, 'Not a good fit');
            }
            apps.add(app);
        }
        insert apps; // single bulk insert (one DML statement)
    }

    /**
     * Main scenario: enqueue the job with all application IDs and check
     * that only 'Applied' records were moved to 'Screening'.
     */
    @isTest
    static void testAppliedMovesToScreening() {
        // Collect the IDs of all four test applications
        Map<Id, Job_Application__c> all = new Map<Id, Job_Application__c>(
            [SELECT Id FROM Job_Application__c]);

        // Test.startTest()/stopTest() makes the asynchronous Queueable run
        // synchronously when stopTest() is called, so results can be asserted
        Test.startTest();
        System.enqueueJob(new TalentHubApplicationStatusQueueable(all.keySet()));
        Test.stopTest();

        // Both 'Applied' records should now be 'Screening'
        System.assertEquals(2,
            [SELECT COUNT() FROM Job_Application__c WHERE Status__c = 'Screening'],
            'Applied records should move to Screening');

        // 'Selected' and 'Rejected' records must be untouched
        System.assertEquals(1,
            [SELECT COUNT() FROM Job_Application__c WHERE Status__c = 'Selected'],
            'Selected records should not change');
        System.assertEquals(1,
            [SELECT COUNT() FROM Job_Application__c WHERE Status__c = 'Rejected'],
            'Rejected records should not change');

        // Nothing should still be 'Applied'
        System.assertEquals(0,
            [SELECT COUNT() FROM Job_Application__c WHERE Status__c = 'Applied'],
            'No Applied records should remain');
    }

    /**
     * Edge case: an empty set of IDs should exit early and change nothing.
     */
    @isTest
    static void testEmptyInputDoesNothing() {
        Test.startTest();
        System.enqueueJob(new TalentHubApplicationStatusQueueable(new Set<Id>()));
        Test.stopTest();

        // The two 'Applied' records from @TestSetup should be unchanged
        System.assertEquals(2,
            [SELECT COUNT() FROM Job_Application__c WHERE Status__c = 'Applied'],
            'Applied records should be untouched when no IDs are passed');
    }
}