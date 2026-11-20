public class TalentHubApplicationNotification {

    // ==========================================
    // METHOD: Send Application Confirmation Email
    // ==========================================

    // @future allows this method to execute asynchronously
    @future
    public static void sendApplicationConfirmationEmail(

        // Constructor parameter: List of Job Application record IDs
        List<Id> applicationIds
    ) {

        // Check whether the application ID list is null or empty
        if (applicationIds == null || applicationIds.isEmpty()) {
            return;
        }

        // Retrieve Job Application records and related Candidate and Job details
        List<Job_Application__c> applications = [
            SELECT Id,
                   Candidate__c,
                   Candidate__r.First_Name__c,
                   Candidate__r.Email__c,
                   Job__r.Name
            FROM Job_Application__c
            WHERE Id IN :applicationIds
        ];

        // Create a list to store email messages before sending
        List<Messaging.SingleEmailMessage> emailList =
            new List<Messaging.SingleEmailMessage>();

        // Loop through each Job Application record
        for (Job_Application__c application : applications) {

            // Check whether Candidate information or email address is missing
            if (application.Candidate__c == null ||
                application.Candidate__r == null ||
                String.isBlank(application.Candidate__r.Email__c)) {

                System.debug('Candidate email is missing.');
                continue;
            }

            // Store the Candidate's first name in a variable
            String candidateName =
                application.Candidate__r.First_Name__c;

            // Assign a default name if the Candidate's first name is empty
            if (String.isBlank(candidateName)) {
                candidateName = 'Candidate';
            }

            // Store the Job name in a variable
            // If Job information is unavailable, use a default value
            String jobName = application.Job__r != null
                ? application.Job__r.Name
                : 'the selected job';

            // Create a new SingleEmailMessage object
            Messaging.SingleEmailMessage email =
                new Messaging.SingleEmailMessage();

            // Set the Candidate's email address as the recipient
            email.setToAddresses(
                new String[] {
                    application.Candidate__r.Email__c
                }
            );

            // Set the email subject
            email.setSubject('Job Application Confirmation');

            // Set the email body with Candidate and Job details
            email.setPlainTextBody(
                'Dear ' + candidateName + ',\n\n' +
                'Your application for the position of ' +
                jobName + ' has been successfully submitted.\n\n' +
                'Thank you for applying.\n\n' +
                'Regards,\nTalentHub Recruitment Team'
            );

            // Add the prepared email to the email list
            emailList.add(email);
        }

        // Check whether at least one email is available to send
        if (!emailList.isEmpty()) {

            // Send all prepared emails
            // false means partial success is allowed
            Messaging.SendEmailResult[] results =
                Messaging.sendEmail(emailList, false);

            // Loop through the email sending results
            for (Integer i = 0; i < results.size(); i++) {

                // Check whether the email was accepted for sending
                if (results[i].isSuccess()) {

                    System.debug('Confirmation email accepted for sending.');

                } else {

                    // Display errors if an email could not be sent
                    for (Messaging.SendEmailError err :
                         results[i].getErrors()) {

                        System.debug('EMAIL ERROR: ' + err.getMessage());
                    }
                }
            }
        }
    }
}