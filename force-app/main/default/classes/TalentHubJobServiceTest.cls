@isTest
public class TalentHubJobServiceTest {

    @testSetup
    static void createTestData() {

        // Create Job records
        List<Job__c> jobs = new List<Job__c>{
            new Job__c(
                Name = 'Salesforce Developer',
                Department__c = 'IT Department',
                Location__c = 'Hyderabad',
                Employment_Type__c = 'Full Time',
                Experience_Required__c = 3,
                Open_Date__c = Date.today(),
                Status__c = 'Open'
            ),
            new Job__c(
                Name = 'Java Developer',
                Department__c = 'IT Department',
                Location__c = 'Hyderabad',
                Employment_Type__c = 'Full Time',
                Experience_Required__c = 2,
                Open_Date__c = Date.today(),
                Status__c = 'Closed'
            )
        };

        insert jobs;

        // Create Candidate records
        List<Candidate__c> candidates = new List<Candidate__c>{
            new Candidate__c(
                First_Name__c = 'Rahul',
                Last_Name__c = 'Kumar',
                Email__c = 'rahul@test.com',
                Highest_Qualification__c = 'B.Tech',
                Total_Experience__c = 4
            ),
            new Candidate__c(
                First_Name__c = 'Arun',
                Last_Name__c = 'Kumar',
                Email__c = 'arun@test.com',
                Highest_Qualification__c = 'B.E',
                Total_Experience__c = 2
            )
        };

        insert candidates;
    }

    // Test getOpenJobs()
    @isTest
    static void testGetOpenJobs() {

        Test.startTest();

        List<Job__c> result = TalentHubJobService.getOpenJobs();

        Test.stopTest();

        System.assertEquals(
            1,
            result.size(),
            'Only open jobs should be returned.'
        );

        System.assertEquals(
            'Open',
            result[0].Status__c,
            'Returned job must have Open status.'
        );

        System.assertEquals(
            'Salesforce Developer',
            result[0].Name
        );
    }

    // Test getEligibility()
    @isTest
    static void testGetEligibility() {

        Test.startTest();

        TalentHubJobService.getEligibility();

        Test.stopTest();

        System.assertEquals(
            2,
            [SELECT COUNT() FROM Candidate__c],
            'Two candidate records should exist.'
        );
    }
}