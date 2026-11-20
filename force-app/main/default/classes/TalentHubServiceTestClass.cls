@IsTest
private class TalentHubServiceTestClass {
    @IsTest
    static void getOpenJobs(){
        Job__c Jobe= new Job__c(
            Name = 'Saroja',
            Department__c = 'IT Department',
            Location__c = 'Hyderabad',
            Status__c = 'Open'
        );
        insert Jobe;
        Test.startTest();
        TalentHubJobService.getOpenJobs();
        Test.stopTest();
    }
}