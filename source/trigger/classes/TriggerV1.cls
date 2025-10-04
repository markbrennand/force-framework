/**
 * @description
 * <p>
 * Class defining the Trigger API available for public use.
 * <p>
 * The Subscriber interface defines the contract that implementations must provide to process events generated
 * by the Trigger API.
 * <p>
 * Each Subscriber implementation must register itself with a Trigger metadata record.
 * <p>
 * See <a href=../../source/trigger/README.md target="_blank">README</a> for full details of the Trigger API.
 * <p>
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../LICENSE target="_blank">MIT License</a>.
 *
 * @author Mark Brennand
 */
@SuppressWarnings('PMD.AvoidGlobalModifier')
global with sharing class TriggerV1 {

    /**
     * @description
     * <p>
     * The type of trigger operation that has fired.
     */
    global enum Operation { INSERTING, UPDATING, DELETING }

    /**
     * @description
     * <p>
     * Exception thrown when a trigger operation fails.
     */
    global with sharing class APIException extends ForceFwException {}

    /**
     * @description
     * <p>
     * Prevent construction.
     */
    @SuppressWarnings('PMD.EmptyStatementBlock')
    private TriggerV1() {}

    /**
     * @description
     * <p>
     * Event created by the trigger to represent the operation being performed.
     * <p>
     * The event is sent to all the Subscribers bound to the object.
     */
    global interface Event {

        /**
         * @description
         * <p>
         * Indicates whether the trigger is performing a before action.
         *
         * @return True if the trigger is performing a before action.
         */
        Boolean isBefore();

        /**
         * @description
         * <p>
         * Indicates whether the trigger is performing an after action.
         *
         * @return True if the trigger is performing an after action.
         */
        Boolean isAfter();

        /**
         * @description
         * <p>
         * Yields the trigger operation being performed.
         *
         * @return The operation being performed by the trigger.
         */
        TriggerV1.Operation getOperation();

        /**
         * @description
         * <p>
         * Yields the records passed to the trigger for processing.
         * <p>
         * Any records passed to an after trigger will have been cloned. This allows DML to be performed on them.
         *
         * @return The records the trigger is processing.
         */
        ImmutableV1.Collection getRecords();

        /**
         * @description
         * <p>
         * Checks whether given record has an old value assigned.
         *
         * @param record The record whose old value is required.
         *
         * @return True if the record has an old value.
         */
        Boolean hasOldValue(final SObject record);

        /**
         * @description
         * <p>
         * Gets the old value of a record.
         *
         * @param record The record whose old value is required.
         *
         * @return The old value of the record, or null if no old record found.
         */
        OptionalV1 getOldValue(final SObject record);

        /**
         * @description
         * <p>
         * Gets all the old values registered.
         *
         * @return All the old values.
         */
        OptionalV1 getOldValues();

        /**
         * @description
         * <p>
         * Yields the maximum recursive depth for the trigger.
         * <p>
         * The recursive depth is the number of times the trigger has been called as a result of DML performed on
         * the object associated with the trigger in trigger logic.
         * <p>
         * If the recursive depth returned is 0, no checks on the recursive depth are performed.
         *
         * @return The maximum recursive depth for the trigger.
         */
        Integer getRecursiveDepth();
    }

    /**
     * @description
     * <p>
     * Classes implementing this interface may register themselves for use of the Trigger API.
     */
    global interface Subscriber {

        /**
         * @description
         * <p>
         * Method called by the Trigger API when a trigger fires.
         * <p>
         * The event argument encapsulates all the information for the trigger operation that has fired.
         * <p>
         * All the Subscriber implementations bound to the object whose trigger hss fired will have their
         * onEvent method called.
         *
         * @param event The trigger event.
         */
        void onEvent(final TriggerV1.Event event);
    }

    /**
     * @description
     * <p>
     * Entry point for Trigger API.
     * <p>
     * This method must be called from the Apex Trigger.
     * <p>
     * An event representing the Trigger action is created and published to all the subscribers bound to the type
     * of object associated with the Apex Trigger.
     */
    global static void publish() {
        TriggerAPI.impl.publish();
    }

    /**
     * @description
     * <p>
     * Disables the subscribers for the given object type.
     *
     * @param type The object type whose subscribers are to be disabled.
     */
    global static void disable(final SObjectType type) {
        TriggerAPI.impl.disable(type);
    }
    /**
     * @description
     * <p>
     * Enables the subscribers for the given object type.
     *
     * @param type The object type whose subscribers are to be enabled.
     */
    global static void enable(final SObjectType type) {
        TriggerAPI.impl.enable(type);
    }

    /**
     * @description
     * <p>
     * Determines whether subscribers are enabled for the given object type.
     *
     * @param type The object type whose subscription status is to be checked.
     *
     * @return True if the subscribers are enabled.
     */
    global static Boolean isEnabled(final SObjectType type) {
        return TriggerAPI.impl.isEnabled(type);
    }

    /**
     * @description
     * <p>
     * Disables the given Subscriber class.
     * <p>
     * No further events will be published to the associated subscriber.
     *
     * @param type The Subscriber class to disable.
     */
    global static void disable(final Type type) {
        TriggerAPI.impl.disable(type);
    }

    /**
     * @description
     * <p>
     * Enables the given Subscriber class.
     * <p>
     * Events will be published to the associated subscriber.
     *
     * @param type The Subscriber class to enable.
     */
    global static void enable(final Type type) {
        TriggerAPI.impl.enable(type);
    }

    /**
     * @description
     * <p>
     * Determines whether the given Subscriber class is enabled.
     *
     * @param type The Subscriber class to be checked.
     *
     * @return True if the Subscriber class is enabled.
     */
    global static Boolean isEnabled(final Type type) {
        return TriggerAPI.impl.isEnabled(type);
    }

    /**
     * @description
     * <p>
     * Class providing check on Binding made to TriggerV1.Subscriber.
     */
    public with sharing class BindingCheck implements DependencyV1.BindingCheck {

        /**
         * @description
         * <p>
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