/**
 * @description
 * @author Mark Brennand
 */

trigger Asynchronous on Asynchronous__c (before insert, before update) {
    Asynchronous.isRunnable((List<Asynchronous__c>) Trigger.new);
}