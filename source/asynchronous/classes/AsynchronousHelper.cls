/**
 * @description
 * Class containing helper methods for the Asynchronous framework.
 *
 * The methods herein are intended for the sole use of the framework.
 *
 * @author Mark Brennand
 */
public with sharing virtual class AsynchronousHelper implements API {

    /**
     * @description
     * Maximum amount of data that can be stored in a chunk.
     *
     * The variable is not declared as final so it can be overridden by a unit test.
     */
    @TestVisible
    private static Integer MAX_CHUNK_SIZE = 131072;

    /**
     * @description
     * Interface defining the API provided by this class.
     */
    public interface API {

        /**
         * @description
         * Records the detail of an Exception.
         *
         * Due to a stubbing issue with Exception, the actual Exception must be wrapped in APIException.
         *
         * @param asyncObject The Asynchronous object to record the Exception against.
         * @param exc The exception to be recorded.
         */
        void apiRecordException(AsynchronousJob__c asyncObject, Asynchronous.APIException exc);

        /**
         * @description
         * Records a new internal Exception encountered in the framework.
         *
         * Due to a stubbing issue with Exception, the actual Exception must be wrapped in APIException.
         *
         * @param asyncObject The Asynchronous object to record the Exception against.
         * @param exc The exception to be recorded.
         */
        void apiRecordInternalException(AsynchronousJob__c asyncObject, Asynchronous.APIException exc);

        /**
         * @description
         * Given the state retrieved from backing store, turns it into the internal representation.
         *
         * @param asyncStateObjects The state objects.
         *
         * @return The decoded state.
         */
        Map<String, String> apiDecodeState(final List<AsynchronousJobState__c> asyncStateObjects);

        /**
         * @description
         * Given the internal state, turns it into a series of state objects representing it.
         *
         * @param asyncObject The Asynchronous object the state will be stored against.
         * @param state The internal state.
         *
         * @return The state objects representing the internal state.
         */
        List<AsynchronousJobState__c> apiEncodeState(AsynchronousJob__c asyncObject, Map<String, String> state);

        /**
         * @description
         * Queues the given job for processing.
         *
         * @param asyncObject The job to be queued for processing.
         *
         * @return True if the job was queued, false if not.
         */
        Boolean apiQueueJob(AsynchronousJob__c asyncObject);
    }

    /**
     * @description
     * Allow extension but not construction.
     *
     * This is also required to support the Apex mocking classes. A private constructor cannot be mocked.
     */
    protected AsynchronousHelper() {}

    /**
     * @description
     * Records the detail of an Exception in an Asynchronous Exception object.
     *
     * A new record is created and persisted for each Exception recorded.
     *
     * @param asyncObject The Asynchronous object to record the Exception against.
     * @param exc The wrapped exception to be recorded.
     */
    public void apiRecordException(final AsynchronousJob__c asyncObject, final Asynchronous.APIException exc) {
        Assertion.isNotNull(asyncObject, 'argument: AsynchronousHelper.apiRecordException.asynchronousObject');
        Assertion.isNotNull(exc, 'argument: AsynchronousHelper.apiRecordException.exc');

        final AsynchronousJobException__c asyncError = new AsynchronousJobException__c(
                AsynchronousJob__c = asyncObject.Id,
                RetryNumber__c = asyncObject.RetryNumber__c,
                StatusOnError__c = asyncObject.Status__c,
                ApexJobId__c = asyncObject.ApexJobId__c,
                ExceptionType__c = exc.getCause().getTypeName(),
                ExceptionMessage__c = exc.getCause().getMessage(),
                ExceptionStackTrace__c = exc.getCause().getStackTraceString()
        );

        AsynchronousDAO.persistException(asyncError);
    }

    /**
     * @description
     * Records a new internal error encountered in the framework.
     *
     * Exceptions thrown from the Runnable for an Apex job are not recorded using this method.
     *
     * A new Asynchronous Exception is created to record the Exception and the Status of the Asynchronous job
     * is changed to indicate it failed. No further processing will be performed on the job.
     *
     * @param asyncObject The Asynchronous object to record the Exception against.
     * @param exc The wrapped exception to be recorded.
     */
    public void apiRecordInternalException(final AsynchronousJob__c asyncObject, final Asynchronous.APIException exc) {
        apiRecordException(asyncObject, exc);
        asyncObject.Status__c = Asynchronous.Status.FAILED.name();
        AsynchronousDAO.persistObjects(new List<AsynchronousJob__c> { asyncObject });
    }

    /**
     * @description
     * Given the state objects retrieved from backing store, turns them into their internal representation.
     *
     * @param asyncStateObjects The state objects.
     *
     * @return The decoded state.
     */
    public Map<String, String> apiDecodeState(final List<AsynchronousJobState__c> asyncStateObjects) {
        Assertion.isNotNull(asyncStateObjects, 'argument: AsynchronousHelper.apiDecodeState.asyncStateObjects');

        final List<String> chunks = new List<String>();

        for (AsynchronousJobState__c chunk : asyncStateObjects) {
            chunks.add(chunk.Content__c);
        }

        Assert.isFalse(chunks.isEmpty(), 'No asynchronous state chunks found for job');

        return (Map<String, String>) JSON.deserialize(String.join(chunks, ''), Map<String, String>.class);
    }

    /**
     * @description
     * Given the internal state, turns it into a series of state objects representing it.
     *
     * @param asyncObject The Asynchronous object the state will be stored against.
     * @param state The internal state.
     *
     * @return The state objects representing the internal state.
     */
    public List<AsynchronousJobState__c> apiEncodeState(
            final AsynchronousJob__c asyncObject,
            final Map<String, String> state
    ) {
        Assertion.isNotNull(asyncObject, 'argument: AsynchronousHelper.apiEncodeState.asyncObject');
        Assertion.isNotNull(state, 'argument: AsynchronousHelper.apiEncodeState.state');

        final List<AsynchronousJobState__c> chunks = new List<AsynchronousJobState__c>();
        String stateJson = JSON.serialize(state);
        Integer size = stateJson.length();
        Integer chunkNumber = 0;

        while (size > MAX_CHUNK_SIZE) {
            chunks.add(new AsynchronousJobState__c(
                    AsynchronousJob__c = asyncObject.Id,
                    ChunkNumber__c = ++chunkNumber,
                    Content__c = stateJSON.substring(0, MAX_CHUNK_SIZE)
            ));

            stateJson = stateJson.substring(MAX_CHUNK_SIZE);
            size -= MAX_CHUNK_SIZE;
        }

        if (size > 0) {
            chunks.add(new AsynchronousJobState__c(
                    AsynchronousJob__c = asyncObject.Id,
                    ChunkNumber__c = ++chunkNumber,
                    Content__c = stateJSON
            ));
        }

        return chunks;
    }

    /**
     * @description
     * Schedules an Apex job for the given Asynchronous object.
     *
     * If an Exception occurs during the queueing, a future job is started to run the job.
     *
     * @param asyncObject The job to be queued.
     *
     * @return True if the job was queued, false if not.
     */
    public Boolean apiQueueJob(final AsynchronousJob__c asyncObject) {
        Assertion.isNotNull(asyncObject, 'argument: AsynchronousHelper.apiQueueJob.asyncObject');

        try {
            return enqueueApexJob(asyncObject, false);
        } catch(Exception exc) {
            startAsynchronousJob(asyncObject.Id);
            return true;
        }
    }

    /**
     * @description
     * Records the detail of an Exception.
     *
     * @param asyncObject The Asynchronous object to record the Exception against.
     * @param exc The exception to be recorded.
     */
    public static void recordException(final AsynchronousJob__c asyncObject, final Exception exc) {
        INSTANCE.apiRecordException(asyncObject, new Asynchronous.APIException('Wrapper', exc));
    }

    /**
     * @description
     * Records a new internal error encountered in the framework.
     *
     * @param asyncObject The Asynchronous object to record the Exception against.
     * @param exc The exception to be recorded.
     */
    public static void recordInternalException(final AsynchronousJob__c asyncObject, final Exception exc) {
        INSTANCE.apiRecordInternalException(asyncObject, new Asynchronous.APIException('Wrapper', exc));
    }

    /**
     * @description
     * Given the state objects retrieved from backing store, turns them into their internal representation.
     *
     * @param asyncStateObjects The state objects.
     *
     * @return The decoded state.
     */
    public static Map<String, String> decodeState(final List<AsynchronousJobState__c> asyncStateObjects) {
        return INSTANCE.apiDecodeState(asyncStateObjects);
    }

    /**
     * @description
     * Given the internal state, turns it into a series of state objects representing it.
     *
     * @param asyncObject The Asynchronous object the state will be stored against.
     * @param state The internal state.
     *
     * @return The state objects representing the internal state.
     */
    public static List<AsynchronousJobState__c> encodeState(
            final AsynchronousJob__c asyncObject,
            final Map<String, String> state
    ) {
        return INSTANCE.apiEncodeState(asyncObject, state);
    }

    /**
     * @description
     * Queues the given job for processing.
     *
     * @param asyncObject The job to be queued for processing.
     *
     * @return True if the job was queued, false if not.
     */
    public static Boolean queueJob(final AsynchronousJob__c asyncObject) {
        return INSTANCE.apiQueueJob(asyncObject);
    }

    /**
     * @description
     * Called if an Apex job could not be started in the request it was queued in.
     *
     * The most likely reason the job could not be started is exceeding the Apex job chaining limit.
     *
     * @param asyncObjectId The id of the AsynchronousJob__c to be started.
     */
    @Future
    private static void startAsynchronousJob(final String asyncObjectId) {
        Assertion.isNotNull(asyncObjectId, 'argument: AsynchronousHelper.startAsynchronousJob.asyncObjectId');
        final AsynchronousJob__c asyncObject = AsynchronousDAO.getObject(asyncObjectId);

        try {
            enqueueApexJob(asyncObject, true);
        } catch(Exception exc) {
            AsynchronousHelper.recordInternalException(asyncObject, exc);
        }
    }

    /**
     * @description
     * Creates an Apex job for the given Asynchronous object.
     *
     * The concurrency for the Runnable associated with job is checked against the number of RUNNING jobs of the
     * same type. If the concurrency would be exceeded by starting a new job, no job is started.
     *
     * If the job is not started due to concurrency being hit, it is not persisted. This logic is important to
     * maintain for the Scheduler. Any new Scheduler jobs that could not be started due to concurrency will not
     * have their Asynchronous__c object persisted and so will not be re-run later.
     *
     * @param asyncObject The job to be started.
     * @param isFuture Is the method being called as a result of a @future call.
     *
     * @return True if the Apex job was created, false if not.
     */
    private static Boolean enqueueApexJob(final AsynchronousJob__c asyncObject, final Boolean isFuture) {
        Assertion.isNotNull(asyncObject, 'argument: AsynchronousHelper.enqueueApexJob.asyncObject');
        Assertion.isNotNull(isFuture, 'argument: AsynchronousHelper.enqueueApexJob.isFuture');

        final AsynchronousJob asyncJob = (AsynchronousJob) AsynchronousJob.fromSObject(asyncObject);
        final AsynchronousRunnable runnable = (AsynchronousRunnable) asyncJob.getRunnable();

        if (isFuture || AsynchronousDAO.countActiveObjects(asyncObject) < runnable.getMaximumActive()) {
            asyncObject.Status__c = Asynchronous.Status.RUNNING.name();
            asyncObject.LastRunTime__c = Datetime.now();
            AsynchronousDAO.persistObjects(new List<AsynchronousJob__c> { asyncObject });

            asyncObject.ApexJobId__c = System.enqueueJob(
                    runnable.forJob(AsynchronousJob.fromSObject(AsynchronousDAO.getObject(asyncObject.Id)))
            );

            AsynchronousDAO.persistObjects(new List<AsynchronousJob__c> { asyncObject });

            return true;

        } else if (runnable instanceof AsynchronousScheduler) {
            return false;

        } else {
            asyncObject.ScheduledRunTime__c = Datetime.now().addSeconds(5);
            asyncObject.Status__c = Asynchronous.Status.QUEUED.name();
            AsynchronousDAO.persistObjects(new List<AsynchronousJob__c> { asyncObject });
            return false;

        }
    }

    /**
     * @description
     * Active API instance.
     *
     * The instance is test visible so it can be mocked.
     */
    @TestVisible
    private static API INSTANCE {
        private get {
            if (INSTANCE == null) {
                INSTANCE = new AsynchronousHelper();
            }
            return INSTANCE;
        }
        private set;
    }
}