/**
 * @description
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../../LICENSE target="_blank">MIT License</a>.
 * <br><br>
 * Trigger for DML performed on Binding__c object.
 *
 * @author Mark Brennand
 */
trigger Binding on Binding__c (after insert, after update) {
    TriggersV1.route();
}