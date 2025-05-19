/**
 * @description
 * Class containing helper methods for the Asynchronous framework.
 *
 * @author Mark Brennand
 */
public with sharing class AsynchronousHelper {

    /**
     * @description
     * Maximum amount of data that can be stored in a chunk.
     */
    @TestVisible
    private static Integer MAX_CHUNK_SIZE = 131072;

    /**
     * @description
     * Records the detail of an Exception in an Asynchronous Error object.
     *
     * A new record is created and persisted for each Exception recorded.
     *
     * @param asyncObject The asynchronous object to record the Exception against.
     * @param exc The exception to be recorded.
     */
    public static void recordException(final Asynchronous__c asyncObject, final Exception exc) {
        Assert.isNotNull(asyncObject, 'parameter; AsynchronousHelper.recordException.asynchronousObject');
        Assert.isNotNull(exc, 'parameter; AsynchronousHelper.recordException.exc');

        final AsynchronousError__c asyncError = new AsynchronousError__c(
                Asynchronous__c = asyncObject.Id,
                StatusOnError__c = asyncObject.Status__c,
                ExceptionType__c = exc.getTypeName(),
                ExceptionMessage__c = exc.getMessage(),
                ExceptionStackTrace__c = exc.getStackTraceString()
        );

        AsynchronousDAO.persist(asyncError);
    }

    public static void internalFailure(final Asynchronous__c asyncObject, final Exception exc) {
        recordException(asyncObject, exc);
        asyncObject.Status__c = Asynchronous.Status.FAILED.name();
        AsynchronousDAO.persist(new List<Asynchronous__c> { asyncObject });
    }

    public static Map<String, String> decodeState(final List<AsynchronousState__c> asyncStateObjects) {
        Assert.isNotNull(asyncStateObjects, 'parameter; AsynchronousHelper.decodeState.asyncStateObjects');

        final List<String> chunks = new List<String>();

        for (AsynchronousState__c chunk : asyncStateObjects) {
            chunks.add(chunk.Content__c);
        }

        Assert.isFalse(chunks.isEmpty(), 'No asynchronous state chunks found for job');

        return (Map<String, String>) JSON.deserialize(String.join(chunks, ''), Map<String, String>.class);
    }

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