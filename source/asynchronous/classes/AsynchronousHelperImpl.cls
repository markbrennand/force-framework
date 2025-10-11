/**
 * @description
 * <p>
 * Implementation of Asynchronous Helper.
 * <p>
 * Implementation class is private to prevent re-use.
 * <p>
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../LICENSE target="_blank">MIT License</a>.
 * 
 * @author Mark Brennand
 */
public with sharing class AsynchronousHelperImpl {

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
     * Class providing the implementation of the API.
     */
    private with sharing class API implements AsynchronousHelper.API {

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
        final AsynchronousImpl.ApexJobRunnable runnable = (AsynchronousImpl.ApexJobRunnable) asyncJob.getRunnable();

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
        @SuppressWarnings('PMD.ApexDoc')
        public Object newInstance() {
            return new API();
        }
    }
}