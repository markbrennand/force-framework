/**
 * @description
 * <p>
 * Class providing a mockable implementation of the Asynchronous Helper.
 * <p>
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../LICENSE target="_blank">MIT License</a>.
 * 
 * @author Mark Brennand
 */
@SuppressWarnings('PMD.ApexDoc')
public with sharing virtual class AsynchronousHelperMockable implements AsynchronousHelper.API {

    public void recordException(final AsynchronousJob__c asyncObject, final AsynchronousV1.APIException exc) {
        throw new AsynchronousV1.APIException('Access denied');
    }

    public void recordInternalException(final AsynchronousJob__c asyncObject, final AsynchronousV1.APIException exc) {
        throw new AsynchronousV1.APIException('Access denied');
    }

    public Map<String, String> decodeState(final List<AsynchronousJobState__c> asyncStateObjects) {
        throw new AsynchronousV1.APIException('Access denied');
    }

    public List<AsynchronousJobState__c> encodeState(
            final AsynchronousJob__c asyncObject,
            final Map<String, String> state
    ) {
        throw new AsynchronousV1.APIException('Access denied');
    }

    public void queueJob(final AsynchronousJob__c asyncObject) {
        throw new AsynchronousV1.APIException('Access denied');
    }

}