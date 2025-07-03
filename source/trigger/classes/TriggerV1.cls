/**
 * @description
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../../LICENSE target="_blank">MIT License</a>.
 * <br><br>
 * Class defining the Trigger API available for public use.
 * <br><br>
 * The Subscriber interface defines the contract that implementations must provide to process events generated
 * by the Trigger API.
 * <br><br>
 * Each Subscriber class must register itself with a Trigger metadata record.
 * <br><br>
 * See <a href=../README.md target="_blank">README</a> for full details of the Trigger API.
 *
 * @author Mark Brennand
 */
global with sharing class TriggerV1 {

    /**
     * @description
     * The type of trigger operation that has fired.
     */
    global enum Operation { INSERTING, UPDATING, DELETING }

    /**
     * @description
     * Exception thrown when a trigger operation fails.
     */
    global with sharing class APIException extends Exception {}

    /**
     * @description
     * Prevent construction.
     */
    private TriggerV1() {}

    /**
     * @description
     * Classes implementing this interface may register themselves for use of the Trigger API.
     */
    global interface Subscriber {

        /**
         * @description
         * Method called by the Trigger API when a trigger fires.
         * <br><br>
         * The event argument encapsulates all the information for the trigger operation that has fired.
         * <br><br>
         * All the Subscriber implementations bound to the object whose trigger hss fired will have their
         * onEvent method called.
         *
         * @param event The trigger event.
         */
        void onEvent(Event event);

        /**
         * @description
         * Returns the operations the subscriber will accept.
         *
         * @return The operations.
         */
        Set<Operation> forOperations();
    }

    /**
     * @description
     * Event created by the trigger to represent the operation being performed.
     * <br><br>
     * The event is sent to all the Subscribers bound to the object.
     */
    global interface Event {

        /**
         * @description
         * Indicates whether the trigger is performing a before action.
         *
         * @return True if the trigger is performing a before action.
         */
        Boolean isBefore();

        /**
         * @description
         * Indicates whether the trigger is performing an after action.
         *
         * @return True if the trigger is performing an after action.
         */
        Boolean isAfter();

        /**
         * @description
         * Yields the trigger operation being performed.
         *
         * @return The operation being performed by the trigger.
         */
        Operation getOperation();

        /**
         * @description
         * Yields the records passed to the trigger for processing.
         * <br><br>
         * Any records passed to an after trigger will have been cloned. This allows DML to be performed on them.
         *
         * @return The records the trigger is processing.
         */
        List<SObject> getRecords();

        /**
         * @description
         * Checks whether given record has an old value assigned.
         *
         * @param record The record whose old value is required.
         *
         * @return True if the record has an old value.
         */
        Boolean hasOldValue(SObject record);

        /**
         * @description
         * Gets the old value of a record.
         *
         * @param record The record whose old value is required.
         *
         * @return The old value of the record, or null if no old record found.
         */
        SObject getOldValue(SObject record);

        /**
         * @description
         * Gets all the old values registered.
         *
         * @return All the old values.
         */
        List<SObject> getOldValues();

        /**
         * @description
         * Yields the maximum recursive depth for the trigger.
         * <br><br>
         * The recursive depth is the number of times the trigger has been called as a result of DML performed on
         * the object associated with the trigger in trigger logic.
         * <br><br>
         * If the recursive depth returned is 0, no checks on the recursive depth are performed.
         *
         * @return The maximum recursive depth for the trigger.
         */
        Integer getRecursiveDepth();
    }

    /**
     * @description
     * Entry point for Trigger API.
     * <br><br>
     * This method must be called from the Apex Trigger.
     * <br><br>
     * An event representing the Trigger action is created and published to all the subscribers bound to the type
     * of object associated with the Apex Trigger.
     */
    global static void publish() {
        TriggerAPI.API.publish();
    }

    /**
     * @description
     * Definition a subscriber may use to indicate that it wishes to subscribe to all the trigger operations.
     */
    global static final Set<Operation> ALL_OPERATIONS = new Set<Operation> {
            Operation.INSERTING,
            Operation.UPDATING,
            Operation.DELETING
    };
}