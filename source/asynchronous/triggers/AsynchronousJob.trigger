/**
 * @description
 * @author Mark Brennand
 */
trigger AsynchronousJob on AsynchronousJob__c (before insert, before update, after insert, after update) {
    if (Trigger.isBefore) {
        Asynchronous.onTriggerBefore((List<AsynchronousJob__c>) Trigger.new);
    } else {
        Asynchronous.onTriggerAfter((List<AsynchronousJob__c>) Trigger.new, (Map<Id, AsynchronousJob__c>) Trigger.oldMap);
    }
}