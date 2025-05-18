/**
 * @description
 * @author Mark Brennand
 */

trigger Asynchronous on Asynchronous__c (before insert, before update, after update) {
    if (Trigger.isBefore) {
        Asynchronous.onTriggerBefore((List<Asynchronous__c>) Trigger.new);
    } else {
        Asynchronous.onTriggerAfter((List<Asynchronous__c>) Trigger.new, (Map<Id, Asynchronous__c>) Trigger.oldMap);
    }
}