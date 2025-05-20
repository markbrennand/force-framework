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

    public interface API {

        /**
         * @description
         * Records the detail of an Exception.
         *
         * @param asyncObject The Asynchronous object to record the Exception against.
         * @param exc The exception to be recorded.
         */
        void apiRecordException(Asynchronous__c asyncObject, Exception exc);

        /**
         * @description
         * Records a new internal Exception encountered in the framework.
         *
         * @param asyncObject The Asynchronous object to record the Exception against.
         * @param exc The exception to be recorded.
         */
        void apiRecordInternalFailure(Asynchronous__c asyncObject, Exception exc);

        /**
         * @description
         * Given the state retrieved from backing store, turns it into the internal representation.
         *
         * @param asyncStateObjects The state objects.
         *
         * @return The decoded state.
         */
        Map<String, String> apiDecodeState(final List<AsynchronousState__c> asyncStateObjects);

        /**
         * @description
         * Given the internal state, turns it into a series of state objects representing it.
         *
         * @param asyncObject The Asynchronous object the state will be stored against.
         * @param state The internal state.
         *
         * @return The state objects representing the internal state.
         */
        List<AsynchronousState__c> apiEncodeState(Asynchronous__c asyncObject, Map<String, String> state);
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
     * @param exc The exception to be recorded.
     */
    public void apiRecordException(final Asynchronous__c asyncObject, final Exception exc) {
        Assert.isNotNull(asyncObject, 'parameter; AsynchronousHelper.apiRecordException.asynchronousObject');
        Assert.isNotNull(exc, 'parameter; AsynchronousHelper.apiRecordException.exc');

        final AsynchronousException__c asyncError = new AsynchronousException__c(
                Asynchronous__c = asyncObject.Id,
                RetryNumber__c = asyncObject.RetryNumber__c,
                StatusOnError__c = asyncObject.Status__c,
                ExceptionType__c = exc.getTypeName(),
                ExceptionMessage__c = exc.getMessage(),
                ExceptionStackTrace__c = exc.getStackTraceString()
        );

        AsynchronousDAO.persistAsynchronousError(asyncError);
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
     * @param exc The exception to be recorded.
     */
    public void apiRecordInternalFailure(final Asynchronous__c asyncObject, final Exception exc) {
        apiRecordException(asyncObject, exc);
        asyncObject.Status__c = Asynchronous.Status.FAILED.name();
        AsynchronousDAO.persistAsynchronous(new List<Asynchronous__c> { asyncObject });
    }

    /**
     * @description
     * Given the state objects retrieved from backing store, turns them into their internal representation.
     *
     * @param asyncStateObjects The state objects.
     *
     * @return The decoded state.
     */
    public Map<String, String> apiDecodeState(final List<AsynchronousState__c> asyncStateObjects) {
        Assert.isNotNull(asyncStateObjects, 'parameter; AsynchronousHelper.apiDecodeState.asyncStateObjects');

        final List<String> chunks = new List<String>();

        for (AsynchronousState__c chunk : asyncStateObjects) {
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
    public static List<AsynchronousState__c> apiEncodeState(
            final Asynchronous__c asyncObject,
            final Map<String, String> state
    ) {
        Assert.isNotNull(asyncObject, 'parameter; AsynchronousHelper.apiEncodeState.asyncObject');
        Assert.isNotNull(state, 'parameter; AsynchronousHelper.apiEncodeState.state');

        final List<AsynchronousState__c> chunks = new List<AsynchronousState__c>();
        String stateJson = JSON.serialize(state);
        Integer size = stateJson.length();
        Integer chunkNumber = 0;

        while (size > MAX_CHUNK_SIZE) {
            chunks.add(new AsynchronousState__c(
                    Asynchronous__c = asyncObject.Id,
                    ChunkNumber__c = ++chunkNumber,
                    Content__c = stateJSON.substring(0, MAX_CHUNK_SIZE)
            ));

            stateJson = stateJson.substring(MAX_CHUNK_SIZE);
            size -= MAX_CHUNK_SIZE;
        }

        if (size > 0) {
            chunks.add(new AsynchronousState__c(
                    Asynchronous__c = asyncObject.Id,
                    ChunkNumber__c = ++chunkNumber,
                    Content__c = stateJSON
            ));
        }

        return chunks;
    }

    /**
     * @description
     * Records the detail of an Exception.
     *
     * @param asyncObject The Asynchronous object to record the Exception against.
     * @param exc The exception to be recorded.
     */
    public static void recordException(final Asynchronous__c asyncObject, final Exception exc) {
        INSTANCE.apiRecordException(asyncObject, exc);
    }

    /**
     * @description
     * Records a new internal error encountered in the framework.
     *
     * @param asyncObject The Asynchronous object to record the Exception against.
     * @param exc The exception to be recorded.
     */
    public static void recordInternalException(final Asynchronous__c asyncObject, final Exception exc) {
        INSTANCE.apiRecordInternalFailure(asyncObject, exc);
    }

    /**
     * @description
     * Given the state objects retrieved from backing store, turns them into their internal representation.
     *
     * @param asyncStateObjects The state objects.
     *
     * @return The decoded state.
     */
    public static Map<String, String> decodeState(final List<AsynchronousState__c> asyncStateObjects) {
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
    public static List<AsynchronousState__c> encodeState(
            final Asynchronous__c asyncObject,
            final Map<String, String> state
    ) {
        return INSTANCE.apiEncodeState(asyncObject, state);
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