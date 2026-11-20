public class TalentHubJobService {
     public static List<Job__c> getOpenJobs() {
                List<Job__c> openJobs = [SELECT Id, Name, Department__c, Location__c, Status__c FROM Job__c WHERE Status__c = 'Open'];
                return openJobs;
    }
    
    public static void getEligibility(){
        List<Candidate__c> candidates = [SELECT Id, Name, Total_Experience__c FROM Candidate__c];
        for(Candidate__c can : candidates){
             if (can.Total_Experience__c >=3){
                system.debug(can.Name +' '+'is'+' Eligible');
             }else{
                system.debug(can.Name +' '+'is'+' '+'Not Eligible');
                    }
            }
	}
    
}