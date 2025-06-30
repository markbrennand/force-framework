/**
 * @description
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../../LICENSE target="_blank">MIT License</a>.
 * <br><br>
 * Class defining services of Trigger API.
 * <br><br>
 * The processing of a trigger is represented by the Trigger.Event interface. The implementation of the interface codes
 * the logic required by the trigger.
 * <br><br>
 * The Event implementation must be constructed by a TypesV1.Factory. By default, a factory with a classname
 * which is {objectName}Trigger.Factory is used to construct the Event. The objectName value is the name of the
 * object the trigger is for with any __c and _ s removed. For example, a trigger for the AsynchonousJob__c object,
 * would expect a TypesV1.Factory inner class named Factory to exist in the AsynchronousJobTrigger class.
 * <br><br>
 * The Event implementation can be overridden using a Binding. The binding would need to have its Type set to
 * Event and the Action would be the full name of the object the trigger is being overridden for, e.g.
 * AsynchronousJob__c.
 * <br><br>
 * It is recommended that you use the Event class in this class rather than developing your own trigger class
 * implementing the Trigger.Event interface.
 * <br><br>
 * A trigger definition must call Triggers.route() to generate and process the event for the trigger.
 * <br><br>
 * See <a href=../README.md target="_blank">README</a> for full details of the Trigger API.
 *
 * @author Mark Brennand
 */
