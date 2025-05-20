/**
 * @description
 * Class containing helper methods for the Asynchronous framework.
 *
 * The methods within are intended for the sole use of the framework.
 *
 * @author Mark Brennand
 */
public with sharing class AsynchronousHelper {

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
     * Records the detail of an Exception in an Asynchronous Exception object.
     *
     * A new record is created and persisted for each Exception recorded.
     *
     * @param asyncObject The Asynchronous object to record the Exception against.
     * @param exc The exception to be recorded.
     */
    public static void recordException(final Asynchronous__c asyncObject, final Exception exc) {
        Assert.isNotNull(asyncObject, 'parameter; AsynchronousHelper.recordException.asynchronousObject');
        Assert.isNotNull(exc, 'parameter; AsynchronousHelper.recordException.exc');

        final AsynchronousException__c asyncError = new AsynchronousException__c(
                Asynchronous__c = asyncObject.Id,
                RetryNumber__c = asyncObject.RetryNumber__c,
                StatusOnError__c = asyncObject.Status__c,
                ExceptionType__c = exc.getTypeName(),
                ExceptionMessage__c = exc.getMessage(),
                ExceptionStackTrace__c = exc.getStackTraceString()
        );

        AsynchronousDAO.persist(asyncError);
    }

    /**
     * @description
     * Records a new internal error encountered in the framework.
     *
     * Exceptions thrown from the Runnable for an Apex job are not recorded using this method.
     *
     * A new Asynchronous Exception is created to record the Exception and the Status of the Asynchronous job
     * is change to indicate it failed. No further processing will be performed on the job.
     *
     * @param asyncObject The Asynchronous object to record the Exception against.
     * @param exc The exception to be recorded.
     */
    public static void internalFailure(final Asynchronous__c asyncObject, final Exception exc) {
        recordException(asyncObject, exc);
        asyncObject.Status__c = Asynchronous.Status.FAILED.name();
        AsynchronousDAO.persist(new List<Asynchronous__c> { asyncObject });
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
        Assert.isNotNull(asyncStateObjects, 'parameter; AsynchronousHelper.decodeState.asyncStateObjects');

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
    public static List<AsynchronousState__c> encodeState(
            final Asynchronous__c asyncObject,
            final Map<String, String> state
    ) {
        Assert.isNotNull(asyncObject, 'parameter; AsynchronousHelper.encodeState.asyncObject');
        Assert.isNotNull(state, 'parameter; AsynchronousHelper.encodeState.state');

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
}