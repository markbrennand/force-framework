/**
 * @description
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../../LICENSE target="_blank">MIT License</a>.
 * <br><br>
 * Class defining trigger API.
 * <br><br>
 * The processing of a trigger is represented by the Event interface. The implementation of the interface codes
 * the logic required by the trigger.
 * <br><br>
 * See <a href=../README.md target="_blank">README</a> for full details of the Triggers API.
 *
 * @author Mark Brennand
 */
global with sharing class Triggers {

    /**
     * @description
     * Exception thrown when a trigger operation fails.
     */
    global with sharing class APIException extends Exception {}

    /**
     * @description
     * Prevent construction.
     */
    private Triggers() {}

    /**
     * @description
     * API to be provided by an Event.
     * <br><br>
     * It is recommended that the TriggersV1.Event class is used when coding a trigger rather than creating a class
     * that implements this interface.
     */
    public interface Event extends Dependency.Prototype {

        /**
         * @description
         * Called to pre-process records being inserted.
         *
         * @param records The records being inserted.
         */
        void onBeforeInsert(List<SObject> records);

        /**
         * @description
         * Called to post-process inserted records.
         *
         * @param records The records being inserted.
         */
        void onAfterInsert(List<SObject> records);

        /**
         * @description
         * Called to pre-process records being updated.
         *
         * @param records The records being inserted.
         */
        void onBeforeUpdate(List<SObject> records);

        /**
         * @description
         * Called to post-process updated records.
         *
         * @param records The records being inserted.
         */
        void onAfterUpdate(List<SObject> records);

        /**
         * @description
         * Called to pre-process records being deleted.
         *
         * @param records The records being inserted.
         */
        void onBeforeDelete(List<SObject> records);

        /**
         * @description
         * Called to post-process deleted records.
         *
         * @param records The records being inserted.
         */
        void onAfterDelete(List<SObject> records);

        /**
         * @description
         * Registers the values of records being updated or deleted before the DML operation was performed.
         *
         * @param oldRecords The old values of the records being updated or deleted.
         */
        void setOldValues(Map<Id, SObject> oldRecords);

        /**
         * @description
         * Determines if a record has an old value registered.
         *
         * @param record The record to be checked.
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

        /**
         * @description
         * When the recursive depth is reached, there are two options.
         * <br><br>
         * If this method returns true, then an APIException is thrown.
         * <br><br>
         * If this method returns false, then the trigger logic coded in the on methods is not called. The trigger
         * effectively becomes a no-op implementation.
         *
         * @return True if an Exception is to be thrown.
         */
        Boolean isThrowExceptionOnRecursiveDepthExceeded();
    }


    /**
     * @description
     * Class providing check on Binding made to AsynchronousV1.API.
     */
    public with sharing class BindingCheck implements Dependency.BindingCheck {

        /**
         * @description
         * Checks that a valid binding has been made to Triggers.Event.
         *
         * @param forType The type being bound to.
         * @param withImpl The implementation being bound.
         *
         * @return The result of the validation.
         */
        public Dependency.ValidationResult validate(Type forType, Type withImpl) {
            return DependencyHelper.buildValidationResult(
                    TypesV1.newInstance(withImpl) instanceof TriggersV1.Event,
                    true,
                    forType,
                    withImpl
            );
        }
    }
}