global with sharing class TriggersV1 {
    private static final Map<SObjectType, List<Triggers.Event>> EVENTS = new Map<SObjectType, List<Triggers.Event>>();

    /**
     * @description
     * Precvent construction.
     */
    private TriggersV1() {}

    /**
     * @description
     * This method must be called from the Trigger.
     * <br><br>
     * Based on the type of object being processed, it will try to create a Trigger.Event. The logic described in the
     * class header will be used to construct the Trigger.Event. If the event can be constructed, the appropriate
     * on method will be called.
     */
    global static void route() {
        final SObjectType objectType = Trigger.isInsert
                ? Trigger.new[0].getSObjectType()
                : Trigger.old[0].getSObjectType();

        final String objectName = objectType.getDescribe().localName;
        final Event event = newEvent(objectName);

        if (EVENTS.containsKey(objectType) && !EVENTS.get(objectType).isEmpty()) {
            EVENTS.get(objectType).add(0, event);
        } else {
            EVENTS.put(objectType, new List<Event> { event });
        }

        try {
            if (hasRecursiveDepthBeenExceeded(objectType, event)) {
                return;
            } else {
                processEvent(event);
            }

        } finally {
            EVENTS.get(objectType).remove(0);
        }
    }

    global with sharing virtual class Event implements Triggers.Event {
        private Map<Id, SObject> oldRecords;

        /**
         * @description
         * Registers the values of records being updated or deleted before the DML operation was performed.
         *
         * @param oldRecords The old values of the records being updated or deleted.
         */
        public void setOldValues(Map<Id, SObject> oldRecords) {
            this.oldRecords = oldRecords == null ? new Map<Id, SObject>() : oldRecords;
        }

        /**
         * @description
         * Determines if a record has an old value registered.
         *
         * @param record The record to be checked.
         *
         * @return True if the record has an old value.
         */
        global Boolean hasOldValue(SObject record) {
            Assertion.isNotNull(record, 'Record must not be null');
            Assertion.isNotNull(record.Id, 'Record Id must not be null');
            return this.oldRecords.containsKey(record.Id);
        }

        /**
         * @description
         * Gets the old value of a record.
         *
         * @param record The record whose old value is required.
         *
         * @return The old value of the record, or null if no old record found.
         */
        global SObject getOldValue(SObject record) {
            Assertion.isNotNull(record, 'Record must not be null');
            Assertion.isNotNull(record.Id, 'Record Id must not be null');
            return oldRecords.get(record.Id);
        }

        /**
         * @description
         * Gets all the old values registered.
         *
         * @return All the old values.
         */
        global List<SObject> getOldValues() {
            return oldRecords.values();
        }

        /**
         * @description
         * Yields the maximum recursive depth for the trigger.
         * <br><br>
         * The recursive depth is the number of times the trigger has been called as a result of DML performed on
         * the object associated with the trigger in trigger logic.
         * <br><br>
         * If the recursive depth returned is 0, no checks on the recursive depth are performed.
         *
         * @return The default return value is 0.
         */
        global Integer getRecursiveDepth() {
            return 0;
        }

        /**
         * @description
         * When the recursive depth is reached, there are two options.
         * <br><br>
         * If this method returns true, then an APIException is thrown.
         * <br><br>
         * If this method returns false, then the trigger logic coded in the on methods is not called. The trigger
         * effectively becomes a no-op implementation.
         *
         * @return The default return value is false.
         */
        global Boolean isThrowExceptionOnRecursiveDepthExceeded() {
            return false;
        }

        /**
         * @description
         * Called to pre-process records being inserted.
         *
         * @param records The records being inserted.
         */
        global virtual void onBeforeInsert(List<SObject> records) {}

        /**
         * @description
         * Called to post-process inserted records.
         *
         * @param records The records being inserted.
         */
        global virtual void onAfterInsert(List<SObject> records) {}

        /**
         * @description
         * Called to pre-process records being updated.
         *
         * @param records The records being inserted.
         */
        global virtual void onBeforeUpdate(List<SObject> records) {}

        /**
         * @description
         * Called to post-process updated records.
         *
         * @param records The records being inserted.
         */
        global virtual void onAfterUpdate(List<SObject> records) {}

        /**
         * @description
         * Called to pre-process records being deleted.
         *
         * @param records The records being inserted.
         */
        global virtual void onBeforeDelete(List<SObject> records) {}

        /**
         * @description
         * Called to post-process deleted records.
         *
         * @param records The records being inserted.
         */
        global virtual void onAfterDelete(List<SObject> records) {}
    }

    /**
     * @description
     * Constructs an Event for a given object.
     * <br><br>
     * The Event implementation must be constructed by a TypesV1.Factory. By default, a factory with a classname
     * which is {objectName}Trigger.Factory is used to construct the Event. The objectName value is the name of the
     * object the trigger is for with any __c and _ s removed. For example, a trigger for the AsynchonousJob__c object,
     * would expect a TypesV1.Factory inner class named Factory to exist in the AsynchronousJobTrigger class.
     * <br><br>
     * The Event implementation can be overridden using a Binding. The binding would need to have its Type set to
     * Event and the Action would be the full name of the object the trigger is being overridden for, e.g.
     * AsynchronousJob__c.
     *
     * @param objectName The name of the object type the Event is for.
     *
     * @return The Event.
     */
    private static Event newEvent(final String objectName) {
        final Event event;

        if (DependencyV1.isBound(Event.class, objectName)) {
            event = (Event) DependencyV1.inject(Event.class, objectName);
        } else {
            final String className = objectName.replace('__c', '').replace('_', '') + 'Trigger.Factory';
            event = (Event) TypesV1.newInstance(TypesV1.load(className));
        }

        return event;
    }

    /**
     * @description
     * Calls the appropriate on method of the given Event based on the Trigger options.
     *
     * @param event The Event to process.
     */
    private static void processEvent(final Event event) {
        final Boolean isBefore = Trigger.isBefore;
        final Boolean isCreate = Trigger.isInsert;
        final Boolean isUpdate = Trigger.isUpdate;

        event.setOldValues(Trigger.oldMap);

        if (isBefore) {
            if (isCreate) {
                event.onBeforeInsert(Trigger.new);
            } else if (isUpdate) {
                event.onBeforeUpdate(Trigger.new);
            } else {
                event.onBeforeDelete(Trigger.old);
            }
        } else {
            if (isCreate) {
                event.onAfterInsert(Trigger.new);
            } else if (isUpdate) {
                event.onAfterUpdate(Trigger.new);
            } else {
                event.onAfterDelete(Trigger.old);
            }
        }
    }

    /**
     * @description
     * Determines whether the recursive depth for a trigger has been exceeded.
     * <br><br>
     * If the depth is exceeded and the Event indicates an Exception should be thrown, then one is.
     *
     * @param objectType The type of object the Event is for.
     * @param event The Event.
     *
     * @return True if the recursive depth has been exceeded.
     */
    private static Boolean hasRecursiveDepthBeenExceeded(final SObjectType objectType, final Event event) {
        final Integer maximumRecursiveCalls = event.getRecursiveDepth();
        if (maximumRecursiveCalls > 0) {
            if (EVENTS.get(objectType).size() > maximumRecursiveCalls) {
                if (event.isThrowExceptionOnRecursiveDepthExceeded() == true) {
                    throw new Triggers.APIException('Maximum recursive calls exceeded for ' + objectType.getDescribe().localName + ' trigger');
                } else {
                    return true;
                }
            }
        }

        return false;
    }
}