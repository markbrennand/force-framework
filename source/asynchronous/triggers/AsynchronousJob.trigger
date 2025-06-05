/**
 * @description
 * @author Mark Brennand
 */
trigger AsynchronousJob on AsynchronousJob__c (before insert, before update, after insert, after update) {
    if (Trigger.isBefore) {
        AsynchronousImpl.onTriggerBefore((List<AsynchronousJob__c>) Trigger.new);
    } else {
        AsynchronousImpl.onTriggerAfter((List<AsynchronousJob__c>) Trigger.new, (Map<Id, AsynchronousJob__c>) Trigger.oldMap);
    }
}