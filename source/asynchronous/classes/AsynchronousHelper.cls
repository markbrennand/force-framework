/**
 * @description
 * <p>
 * Class containing helper methods for the Asynchronous framework.
 * <p>
 * The methods herein are intended for the sole use of the framework.
 * <p>
 * The implementation of the API is hidden in the private Implementation class. The class is hidden so an application
 * cannot access the class to mis-use it.
 * <p>
 * All application access is restricted to the API instance variable API. This ensures the application can only
 * ever call the methods of the API interface.
 * <p>
 * The outer class implements the API only to allow it to be mocked. Any calls to the API method implementations
 * in the outer class will throw an Exception.
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../LICENSE target="_blank">MIT License</a>.
 * <p>
 *
 * @author Mark Brennand
 */
public with sharing virtual class AsynchronousHelper extends AsynchronousHelperMockable {

    /**
     * @description
     * <p>
     * Active API instance.
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
     * Interface defining the API provided by this class.
     */
    public interface API {

        /**
         * @description
         * <p>
         * Records the detail of an Exception.
         * <p>
         * Due to a stubbing issue with Exception, the actual Exception must be wrapped in APIException.
         *
         * @param asyncObject The Asynchronous object to record the Exception against.
         * @param exc The exception to be recorded.
         */
        void recordException(final AsynchronousJob__c asyncObject, final AsynchronousV1.APIException exc);

        /**
         * @description
         * <p>
         * Records a new internal Exception encountered in the framework.
         * <p>
         * Due to a stubbing issue with Exception, the actual Exception must be wrapped in APIException.
         *
         * @param asyncObject The Asynchronous object to record the Exception against.
         * @param exc The exception to be recorded.
         */
        void recordInternalException(final AsynchronousJob__c asyncObject, final AsynchronousV1.APIException exc);

        /**
         * @description
         * <p>
         * Given the state retrieved from backing store, turns it into the internal representation.
         *
         * @param asyncStateObjects The state objects.
         *
         * @return The decoded state.
         */
        Map<String, String> decodeState(final List<AsynchronousJobState__c> asyncStateObjects);

        /**
         * @description
         * <p>
         * Given the internal state, turns it into a series of state objects representing it.
         *
         * @param asyncObject The Asynchronous object the state will be stored against.
         * @param state The internal state.
         *
         * @return The state objects representing the internal state.
         */
        List<AsynchronousJobState__c> encodeState(final AsynchronousJob__c asyncObject, final Map<String, String> state);

        /**
         * @description
         * <p>
         * Queues the given job for processing.
         *
         * @param asyncObject The job to be queued for processing.
         */
        void queueJob(final AsynchronousJob__c asyncObject);
    }

    /**
     * @description
     * <p>
     * Allow extension but not construction.
     *
     * This is also required to support the Apex mocking classes. A private constructor cannot be mocked.
     */
    @SuppressWarnings('PMD.EmptyStatementBlock')
    protected AsynchronousHelper() {}

    // Set the default implementation of the API. This can be overridden using a Dependency Injection Binding.
    static {
        DependencyV1.bind(API.class, AsynchronousHelperImpl.Factory.class);
    }
}