/**
 * @description
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../../LICENSE target="_blank">MIT License</a>.
 * <br><br>
 * Class providing the trigger logic for the Binding__c object.
 * <br><br>
 * See <a href=../../triggers/README.md target="_blank">README</a> for full details of the Triggers API.
 *
 * @author Mark Brennand
 */
public with sharing class BindingTrigger {

    /**
     * Prevent re-use.
     */
    private BindingTrigger() {}

    /**
     * @description
     * Class implementing the trigger logic.
     * <br><br>
     * It is private to prevent its re-use outside this class.
     */
    private with sharing class Implementation extends TriggersV1.Event {

        /**
         * @description
         * The maximum number of times a Binding__c record trigger can fire when a DML operation is performed.
         *
         * @return 1
         */
        public Integer getMaximumRecursion() {
            return 1;
        }

        /**
         * @description
         * Return true to indicate that an exception should be thrown if an attempt is made to perform DML on
         * more Binding__c object(s) from the code called by the trigger logic.
         *
         * @return True.
         */
        public Boolean isThrowExceptionOnMaximumRecursion() {
            return true;
        }

        /**
         * @description
         * Called when Binding__c records have been inserted.
         *
         * @param records The inserted records.
         */
        public override void onAfterInsert(final List<SObject> records) {
            handle((List<Binding__c>) records);
        }

        /**
         * @description
         * Called when Binding__c records have been updated.
         *
         * @param records The inserted records.
         */
        public override void onAfterUpdate(final List<SObject> records) {
            handle((List<Binding__c>) records);
        }

        /**
         * @description
         * Check Binding__c records are valid.
         *
         * @param bindings The inserted records.
         */
        private void handle(final List<Binding__c> bindings) {
            DependencyAPI.checkForDuplicates();
            DependencyAPI.validate(bindings);
        }
    }

    /**
     * @description
     * Creates the default Binding trigger implementation.
     * <br><br>
     * The constructor for the implementation is private. This prevents the Dependency framework constructing it.
     * We use the factory to defer the construction by injection to this class, which is able to construct it.
     */
    public with sharing class Factory implements TypesV1.Factory {
        public Object newInstance() {
            return new Implementation();
        }
    }
}