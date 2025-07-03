/**
 * @description
 * Class providing the Triggers API.
 * <br><br>
 * This class will generate an Event representing the trigger that fired and send it to all subscribers bound to
 * the event.
 *
 * @author Mark Brennand
 */
public with sharing virtual class TriggerAPI implements API {

    /**
     * @description
     * Active API instance.
     * <br><br>
     * The instance is injected from the Registry.
     * <br><br>
     * The instance is test visible so it can be mocked.
     */
    @TestVisible
    public static API API {
        public get {
            if (Test.isRunningTest() && API != null) { // API has been mocked.
                return API;
            } else {
                return (API) DependencyV1.inject(API.class);
            }
        }
        private set;
    }

    /**
     * @description
     * Action to be taken as a result of the check on the recursive depth.
     */
    private enum RecursiveDepthAction { PROCESS_EVENT, THROW_EXCEPTION, IGNORE_EVENT }

    /**
     * @description
     * The API for trigger processing.
     * <br><br>
     * The Trigger API will publish an Event representing the detail of the trigger. The Event will be consumed by
     * all the subscribers bound to the object type of the trigger that fired.
     */
    public interface API {

        /**
         * @description
         * This method must create an Event representing the trigger being fired and send it to all the subscribers
         * bound to the object type of the trigger that fired.
         */
        void publish();
    }

    /**
     * @description
     * Allow extension but not construction.
     * <br><br>
     * This is also required to support the Apex mocking classes. A private constructor cannot be mocked.
     */
    protected TriggerAPI() {}

    private with sharing class Implementation implements API {

        /**
         * @description
         * Cache of all the trigger definitions held in the custom metadata.
         */
        private final Map<String, List<Trigger__mdt>> TRIGGER_DEFINITIONS {
            private get {
                if (TRIGGER_DEFINITIONS == null) {
                    TRIGGER_DEFINITIONS = loadTriggerDefinitions();
                }
                return TRIGGER_DEFINITIONS;
            }
            private set;
        }

        /**
         * @description
         * Record of all the active events for each object type.
         */
        private final Map<String, List<TriggerV1.Event>> EVENTS = new Map<String, List<TriggerV1.Event>>();

        /**
         * @description
         * Cache of the Subscriber implementation for each object type.
         */
        private final Map<String, TriggerV1.Subscriber> SUBSCRIBERS = new Map<String, TriggerV1.Subscriber>();

        public void publish() {
            final SObjectType objectType = Trigger.isInsert
                    ? Trigger.new[0].getSObjectType()
                    : Trigger.old[0].getSObjectType();

            publishEvent(objectType);
        }

        private void publishEvent(final SObjectType objectType) {
            final String key = getObjectKey(objectType.getDescribe().name);

            if (TRIGGER_DEFINITIONS.containsKey(key)) {
                final TriggerV1.Event event = createEvent(key);

                if (EVENTS.containsKey(key) && !EVENTS.get(key).isEmpty()) {
                    EVENTS.get(key).add(0, event);
                } else {
                    EVENTS.put(key, new List<TriggerV1.Event>{
                            event
                    });
                }

                try {
                    for (Trigger__mdt triggerDefinition : TRIGGER_DEFINITIONS.get(key)) {
                        if (triggerDefinition.IsUnitTest__c != Test.isRunningTest()) {
                            continue;
                        }

                        switch on checkRecursiveDepth(key, triggerDefinition) {
                            when THROW_EXCEPTION {
                                throw new TriggerV1.APIException('Maximum recursive calls exceeded for ' + key + ' event');
                            }
                            when IGNORE_EVENT {
                                return;
                            }
                            when PROCESS_EVENT {
                                processEvent(triggerDefinition, event);
                            }
                        }
                    }

                } finally {
                    EVENTS.get(key).remove(0);
                }

            } else {
                throw new TriggerV1.APIException('No Trigger metadata record found for ' + key);
            }
        }

        private String getObjectKey(final String name) {
            return name.replace('__c', '').replaceFirst('^.*__', '');
        }

        private RecursiveDepthAction checkRecursiveDepth(final String key, final Trigger__mdt triggerDefinition) {
            final Integer maximumRecursiveCalls = (Integer) triggerDefinition.MaximumRecursiveDepth__c;
            if (maximumRecursiveCalls > 0) {
                if (EVENTS.get(key).size() > maximumRecursiveCalls) {
                    if (triggerDefinition.ThrowExceptionWhenRecursionExceeded__c) {
                        return RecursiveDepthAction.THROW_EXCEPTION;
                    } else {
                        return RecursiveDepthAction.IGNORE_EVENT;
                    }
                }
            }

            return RecursiveDepthAction.PROCESS_EVENT;
        }


        /**
         * @description
         * Calls the appropriate on method of the given Event based on the Trigger options.
         *
         * @param triggerDefinition The Trigger metadata record registered to process event.
         * @param event The Event to process.
         */
        private void processEvent(final Trigger__mdt triggerDefinition, final TriggerV1.Event event) {
            final String subscriberClass = triggerDefinition.SubscriberClass__c;
            final TriggerV1.Subscriber subscriber;
            if (SUBSCRIBERS.containsKey(subscriberClass)) {
                subscriber = SUBSCRIBERS.get(subscriberClass);
            } else {
                subscriber =
                        (TriggerV1.Subscriber) TypesV1.newInstance(TypesV1.load(triggerDefinition.SubscriberClass__c));

                SUBSCRIBERS.put(subscriberClass, subscriber);
            }

            final Set<TriggerV1.Operation> forOperations = subscriber.forOperations();

            if (Trigger.isInsert && forOperations.contains(TriggerV1.Operation.INSERTING)) {
                subscriber.onEvent(event);
            } else if (Trigger.isUpdate && forOperations.contains(TriggerV1.Operation.UPDATING)) {
                subscriber.onEvent(event);
            } else if (Trigger.isDelete && forOperations.contains(TriggerV1.Operation.DELETING)) {
                subscriber.onEvent(event);
            }
        }

        private TriggerV1.Event createEvent(String key) {
            final Boolean isBefore = Trigger.isBefore;

            final TriggerV1.Operation operation =
                    Trigger.isInsert ? TriggerV1.Operation.INSERTING
                            : Trigger.isUpdate ? TriggerV1.Operation.UPDATING : TriggerV1.Operation.DELETING;

            final List<SObject> records = Trigger.isDelete ? Trigger.old : Trigger.new;

            return new Event(
                    records,
                    Trigger.isInsert ? new Map<Id, SObject>() : Trigger.oldMap,
                    isBefore,
                    operation,
                    EVENTS.containsKey(key) ? EVENTS.get(key).size() + 1 : 1
            );
        }

        private Map<String, List<Trigger__mdt>> loadTriggerDefinitions() {
            final Map<String, List<Trigger__mdt>> triggerDefinitions = new Map<String, List<Trigger__mdt>>();

            for (Trigger__mdt triggerDefinition : Trigger__mdt.getAll().values()) {
                final String objectName = triggerDefinition.ObjectKey__c;
                if (triggerDefinitions.containsKey(objectName)) {
                    triggerDefinitions.get(objectName).add(triggerDefinition);
                } else {
                    triggerDefinitions.put(objectName, new List<Trigger__mdt> { triggerDefinition });
                }
            }

            return triggerDefinitions;
        }
    }

    /**
     * @description
     * Implementation of the Event interface.
     */
    private with sharing class Event implements TriggerV1.Event {
        final List<SObject> records;
        private final Map<Id, SObject> oldRecords;
        private final Boolean isBefore;
        private final TriggerV1.Operation operation;
        private final Integer recursiveDepth;

        public Event(
                final List<SObject> records,
                final Map<Id, SObject> oldRecords,
                final Boolean isBefore,
                final TriggerV1.Operation operation,
                final Integer recursiveDepth
        ) {
            this.records =  records;
            this.oldRecords = oldRecords;
            this.isBefore = isBefore;
            this.operation  = operation;
            this.recursiveDepth = recursiveDepth;
        }

        public Boolean isBefore() {
            return isBefore;
        }

        public Boolean isAfter() {
            return !isBefore();
        }

        public TriggerV1.Operation getOperation() {
            return operation;
        }

        public List<SObject> getRecords() {
            return records;
        }

        /**
         * @description
         * Determines if a record has an old value registered.
         *
         * @param record The record to be checked.
         *
         * @return True if the record has an old value.
         */
        public Boolean hasOldValue(SObject record) {
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
        public SObject getOldValue(SObject record) {
            return oldRecords.get(record.Id);
        }

        /**
         * @description
         * Gets all the old values registered.
         *
         * @return All the old values.
         */
        public List<SObject> getOldValues() {
            return oldRecords.values();
        }

        /**
         * @description
         * Yields the currentg recursive depth of the trigger.
         * <br><br>
         * The recursive depth is the number of times the trigger has been called as a result of DML performed on
         * the object associated with the trigger in trigger logic.
         *
         * @return The recursive depth.
         */
        public Integer getRecursiveDepth() {
            return recursiveDepth;
        }
    }

    /**
     * @description
     * Creates the default API implementation.
     * <br><br>
     * The constructor for the implementation is protected. This prevents the Dependency framework constructing it.
     * We use the factory to defer the construction by injection to this class, which is able to construct it.
     */
    public with sharing class Factory implements TypesV1.Factory {
        public Object newInstance() {
            return new Implementation();
        }
    }

    /**
     * @description
     * Class providing check on Binding made to TriggersAPIg.API.
     */
    public with sharing class BindingCheck implements DependencyV1.BindingCheck {

        /**
         * @description
         * Checks that a valid binding has been made to TriggersAPI.API.
         *
         * @param forType The type being bound to, AsynchronousV1.API.
         * @param withImpl The implementation being bound to AsynchronousV1.API.
         *
         * @return The result of the validation.
         */
        public DependencyV1.ValidationResult validate(Type forType, Type withImpl) {
            return DependencyHelper.buildValidationResult(
                    TypesV1.newInstance(withImpl) instanceof API,
                    true,
                    forType,
                    withImpl
            );
        }
    }

    /**
     * @description
     * Method is solely for mocking use.
     */
    public void publish() {
        throw new TriggerV1.APIException('Access denied');
    }

    // Set the default implementation of API. This can be overridden using a Dependency Injection Binding.
    static {
        DependencyV1.bind(API.class, Factory.class);
    }
}