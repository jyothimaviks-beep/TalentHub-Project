trigger JobApplicationTrigger on Job_Application__c (
    before insert,
    before update,
    after insert
) {

    // BEFORE INSERT
    if (Trigger.isBefore && Trigger.isInsert) {

        JobApplicationTriggerHandler.beforeInsert(
            Trigger.new
        );
    }

    // BEFORE UPDATE
    if (Trigger.isBefore && Trigger.isUpdate) {

        JobApplicationTriggerHandler.beforeUpdate(
            Trigger.new,
            Trigger.oldMap
        );
    }

    // AFTER INSERT
    if (Trigger.isAfter && Trigger.isInsert) {

        JobApplicationAfterInsertHandler.afterInsert(
            Trigger.new
        );
    }
}