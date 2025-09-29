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
public with sharing virtual class AsynchronousHelper implements API {

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
     * Maximum amount of data that can be stored in a chunk.
     * <p>
     * The variable is not declared as final so it can be overridden by a unit test.
     */
    @TestVisible
    private static Integer maxChunkSize = 131072;

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
     * Allow extension but not construction.
     *
     * This is also required to support the Apex mocking classes. A private constructor cannot be mocked.
     */
    @SuppressWarnings('PMD.EmptyStatementBlock')
    protected AsynchronousHelper() {}

    /**
     * @description
     * <p>
     * Class providing the implementation of the API.
     */
    private with sharing class Implementation implements API {

        /**
         * @description
         * <p>
         * Records the detail of an Exception in an Asynchronous Exception object.
         * <p>
         * A new record is created and persisted for each Exception recorded.
         *
         * @param asyncObject The Asynchronous object to record the Exception against.
         * @param exc The wrapped exception to be recorded.
         */
        public void recordException(final AsynchronousJob__c asyncObject, final AsynchronousV1.APIException exc) {
            AssertionV1.isNotNull(asyncObject, 'argument: AsynchronousHelper.apiRecordException.asynchronousObject');
            AssertionV1.isNotNull(exc, 'argument: AsynchronousHelper.apiRecordException.exc');

            final AsynchronousJobException__c asyncError = new AsynchronousJobException__c(
                    AsynchronousJob__c = asyncObject.Id,
                    RetryNumber__c = asyncObject.RetryNumber__c,
                    StatusOnError__c = asyncObject.Status__c,
                    ApexJobId__c = asyncObject.ApexJobId__c,
                    ExceptionType__c = exc.getCause().getTypeName(),
                    ExceptionMessage__c = exc.getCause().getMessage(),
                    ExceptionStackTrace__c = exc.getCause().getStackTraceString()
            );

            AsynchronousDAO.impl.persistException(asyncError);
        }

        /**
         * @description
         * <p>
         * Records a new internal error encountered in the framework.
         * <p>
         * Exceptions thrown from the Runnable for an Apex job are not recorded using this method.
         * <p>
         * A new Asynchronous Exception is created to record the Exception and the Status of the Asynchronous job
         * is changed to indicate it failed. No further processing will be performed on the job.
         *
         * @param asyncObject The Asynchronous object to record the Exception against.
         * @param exc The wrapped exception to be recorded.
         */
        public void recordInternalException(final AsynchronousJob__c asyncObject, final AsynchronousV1.APIException exc) {
            recordException(asyncObject, exc);
            asyncObject.Status__c = AsynchronousV1.Status.FAILED.name();
            AsynchronousDAO.impl.persistObjects(new List<AsynchronousJob__c> { asyncObject });
        }

        /**
         * @description
         * <p>
         * Given the state objects retrieved from backing store, turns them into their internal representation.
         *
         * @param asyncStateObjects The state objects.
         *
         * @return The decoded state.
         */
        public Map<String, String> decodeState(final List<AsynchronousJobState__c> asyncStateObjects) {
            AssertionV1.isNotNull(asyncStateObjects, 'argument: AsynchronousHelper.apiDecodeState.asyncStateObjects');

            final List<String> chunks = new List<String>();

            for (AsynchronousJobState__c chunk : asyncStateObjects) {
                chunks.add(chunk.Content__c);
            }

            AssertionV1.isTrue(!chunks.isEmpty(), 'No asynchronous state chunks found for job');

            return (Map<String, String>) JSON.deserialize(String.join(chunks, ''), Map<String, String>.class);
        }

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
        public List<AsynchronousJobState__c> encodeState(
                final AsynchronousJob__c asyncObject,
                final Map<String, String> state
        ) {
            AssertionV1.isNotNull(asyncObject, 'argument: AsynchronousHelper.apiEncodeState.asyncObject');
            AssertionV1.isNotNull(state, 'argument: AsynchronousHelper.apiEncodeState.state');

            final List<AsynchronousJobState__c> chunks = new List<AsynchronousJobState__c>();
            String stateJson = JSON.serialize(state);
            Integer size = stateJson.length();
            Integer chunkNumber = 0;

            while (size > maxChunkSize) {
                chunks.add(new AsynchronousJobState__c(
                        AsynchronousJob__c = asyncObject.Id,
                        ChunkNumber__c = ++chunkNumber,
                        Content__c = stateJson.substring(0, maxChunkSize)
                ));

                stateJson = stateJson.substring(maxChunkSize);
                size -= maxChunkSize;
            }

            if (size > 0) {
                chunks.add(new AsynchronousJobState__c(
                        AsynchronousJob__c = asyncObject.Id,
                        ChunkNumber__c = ++chunkNumber,
                        Content__c = stateJson
                ));
            }

            return chunks;
        }

        /**
         * @description
         * <p>
         * Schedules an Apex job for the given Asynchronous object.
         * <p>
         * If an Exception occurs during the queueing, a future job is started to run the job.
         *
         * @param asyncObject The job to be queued.
         */
        public void queueJob(final AsynchronousJob__c asyncObject) {
            AssertionV1.isNotNull(asyncObject, 'argument: AsynchronousHelper.apiQueueJob.asyncObject');

            try {
                enqueueApexJob(asyncObject);
            } catch(Exception exc) {
                startAsynchronousJob(asyncObject.Id);
            }
        }
    }

    /**
     * @description
     * Method is solely for mocking use.
     *
     * @param asyncObject ignored.
     * @param exc ignored.
     */
    public void recordException(final AsynchronousJob__c asyncObject, final AsynchronousV1.APIException exc) {
        throw new AsynchronousV1.APIException('Access denied');
    }

    /**
     * @description
     * <p>
     * Method is solely for mocking use.
     *
     * @param asyncObject ignored.
     * @param exc ignored.
     */
    public void recordInternalException(final AsynchronousJob__c asyncObject, final AsynchronousV1.APIException exc) {
        throw new AsynchronousV1.APIException('Access denied');
    }

    /**
     * @description
     * <p>
     * Method is solely for mocking use.
     *
     * @param asyncStateObjects ignored.
     *
     * @return ignored.
     */
    public Map<String, String> decodeState(final List<AsynchronousJobState__c> asyncStateObjects) {
        throw new AsynchronousV1.APIException('Access denied');
    }

    /**
     * @description
     * <p>
     * Method is solely for mocking use.
     *
     * @param asyncObject ignored.
     * @param state ignored.
     *
     * @return ignored.
     */
    public List<AsynchronousJobState__c> encodeState(
            final AsynchronousJob__c asyncObject,
            final Map<String, String> state
    ) {
        throw new AsynchronousV1.APIException('Access denied');
    }

    /**
     * @description
     * <p>
     * Method is solely for mocking use.
     *
     * @param asyncObject ignored.
     */
    public void queueJob(final AsynchronousJob__c asyncObject) {
        throw new AsynchronousV1.APIException('Access denied');
    }

    /**
     * @description
     * <p>
     * Called if an Apex job could not be started in the request it was queued in.
     * <p>
     * The most likely reason the job could not be started is exceeding the Apex job chaining limit.
     *
     * @param asyncObjectId The id of the AsynchronousJob__c to be started.
     */
    @Future
    private static void startAsynchronousJob(final String asyncObjectId) {
        AssertionV1.isNotNull(asyncObjectId, 'argument: AsynchronousHelper.startAsynchronousJob.asyncObjectId');
        final AsynchronousJob__c asyncObject = AsynchronousDAO.impl.getObject(asyncObjectId);

        try {
            enqueueApexJob(asyncObject);
        } catch(Exception exc) {
            AsynchronousHelper.impl.recordInternalException(asyncObject, new AsynchronousV1.APIException('Wrapper', exc));
        }
    }

    /**
     * @description
     * <p>
     * Creates an Apex job for the given Asynchronous object.
     *
     * @param asyncObject The job to be started.
     */
    private static void enqueueApexJob(final AsynchronousJob__c asyncObject) {
        AssertionV1.isNotNull(asyncObject, 'argument: AsynchronousHelper.enqueueApexJob.asyncObject');

        final AsynchronousJob asyncJob = (AsynchronousJob) AsynchronousJob.fromSObject(asyncObject);
        final AsynchronousAPI.ApexJobRunnable runnable = (AsynchronousAPI.ApexJobRunnable) asyncJob.getRunnable();

        asyncObject.Status__c = AsynchronousV1.Status.RUNNING.name();
        asyncObject.LastRunTime__c = CommonHelper.now();

        AsynchronousDAO.impl.persistObjects(new List<AsynchronousJob__c> { asyncObject });

        asyncObject.ApexJobId__c = System.enqueueJob(
                runnable.forJob(AsynchronousJob.fromSObject(AsynchronousDAO.impl.getObject(asyncObject.Id)))
        );

        AsynchronousDAO.impl.persistObjects(new List<AsynchronousJob__c> { asyncObject });
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
         * Returns a new instance of the API implementation.
         *
         * @return The API implementation.
         */
        public Object newInstance() {
            return new Implementation();
        }
    }

    /**
     * @description
     * <p>
     * Class providing check on Binding made to AsynchronousDAO.API.
     */
    public with sharing class BindingCheck implements DependencyV1.BindingCheck {

        /**
         * @description
         * <p>
         * Checks that a valid binding has been made to AsynchronousDAO.API.
         *
         * @param forType The type being bound to, AsynchronousDAO.API.
         * @param withImpl The implementation being bound to AsynchronousDAO.API.
         *
         * @return The result of the validation.
         */
        public DependencyV1.ValidationResult validate(final Type forType, final Type withImpl) {
            return DependencyHelper.buildValidationResult(
                    TypesV1.newInstance(withImpl) instanceof AsynchronousHelper.API,
                    true,
                    forType,
                    withImpl
            );
        }
    }

    // Set the default implementation of the API. This can be overridden using a Dependency Injection Binding.
    static {
        DependencyV1.bind(API.class, Factory.class);
    }
}