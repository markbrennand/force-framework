/**
 * @description
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../../LICENSE target="_blank">MIT License</a>.
 * <br><br>
 * Trigger for DML performed on Binding__c object.
 * <br><br>
 * The Trigger API is used to build and publish an Event representing the Trigger action.
 *
 * @author Mark Brennand
 */
trigger Binding on Binding__c (before insert, after insert, before update, after update) {
    TriggerV1.publish();
}