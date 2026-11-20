public class JobApplicationStatusTransitionHandler {

    // Define approved status transitions
    private static final Map<String, Set<String>> ALLOWED_TRANSITIONS =
        new Map<String, Set<String>>{

            'Applied' => new Set<String>{
                'Screening', 'Rejected', 'Withdrawn'
            },

            'Submitted' => new Set<String>{
                'Screening', 'Rejected', 'Withdrawn'
            },

            'Screening' => new Set<String>{
                'Shortlisted', 'Rejected', 'Withdrawn'
            },

            'Shortlisted' => new Set<String>{
                'Interview', 'Rejected', 'Withdrawn'
            },

            'Interview' => new Set<String>{
                'Technical Round', 'Rejected', 'Withdrawn'
            },

            'Technical Round' => new Set<String>{
                'HR Round', 'Rejected', 'Withdrawn'
            },

            'HR Round' => new Set<String>{
                'Selected', 'Rejected', 'Withdrawn'
            }
        };


    // Validate application status transitions
    public static void validateTransitions(
        List<Job_Application__c> newRecords,
        Map<Id, Job_Application__c> oldMap
    ) {

        // Handle empty input
        if (newRecords == null || newRecords.isEmpty() ||
            oldMap == null) {
            return;
        }

        // Process all updated applications
        for (Job_Application__c app : newRecords) {

            // Get the previous version of the record
            Job_Application__c oldApp = oldMap.get(app.Id);

            if (oldApp == null) {
                continue;
            }

            String oldStatus = oldApp.Status__c;
            String newStatus = app.Status__c;

            // No validation needed if status has not changed
            if (oldStatus == newStatus) {
                continue;
            }

            // Get allowed next statuses
            Set<String> allowedStatuses =
                ALLOWED_TRANSITIONS.get(oldStatus);

            // Skip transition validation when reactivating an application.
// Existing duplicate-application validation handles this case.
if (
    oldStatus == 'Rejected' &&
    newStatus == 'Submitted'
) {
    continue;
}

// Reject invalid transitions
if (
    allowedStatuses == null ||
    !allowedStatuses.contains(newStatus)
) {
    app.addError(
        'Invalid status transition from ' +
        oldStatus + ' to ' + newStatus + '.'
    );
}
        }
    }
}