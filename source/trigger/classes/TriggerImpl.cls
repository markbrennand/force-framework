/**
 * @description
 * <p>
 * Implementation of the Trigger API.
 * <p>
 * The class implementing the API is private to prevent its re-use.
 * <p>
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../LICENSE target="_blank">MIT License</a>.
 * 
 * @author Mark Brennand
 */
public with sharing class TriggerImpl {

    /**
     * @description
     * <p>
     * Action to be taken as a result of the check on the recursive depth.
     */
    private enum RecursiveDepthAction { PROCESS_EVENT, THROW_EXCEPTION, IGNORE_EVENT }

    /**
     * @description
     * <p>
     * Class encapsulating all the information required to publish an event from an inner class called from forEach.
     */
    private with sharing class PublishingInformation {
        private final API parent { private get; private set; }
        private final String objectKey { private get; private set; }
        private final TriggerV1.Event event { private get; private set; }

        /**
         * @description
         * <p>
         * Details of an event to be published.
         *
         * @param parent The API implementation publishing the event.
         * @param objectKey The key for the object the event is being published for.
         * @param event The event to publish.
         */
        public PublishingInformation(
                final API parent,
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
     * <p>
     * Class providing the implementation of the API.
     * <p>
     * The class is private to prevent its re-use.
     */
    private with sharing class API implements TriggerAPI.API {

        /**
         * @description
         * <p>
         * Record of all the active events for each object type.
         */
        private final Map<String, ArrayV1.Methods> events = new Map<String, ArrayV1.Methods>();

        /**
         * @description
         * <p>
         * Cache of the Subscriber implementation for each object type.
         */
        private final Map<String, TriggerV1.Subscriber> subscribers = new Map<String, TriggerV1.Subscriber>();

        /**
         * @description
         * <p>
         * Cache of the Filter implementation for each object type.
         */
        private final Map<String, ArrayV1.Callback> filters = new Map<String, ArrayV1.Callback>();

        /**
         * @description
         * <p>
         * Determines whether subscriber for an object type is enabled or not.
         */
        private final Map<SObjectType, Boolean> disabledObjectTypes = new Map<SObjectType, Boolean>();

        /**
         * @description
         * <p>
         * Determines whether subscriber for an object type is enabled or not.
         */
        private final Map<String, Boolean> disabledSubscribers = new Map<String, Boolean>();

        /**
         * @description
         * <p>
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
         * <p>
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
         * <p>
         * Disables the subscribers for the given object type.
         *
         * @param type The object type whose subscribers are to be disabled.
         */
        public void disable(final SObjectType type) {
            disabledObjectTypes.put(type, true);
        }

        /**
         * @description
         * <p>
         * Enables the subscribers for the given object type.
         *
         * @param type The object type whose subscribers are to be enabled.
         */
        public void enable(final SObjectType type) {
            disabledObjectTypes.remove(type);
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
        public Boolean isEnabled(final SObjectType type) {
            return !disabledObjectTypes.containsKey(type) || disabledObjectTypes.get(type) != true;
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
        public void disable(final Type type) {
            disabledSubscribers.put(type.getName(), true);
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
        public void enable(final Type type) {
            disabledSubscribers.remove(type.getName());
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
        public Boolean isEnabled(final Type type) {
            return !disabledSubscribers.containsKey(type.getName()) || disabledSubscribers.get(type.getName()) != true;
        }

        /**
         * @description
         * <p>
         * Finds the Trigger custom metadata for the given object type and publishes an event representing the Trigger
         * invocation to each subscriber defined in the custom metadata.
         * <p>
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
         * <p>
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
         * <p>
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

            return TriggerEvent.newEvent(
                    records,
                    Trigger.isInsert ? OptionalV1.empty() : OptionalV1.of(ImmutableV1.of(Trigger.oldMap)),
                    isBefore,
                    operation,
                    events.containsKey(objectKey) ? events.get(objectKey).length() + 1 : 1
            );
        }

        /**
         * @description
         * <p>
         * Builds a cache of the Trigger custom metadata records.
         * <p>
         * Each cache entry is keyed by the canonical object type and the value is the list of Trigger custom
         * metadata records registered for that type.
         *
         * @return The cache of Trigger custom metadata records.
         */
        private ImmutableV1.ReadOnlyMap loadTriggerDefinitions() {
            return ImmutableV1.of((Map<String, List<Trigger__mdt>>)
                    ArrayV1.over(Trigger__mdt.getAll().values())
                            .reduce(new TriggerHelper.TriggerDefinitionMapBuilder(), new Map<String, List<Trigger__mdt>>()));
        }
    }

    /**
     * @description
     * <p>
     * Class called from forEach to publish event to each Subscriber defined in the Trigger metadata records for
     * the object.
     */
    private with sharing class EventPublisher extends ArrayV1.Callback {

        /**
         * @description
         * <p>
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

            final OptionalV1 eventToPublish = getEventToPublish(
                    getPublishingInformation().event,
                    triggerDefinition);

            if (!eventToPublish.isPresent()) {
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
                when PROCESS_EVENT {
                    processEvent(triggerDefinition, (TriggerV1.Event) eventToPublish.get());
                }
            }

            return OptionalV1.empty();
        }

        /**
         * @description
         * <p>
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
         * <p>
         * For the given Trigger definition and Event, the Subscriber for the definition is loaded and the onEvent
         * of it is called.
         *
         * @param triggerDefinition The Trigger custom metadata record registered to process event.
         * @param event The Event to publish.
         */
        private void processEvent(final Trigger__mdt triggerDefinition, final TriggerV1.Event event) {
            if (!TriggerHelper.isSubscriberBoundToAction(triggerDefinition, event.getOperation(), event.isBefore())) {
                return;
            }

            final TriggerV1.Subscriber subscriber = getSubscriber(triggerDefinition);
            subscriber.onEvent(event);
        }

        /**
         * @description
         * <p>
         * Gets the publishing information for the Event.
         *
         * @return The publishing information.
         */
        private PublishingInformation getPublishingInformation() {
            return (PublishingInformation) shared().get();
        }

        private TriggerV1.Subscriber getSubscriber(final Trigger__mdt triggerDefinition) {
            final String subscriberClass = triggerDefinition.SubscriberClass__c;
            if (getPublishingInformation().parent.subscribers.containsKey(subscriberClass)) {
                return  getPublishingInformation().parent.subscribers.get(subscriberClass);
            } else {
                TriggerV1.Subscriber subscriber = (TriggerV1.Subscriber)
                        TypesV1.newInstance(TypesV1.load(triggerDefinition.SubscriberClass__c));

                getPublishingInformation().parent.subscribers.put(subscriberClass, subscriber);
                return subscriber;
            }
        }

        private OptionalV1 getEventToPublish(final TriggerV1.Event event, final Trigger__mdt triggerDefinition) {
            OptionalV1 filter = getFilter(triggerDefinition);
            if (filter.isPresent()) {
                final List<SObject> matches = (List<SObject>) event.getRecords()
                        .sharing(event.getOldValues())
                        .filter((ArrayV1.Callback) filter.get());

                if (matches.isEmpty()) {
                    return OptionalV1.empty();
                } else {
                    return OptionalV1.of(TriggerEvent.newEvent(
                            matches,
                            event.getOldValues(),
                            event.isBefore(),
                            event.getOperation(),
                            event.getRecursiveDepth()
                    ));
                }
            } else {
                return OptionalV1.of(event);
            }
        }

        private OptionalV1 getFilter(final Trigger__mdt triggerDefinition) {
            final String filterClass = triggerDefinition.FilterClass__c;
            if (String.isEmpty(filterClass)) {
                return OptionalV1.empty();
            }

            final Map<String, ArrayV1.Callback> filters = (Map<String, ArrayV1.Callback>) getPublishingInformation().parent.filters;
            if (filters.containsKey(filterClass)) {
                return OptionalV1.of(filters.get(filterClass));
            } else {
                ArrayV1.Callback filter = (ArrayV1.Callback) TypesV1.newInstance(TypesV1.load(filterClass));
                filters.put(filterClass, filter);
                return OptionalV1.of(filter);
            }
        }
    }

    /**
     * @description
     * <p>
     * Creates the default API implementation.
     * <p>
     * The constructor for the implementation is protected. This prevents the Dependency framework constructing it.
     * We use the factory to defer the construction by injection to this class, which is able to construct it.
     */
    public with sharing class Factory implements TypesV1.Factory {

        /**
         * @description
         * <p>
         * Constructs an instance of the API implementation.
         *
         * @return The API implementation.
         */
        public Object newInstance() {
            return new API();
        }
    }
}