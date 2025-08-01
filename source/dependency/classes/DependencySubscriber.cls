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
public with sharing class DependencySubscriber {

    /**
     * Prevent construction outside class.
     */
    @SuppressWarnings('PMD.EmptyStatementBlock')
    private DependencySubscriber() {}

    /**
     * @description
     * Class implementing the trigger logic.
     * <br><br>
     * It is private to prevent its re-use outside this class.
     */
    private with sharing class Implementation implements TriggerV1.Subscriber {

        public void onEvent(final TriggerV1.Event event) {
            if (event.isAfter()) {
                handle(event);
            }
        }

        /**
         * @description
         * Check Binding__c records are valid.
         *
         * @param event The event representing the trigger invocation.
         */
        private void handle(final TriggerV1.Event event) {
            DependencyAPI.checkForDuplicates();
            DependencyAPI.validate(event.getRecords());
            DependencyV1.reload();
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
        private Implementation subscriber = new Implementation();

        public Object newInstance() {
            return subscriber;
        }
    }
}