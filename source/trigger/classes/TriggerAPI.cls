/**
 * @description
 * Class providing the Trigger API.
 * <p/>
 * The Trigger custom metadata records define the subscribers for each object type. Each Trigger invocation
 * is turned into its representation as an Event. The event is then published to each subscriber
 * bound to the type of object the trigger has fired for.
 * <p/>
 * See <a href=../README.md target="_blank">README</a> for full details of the Trigger API.
 * <p/>
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../LICENSE target="_blank">MIT License</a>.
 *
 * @author Mark Brennand
 */
public with sharing virtual class TriggerAPI implements API {

    /**
     * @description
     * <p/>
     * Active API instance.
     * <p/>
     * The instance is injected from the Registry.
     * <p/>
     * The instance is test visible so it can be mocked.
     */
    @TestVisible
    @SuppressWarnings('PMD.PropertyNamingConventions')
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
     * <p/>
     * Action to be taken as a result of the check on the recursive depth.
     */
    private enum RecursiveDepthAction { PROCESS_EVENT, THROW_EXCEPTION, IGNORE_EVENT }

    /**
     * @description
     * <p/>
     * The API for trigger processing.
     * <p/>
     * The Trigger API will publish an Event representing the detail of the trigger. The Event will be consumed by
     * all the subscribers bound to the object type of the trigger that fired.
     */
    public interface API {

        /**
         * @description
         * <p/>
         * This method must create an Event representing the trigger being fired and send it to all the subscribers
         * bound to the object type of the trigger that fired.
         */
        void publish();

        /**
         * @description
         * <p/>
         * Disables the subscribers for the given object type.
         *
         * @param type The object type whose subscribers are to be disabled.
         */
        void disable(final SObjectType type);

        /**
         * @description
         * <p/>
         * Enables the subscribers for the given object type.
         *
         * @param type The object type whose subscribers are to be enabled.
         */
        void enable(final SObjectType type);

        /**
         * @description
         * <p/>
         * Determines whether subscribers are enabled for the given object type.
         *
         * @param type The object type whose subscription status is to be checked.
         *
         * @return True if the subscribers are enabled.
         */
        Boolean isEnabled(final SObjectType type);

        /**
         * @description
         * <p/>
         * Disables the given Subscriber class.
         * <p/>
         * No further events will be published to the associated subscriber.
         *
         * @param type The Subscriber class to disable.
         */
        void disable(final Type type);

        /**
         * @description
         * <p/>
         * Enables the given Subscriber class.
         * <p/>
         * Events will be published to the associated subscriber.
         *
         * @param type The Subscriber class to enable.
         */
        void enable(final Type type);

        /**
         * @description
         * <p/>
         * Determines whether the given Subscriber class is enabled.
         *
         * @param type The Subscriber class to be checked.
         *
         * @return True if the Subscriber class is enabled.
         */
        Boolean isEnabled(final Type type);
    }

    /**
     * @description
     * <p/>
     * Allow extension but not construction.
     * <p/>
     * This is also required to support the Apex mocking classes. A private constructor cannot be mocked.
     */
    @SuppressWarnings('PMD.EmptyStatementBlock')
    protected TriggerAPI() {}

    /**
     * @description
     * <p/>
     * Class providing the implementation of the API.
     * <p/>
     * The class is private to prevent its re-use.
     */
    private with sharing class Implementation implements API {

        /**
         * @description
         * <p/>
         * Record of all the active events for each object type.
         */
        private final Map<String, ArrayV1.Methods> events = new Map<String, ArrayV1.Methods>();

        /**
         * @description
         * <p/>
         * Cache of the Subscriber implementation for each object type.
         */
        private final Map<String, TriggerV1.Subscriber> subscribers = new Map<String, TriggerV1.Subscriber>();

        /**
         * @description
         * <p/>
         * Determines whether subscriber for an object type is enabled or not.
         */
        private final Map<SObjectType, Boolean> disabledObjectTypes = new Map<SObjectType, Boolean>();

        /**
         * @description
         * <p/>
         * Determines whether subscriber for an object type is enabled or not.
         */
        private final Map<String, Boolean> disabledSubscribers = new Map<String, Boolean>();

        /**
         * @description
         * <p/>
         * Cache of all the trigger definitions held in the custom metadata.
         */
        private final ImmutableV1.ReadOnlyMap triggerDefinitions {
            private get {
                if (triggerDefinitions == null) {
                    triggerDefinitions = loadTriggerDefinitions();
                }
                return triggerDefinitions;
            }
            private set;
        }

        /**
         * @description
         * <p/>
         * Publishes an Event representing the Trigger invocation to each subscriber bound to the object type
         * that fired the Trigger.
         */
        public void publish() {
            final SObjectType objectType = Trigger.isInsert
                    ? Trigger.new[0].getSObjectType()
                    : Trigger.old[0].getSObjectType();

            if (!isEnabled(objectType)) {
                return;
            }

            publishEvent(objectType);
        }

        /**
         * @description
         * <p/>
         * Disables the subscribers for the given object type.
         *
         * @param type The object type whose subscribers are to be disabled.
         */
        public void disable(final SObjectType type) {
            disabledObjectTypes.put(type, true);
        }

        /**
         * @description
         * <p/>
         * Enables the subscribers for the given object type.
         *
         * @param type The object type whose subscribers are to be enabled.
         */
        public void enable(final SObjectType type) {
            disabledObjectTypes.remove(type);
        }

        /**
         * @description
         * <p/>
         * Determines whether subscribers are enabled for the given object type.
         *
         * @param type The object type whose subscription status is to be checked.
         *
         * @return True if the subscribers are enabled.
         */
        public Boolean isEnabled(final SObjectType type) {
            return !disabledObjectTypes.containsKey(type) || disabledObjectTypes.get(type) != true;
        }

        /**
         * @description
         * <p/>
         * Disables the given Subscriber class.
         * <p/>
         * No further events will be published to the associated subscriber.
         *
         * @param type The Subscriber class to disable.
         */
        public void disable(final Type type) {
            disabledSubscribers.put(type.getName(), true);
        }

        /**
         * @description
         * <p/>
         * Enables the given Subscriber class.
         * <p/>
         * Events will be published to the associated subscriber.
         *
         * @param type The Subscriber class to enable.
         */
        public void enable(final Type type) {
            disabledSubscribers.remove(type.getName());
        }

        /**
         * @description
         * <p/>
         * Determines whether the given Subscriber class is enabled.
         *
         * @param type The Subscriber class to be checked.
         *
         * @return True if the Subscriber class is enabled.
         */
        public Boolean isEnabled(final Type type) {
            return !disabledSubscribers.containsKey(type.getName()) || disabledSubscribers.get(type.getName()) != true;
        }

        /**
         * @description
         * <p/>
         * Finds the Trigger custom metadata for the given object type and publishes an event representing the Trigger
         * invocation to each subscriber defined in the custom metadata.
         * <p/>
         * A check is performed on the recursive depth of the current trigger invocation. If the depth exceeds
         * the maximum value defined in the Trigger custom metadata record, then an Exception is thrown or
         * the Trigger invocation is ignored. The Trigger custom metadata record defines which action is taken.
         *
         * @param objectType The type of object the trigger has fired for.
         */
        private void publishEvent(final SObjectType objectType) {
            final String objectKey = getObjectKey(objectType.getDescribe(SObjectDescribeOptions.DEFERRED).name);

            if (triggerDefinitions.containsKey(objectKey)) {
                final TriggerV1.Event event = createEvent(objectKey);

                if (events.containsKey(objectKey)) {
                    events.get(objectKey).push(event);
                } else {
                    events.put(objectKey, ArrayV1.over(event));
                }

                try {
                    ArrayV1.over(triggerDefinitions.get(objectKey))
                            .sharing(new PublishingInformation(this, objectKey, event))
                            .forEach(new EventPublisher());

                } finally {
                    events.get(objectKey).pop();
                }

            } else {
                throw new TriggerV1.APIException('No Trigger metadata record found for ' + objectKey);
            }
        }

        /**
         * @description
         * <p/>
         * Builds the canonical key to match the Trigger_mdt.ObjectKey__c field.
         *
         * @param name The object type.
         *
         * @return The canonical key.
         */
        private String getObjectKey(final String name) {
            return name.replace('__c', '').replaceFirst('^.*__', '');
        }

        /**
         * @description
         * <p/>
         * Builds an Event representing the Trigger invocation.
         *
         * @param objectKey The canonical key of the object the Trigger has fired for.
         *
         * @return The Event representing the Trigger invocation.
         */
        private TriggerV1.Event createEvent(final String objectKey) {
            final Boolean isBefore = Trigger.isBefore;

            final TriggerV1.Operation operation =
                    Trigger.isInsert ? TriggerV1.Operation.INSERTING
                            : Trigger.isUpdate ? TriggerV1.Operation.UPDATING : TriggerV1.Operation.DELETING;

            final List<SObject> records = Trigger.isDelete ? Trigger.old : Trigger.new;

            return new Event(
                    records,
                    Trigger.isInsert ? OptionalV1.empty() : OptionalV1.of(Trigger.oldMap),
                    isBefore,
                    operation,
                    events.containsKey(objectKey) ? events.get(objectKey).length() + 1 : 1
            );
        }

        /**
         * @description
         * <p/>
         * Builds a cache of the Trigger custom metadata records.
         * <p/>
         * Each cache entry is keyed by the canonical object type and the value is the list of Trigger custom
         * metadata records registered for that type.
         *
         * @return The cache of Trigger custom metadata records.
         */
        private ImmutableV1.ReadOnlyMap loadTriggerDefinitions() {
            return ImmutableV1.of((Map<String, List<Trigger__mdt>>)
                    ArrayV1.over(Trigger__mdt.getAll().values())
                            .reduce(new TriggerDefinitionMapBuilder(), new Map<String, List<Trigger__mdt>>()));
        }
    }

    /**
     * @description
     * <p/>
     * Implementation of the Event interface.
     */
    private with sharing class Event implements TriggerV1.Event {
        private final List<SObject> records;
        private final OptionalV1 oldRecords;
        private final Boolean isBefore;
        private final TriggerV1.Operation operation;
        private final Integer recursiveDepth;

        /**
         * @description
         * <p/>
         * Constructs an event representing the DML operation.
         *
         * @param records The new values for the records resulting from the DML.
         * @param oldRecords  The original values for the records prior to the DML.
         * @param isBefore If true, the event is for the DML operation prior to persisting the data.
         * @param operation The DML operation being performed.
         * @param recursiveDepth The number of times the trigger has been invoked as a result of the top level DML.
         */
        public Event(
                final List<SObject> records,
                final OptionalV1 oldRecords,
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

        /**
         * @description
         * <p/>
         * Is a before operation being performed.
         *
         * @return True if Event represents a before operation.
         */
        public Boolean isBefore() {
            return isBefore;
        }

        /**
         * @description
         * <p/>
         * Is an after operation being performed.
         *
         * @return True if Event represents aa after operation.
         */
        public Boolean isAfter() {
            return !isBefore();
        }

        /**
         * @description
         * <p/>
         * The type of DML operation being performed.
         *
         * @return The operation being performed.
         */
        public TriggerV1.Operation getOperation() {
            return operation;
        }

        /**
         * @description
         * <p/>
         * The objects the DML operation is being performed on.
         *
         * @return The objects the DML operation is being performed on.
         */
        public List<SObject> getRecords() {
            return records;
        }

        /**
         * @description
         * <p/>
         * Tests whether the given object has a previous value.
         * <p/>
         * This method will only return true for a DML update.
         *
         * @param record The object to check.
         *
         * @return True if the object has a previous value.
         */
        public Boolean hasOldValue(final SObject record) {
            return oldRecords.isPresent() && ((Map<Id, SObject>) oldRecords.get()).containsKey(record.Id);
        }

        /**
         * @description
         * <p/>
         * Gets the original value of a record being updated.
         *
         * @param record The object to get the previous value of.
         *
         * @return The previous value of the object or an optional representing undefined.
         */
        public OptionalV1 getOldValue(final SObject record) {
            return oldRecords.isPresent()
                    ? OptionalV1.ofNullable(((Map<Id, SObject>) oldRecords.get()).get(record.Id))
                    : OptionalV1.empty();
        }

        /**
         * @description
         * <p/>
         * Gets the values of the records prior to update.
         *
         * @return The Map of old record values, or an optional representing undefined.
         */
        public OptionalV1 getOldValues() {
            return oldRecords;
        }

        /**
         * @description
         * <p/>
         * Gets the number of times the trigger has been called within the scope of the top level trigger invocation.
         *
         * @return The recursive depth.
         */
        public Integer getRecursiveDepth() {
            return recursiveDepth;
        }
    }

    /**
     * @description
     * <p/>
     * Creates the default API implementation.
     * <p/>
     * The constructor for the implementation is protected. This prevents the Dependency framework constructing it.
     * We use the factory to defer the construction by injection to this class, which is able to construct it.
     */
    public with sharing class Factory implements TypesV1.Factory {

        /**
         * @description
         * <p/>
         * Constructs an instance of the API implementation.
         *
         * @return The API implementation.
         */
        public Object newInstance() {
            return new Implementation();
        }
    }

    /**
     * @description
     * <p/>
     * Class providing check on Binding made to TriggerAPI.API.
     */
    public with sharing class BindingCheck implements DependencyV1.BindingCheck {

        /**
         * @description
         * <p/>
         * Checks that a valid binding has been made to TriggerAPI.API.
         *
         * @param forType The type being bound to, TriggerAPI.API.
         * @param withImpl The implementation being bound to TriggerAPI.API.
         *
         * @return The result of the validation.
         */
        public DependencyV1.ValidationResult validate(final Type forType, final Type withImpl) {
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
     * <p/>
     * Builds the Map of object name to its associated Trigger metadata records.
     */
    private with sharing class TriggerDefinitionMapBuilder extends ArrayV1.Callback {
        public override OptionalV1 function(final Object element, final OptionalV1 currentValue, final Integer index) {
            final Map<String, List<Trigger__mdt>> triggerDefinitions = (Map<String, List<Trigger__mdt>>) currentValue.get();
            final Trigger__mdt triggerDefinition  = (Trigger__mdt) element;
            final String objectKey = triggerDefinition.ObjectKey__c;

            if (triggerDefinitions.containsKey(objectKey)) {
                triggerDefinitions.get(objectKey).add(triggerDefinition);
            } else {
                triggerDefinitions.put(objectKey, new List<Trigger__mdt> { triggerDefinition });
            }

            return OptionalV1.of(triggerDefinitions);
        }
    }

    /**
     * @description
     * <p/>
     * Class called from forEach to publish event to each Subscriber defined in the Trigger metadata records for
     * the object.
     */
    private with sharing class EventPublisher extends ArrayV1.Callback {

        /**
         * @description
         * <p/>
         * Publishes the Event to the the Subscriber defined by the Trigger metadata record being processed.
         *
         * @param element The Trigger metadata record.
         * @param currentValue The publishing information.
         * @param index The positional index in the array of Trigger metadata records.
         *
         * @return Return value is ignored by caller.
         */
        public override OptionalV1 function(final Object element, final OptionalV1 currentValue, final Integer index) {
            final Trigger__mdt triggerDefinition = (Trigger__mdt) element;

            if (triggerDefinition.IsUnitTest__c != Test.isRunningTest()) {
                return OptionalV1.empty();
            }

            // Add any namespace to the class before checking.
            final Type subscriberType = TypesV1.load(triggerDefinition.SubscriberClass__c);
            if (getPublishingInformation().parent.disabledSubscribers.containsKey(subscriberType.getName())) {
                return OptionalV1.empty();
            }

            switch on checkRecursiveDepth(getPublishingInformation().objectKey, triggerDefinition) {
                when THROW_EXCEPTION {
                    throw new TriggerV1.APIException('Maximum recursive calls exceeded for ' + getPublishingInformation().objectKey + ' event');
                }
                when IGNORE_EVENT {
                    return OptionalV1.empty();
                }
                when PROCESS_EVENT {
                    processEvent(triggerDefinition, getPublishingInformation().event);
                }
            }

            return OptionalV1.empty();
        }

        /**
         * @description
         * <p/>
         * For the given canonical key and Trigger custom metadata records, the current recursive depth is checked
         * against the maximum value set in the custom metadata record.
         *
         * @param objectKey The canonical key for the object the trigger has fired for.
         * @param triggerDefinition The Trigger custom metadata record being processed.
         *
         * @return Result of the processing.
         */
        private RecursiveDepthAction checkRecursiveDepth(final String objectKey, final Trigger__mdt triggerDefinition) {
            final Integer maximumRecursiveCalls = (Integer) triggerDefinition.MaximumRecursiveDepth__c;
            if ((maximumRecursiveCalls > 0) &&
                    (getPublishingInformation().parent.events.get(getPublishingInformation().objectKey).length() >
                            maximumRecursiveCalls)
            ) {
                return triggerDefinition.ThrowExceptionWhenRecursionExceeded__c
                        ? RecursiveDepthAction.THROW_EXCEPTION
                        : RecursiveDepthAction.IGNORE_EVENT;
            }

            return RecursiveDepthAction.PROCESS_EVENT;
        }

        /**
         * @description
         * <p/>
         * For the given Trigger definition and Event, the Subscriber for the definition is loaded and the onEvent
         * of it is called.
         *
         * @param triggerDefinition The Trigger custom metadata record registered to process event.
         * @param event The Event to publish.
         */
        private void processEvent(final Trigger__mdt triggerDefinition, final TriggerV1.Event event) {
            if (!isSubscriberBoundToAction(triggerDefinition, event.getOperation(), event.isBefore())) {
                return;
            }

            final String subscriberClass = triggerDefinition.SubscriberClass__c;
            final TriggerV1.Subscriber subscriber;

            if (getPublishingInformation().parent.subscribers.containsKey(subscriberClass)) {
                subscriber = getPublishingInformation().parent.subscribers.get(subscriberClass);
            } else {
                subscriber = (TriggerV1.Subscriber)
                        TypesV1.newInstance(TypesV1.load(triggerDefinition.SubscriberClass__c));

                getPublishingInformation().parent.subscribers.put(subscriberClass, subscriber);
            }

            subscriber.onEvent(event);
        }

        /**
         * @description
         * <p/>
         * Gets the publishing information for the Event.
         *
         * @return The publishing information.
         */
        private PublishingInformation getPublishingInformation() {
            return (PublishingInformation) shared().get();
        }
    }

    /**
     * @description
     * <p/>
     * Class encapsulating all the information required to publish an event from an inner class called from forEach.
     */
    private with sharing class PublishingInformation {
        private final Implementation parent { private get; private set; }
        private final String objectKey { private get; private set; }
        private final TriggerV1.Event event { private get; private set; }

        /**
         * @description
         * <p/>
         * Details of an event to be published.
         *
         * @param parent The API implementation publishing the event.
         * @param objectKey The key for the object the event is being published for.
         * @param event The event to publish.
         */
        public PublishingInformation(
                final Implementation parent,
                final String objectKey,
                final TriggerV1.Event event

        ) {
            this.parent = parent;
            this.objectKey = objectKey;
            this.event = event;
        }
    }

    /**
     * @description
     * <p/>
     * Determines whether the subscriber defined by a trigger definition is bound to receive the event for the
     * current trigger action.
     *
     * @param triggerDefinition The trigger definition to check.
     * @param operation The operation being performed.
     * @param isBefore True if trigger before action is being called.
     *
     * @return True if the subscriber is bound the action.
     */
    @TestVisible
    private static Boolean isSubscriberBoundToAction(
            final Trigger__mdt triggerDefinition,
            final TriggerV1.Operation operation,
            final Boolean isBefore)
    {
        switch on operation {
            when INSERTING {
                return isBefore ? triggerDefinition.BeforeInsert__c : triggerDefinition.AfterInsert__c;
            }
            when UPDATING {
                return isBefore ? triggerDefinition.BeforeUpdate__c : triggerDefinition.AfterUpdate__c;
            }
            when DELETING {
                return isBefore ? triggerDefinition.BeforeDelete__c : triggerDefinition.AfterDelete__c;
            }
        }
        return false;
    }

    /**
     * @description
     * <p/>
     * Method is solely for mocking use.
     */
    public void publish() {
        throw new TriggerV1.APIException('Access denied');
    }

    /**
     * @description
     * <p/>
     * Method is solely for mocking use.
     *
     * @param type ignored.
     */
    public void disable(final SObjectType type) {
        throw new TriggerV1.APIException('Access denied');
    }

    /**
     * @description
     * <p/>
     * Method is solely for mocking use.
     *
     * @param type ignored.
     */
    public void enable(final SObjectType type) {
        throw new TriggerV1.APIException('Access denied');
    }

    /**
     * @description
     * <p/>
     * Method is solely for mocking use.
     *
     * @param type ignored.
     *
     * @return ignored.
     */
    public Boolean isEnabled(final SObjectType type) {
        throw new TriggerV1.APIException('Access denied');
    }

    /**
     * @description
     * <p/>
     * Method is solely for mocking use.
     *
     * @param type ignored.
     */
    public void disable(final Type type) {
        throw new TriggerV1.APIException('Access denied');
    }

    /**
     * @description
     * <p/>
     * Method is solely for mocking use.
     *
     * @param type ignored.
     */
    public void enable(final Type type) {
        throw new TriggerV1.APIException('Access denied');
    }

    /**
     * @description
     * <p/>
     * Method is solely for mocking use.
     *
     * @param type ignored.
     *
     * @return ignored.
     */
    public Boolean isEnabled(final Type type) {
        throw new TriggerV1.APIException('Access denied');
    }

    // Set the default implementation of API. This can be overridden using a Dependency Injection Binding.
    static {
        DependencyV1.bind(API.class, Factory.class);
    }
}