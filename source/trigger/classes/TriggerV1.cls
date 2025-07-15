/**
 * @description
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../../LICENSE target="_blank">MIT License</a>.
 * <br><br>
 * Class defining the Trigger API available for public use.
 * <br><br>
 * The Subscriber interface defines the contract that implementations must provide to process events generated
 * by the Trigger API.
 * <br><br>
 * Each Subscriber implementation must register itself with a Trigger metadata record.
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
        Boolean hasOldValue(final SObject record);

        /**
         * @description
         * Gets the old value of a record.
         *
         * @param record The record whose old value is required.
         *
         * @return The old value of the record, or null if no old record found.
         */
        SObject getOldValue(final SObject record);

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
        void onEvent(final Event event);
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
     * Disables the subscribers for the given object type.
     *
     * @param type The object type whose subscribers are to be disabled.
     */
    global static void disable(final SObjectType type) {
        TriggerAPI.API.disable(type);
    }
    /**
     * @description
     * Enables the subscribers for the given object type.
     *
     * @param type The object type whose subscribers are to be enabled.
     */
    global static void enable(final SObjectType type) {
        TriggerAPI.API.enable(type);
    }

    /**
     * @description
     * Determines whether subscribers are enabled for the given object type.
     *
     * @param type The object type whose subscription status is to be checked.
     *
     * @return True if the subscribers are enabled.
     */
    global static Boolean isEnabled(final SObjectType type) {
        return TriggerAPI.API.isEnabled(type);
    }

    /**
     * @description
     * Disables the given Subscriber class.
     * <br><br>
     * No further events will be published to the associated subscriber.
     *
     * @param type The Subscriber class to disable.
     */
    global static void disable(final Type type) {
        TriggerAPI.API.disable(type);
    }

    /**
     * @description
     * Enables the given Subscriber class.
     * <br><br>
     * Events will be published to the associated subscriber.
     *
     * @param type The Subscriber class to enable.
     */
    global static void enable(final Type type) {
        TriggerAPI.API.enable(type);
    }

    /**
     * @description
     * Determines whether the given Subscriber class is enabled.
     *
     * @param type The Subscriber class to be checked.
     *
     * @return True if the Subscriber class is enabled.
     */
    global static Boolean isEnabled(final Type type) {
        return TriggerAPI.API.isEnabled(type);
    }

    /**
     * @description
     * Class providing check on Binding made to TriggerV1.Subscriber.
     */
    public with sharing class BindingCheck implements DependencyV1.BindingCheck {

        /**
         * @description
         * Checks that a valid binding has been made to TriggerV1.Subscriber.
         *
         * @param forType The type being bound to, TriggerV1.Subscriber.
         * @param withImpl The implementation being bound to TriggerV1.Subscriber.
         *
         * @return The result of the validation.
         */
        public DependencyV1.ValidationResult validate(final Type forType, final Type withImpl) {
            return DependencyHelper.buildValidationResult(
                    TypesV1.newInstance(withImpl) instanceof Subscriber,
                    true,
                    forType,
                    withImpl
            );
        }
    }
}