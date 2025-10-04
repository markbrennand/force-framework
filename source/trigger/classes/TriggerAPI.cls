/**
 * @description
 * Class providing the Trigger API.
 * <p>
 * The Trigger custom metadata records define the subscribers for each object type. Each Trigger invocation
 * is turned into its representation as an Event. The event is then published to each subscriber
 * bound to the type of object the trigger has fired for.
 * <p>
 * See <a href=../README.md target="_blank">README</a> for full details of the Trigger API.
 * <p>
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../LICENSE target="_blank">MIT License</a>.
 *
 * @author Mark Brennand
 */
public with sharing virtual class TriggerAPI extends TriggerAPIMockable {

    /**
     * @description
     * <p>
     * Active API instance.
     * <p>
     * The instance is injected from the Registry.
     * <p>
     * The instance is test visible so it can be mocked.
     */
    @TestVisible
    public static API impl {
        public get {
            if (Test.isRunningTest() && impl != null) { // API has been mocked.
                return impl;
            } else {
                return (API) DependencyV1.inject(API.class);
            }
        }
        private set;
    }

    /**
     * @description
     * <p>
     * The API for trigger processing.
     * <p>
     * The Trigger API will publish an Event representing the detail of the trigger. The Event will be consumed by
     * all the subscribers bound to the object type of the trigger that fired.
     */
    public interface API {

        /**
         * @description
         * <p>
         * This method must create an Event representing the trigger being fired and send it to all the subscribers
         * bound to the object type of the trigger that fired.
         */
        void publish();

        /**
         * @description
         * <p>
         * Disables the subscribers for the given object type.
         *
         * @param type The object type whose subscribers are to be disabled.
         */
        void disable(final SObjectType type);

        /**
         * @description
         * <p>
         * Enables the subscribers for the given object type.
         *
         * @param type The object type whose subscribers are to be enabled.
         */
        void enable(final SObjectType type);

        /**
         * @description
         * <p>
         * Determines whether subscribers are enabled for the given object type.
         *
         * @param type The object type whose subscription status is to be checked.
         *
         * @return True if the subscribers are enabled.
         */
        Boolean isEnabled(final SObjectType type);

        /**
         * @description
         * <p>
         * Disables the given Subscriber class.
         * <p>
         * No further events will be published to the associated subscriber.
         *
         * @param type The Subscriber class to disable.
         */
        void disable(final Type type);

        /**
         * @description
         * <p>
         * Enables the given Subscriber class.
         * <p>
         * Events will be published to the associated subscriber.
         *
         * @param type The Subscriber class to enable.
         */
        void enable(final Type type);

        /**
         * @description
         * <p>
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
     * <p>
     * Allow extension but not construction.
     * <p>
     * This is also required to support the Apex mocking classes. A private constructor cannot be mocked.
     */
    @SuppressWarnings('PMD.EmptyStatementBlock')
    protected TriggerAPI() {}

    // Set the default implementation of API. This can be overridden using a Dependency Injection Binding.
    static {
        DependencyV1.bind(API.class, TriggerImpl.Factory.class);
    }
}