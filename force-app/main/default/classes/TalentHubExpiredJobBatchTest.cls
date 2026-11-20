@isTest
private class TalentHubExpiredJobBatchTest {

    // Returns the first active picklist value (avoids restricted picklist errors)
    private static String pick(Schema.SObjectField field, String fallback) {
        for (Schema.PicklistEntry pe : field.getDescribe().getPicklistValues()) {
            if (pe.isActive()) {
                return pe.getValue();
            }
        }
        return fallback;
    }

    // Job Title is the standard Name field
    private static Job__c makeJob(String title, String status, Date closeDate) {
        return new Job__c(
            Name                   = title,
            Department__c          = pick(Job__c.Department__c, 'Engineering'),
            Location__c            = 'Hyderabad',
            Employment_Type__c     = pick(Job__c.Employment_Type__c, 'Full-Time'),
            Experience_Required__c = 2,
            Open_Date__c           = Date.today(),
            Status__c              = status,
            Close_Date__c          = closeDate
        );
    }

    // Returns the current status of the job with this title.
    // If the job is missing, the message shows which titles do exist.
    private static String statusOf(String title) {
        Map<String, Job__c> byTitle = new Map<String, Job__c>();
        for (Job__c j : [SELECT Id, Name, Status__c FROM Job__c]) {
            byTitle.put(j.Name, j);
        }
        System.assert(byTitle.containsKey(title),
            'No job titled "' + title + '". Titles found: ' + byTitle.keySet());
        return byTitle.get(title).Status__c;
    }

    // All Close Dates are valid (today or later), so the validation rules pass.
    // The tests run the batch with a cutoff of today + 10, so jobs closing
    // before that date count as expired.
    @TestSetup
    static void setup() {
        insert new List<Job__c>{
            makeJob('Expired Open',     'Open',   Date.today().addDays(1)),   // before cutoff: should close
            makeJob('Expired Open 2',   'Open',   Date.today().addDays(3)),   // before cutoff: should close
            makeJob('Future Open',      'Open',   Date.today().addDays(20)),  // after cutoff: stays Open
            makeJob('Closes On Cutoff', 'Open',   Date.today().addDays(10)),  // equal to cutoff: stays Open
            makeJob('Already Closed',   'Closed', Date.today().addDays(2))    // not Open: stays Closed
        };
    }

    @isTest
    static void testExpiredOpenJobsAreClosed() {
        Test.startTest();
        Database.executeBatch(new TalentHubExpiredJobBatch(Date.today().addDays(10)), 200);
        Test.stopTest(); // the batch runs here

        System.assertEquals('Closed', statusOf('Expired Open'));
        System.assertEquals('Closed', statusOf('Expired Open 2'));
    }

    @isTest
    static void testNonExpiredJobsAreNotChanged() {
        Test.startTest();
        Database.executeBatch(new TalentHubExpiredJobBatch(Date.today().addDays(10)), 200);
        Test.stopTest();

        System.assertEquals('Open',   statusOf('Future Open'));
        System.assertEquals('Open',   statusOf('Closes On Cutoff'));
        System.assertEquals('Closed', statusOf('Already Closed'));
    }

    // Default constructor uses today's date: no job has a Close Date before
    // today, so nothing should change
    @isTest
    static void testDefaultConstructorChangesNothing() {
        Test.startTest();
        Database.executeBatch(new TalentHubExpiredJobBatch(), 200);
        Test.stopTest();

        System.assertEquals(4,
            [SELECT COUNT() FROM Job__c WHERE Status__c = 'Open']);
        System.assertEquals(1,
            [SELECT COUNT() FROM Job__c WHERE Status__c = 'Closed']);
    }
}