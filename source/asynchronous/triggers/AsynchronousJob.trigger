/**
 * @description
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../../LICENSE target="_blank">MIT License</a>.
 * <br><br>
 * Trigger for DML performed on AsynchronousJob__c object.
 *
 * @author Mark Brennand
 */
trigger AsynchronousJob on AsynchronousJob__c (before insert, before update, after insert, after update) {
    TriggersV1.route();
}
