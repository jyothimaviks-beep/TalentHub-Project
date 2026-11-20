trigger JobTrigger on Job__c (before insert, before update) {

    if (Trigger.isBefore && Trigger.isInsert) {

        JobTriggerHandler.beforeInsert(Trigger.new);

    }

    if (Trigger.isBefore && Trigger.isUpdate) {

        JobTriggerHandler.beforeUpdate(Trigger.new);

    }

}