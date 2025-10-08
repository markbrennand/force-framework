/**
 * @description
 * <p>
 * Class providing a mockable implementation of the Asynchronous DAO.
 * <p>
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../LICENSE target="_blank">MIT License</a>.
 * 
 * @author Mark Brennand
 */
@SuppressWarnings('PMD.ApexDoc')
public with sharing virtual class AsynchronousDAOMockable implements AsynchronousDAO.API {

    public AsynchronousJob__c getObject(final Id asyncObjectId) {
        throw new AsynchronousV1.APIException('Access denied');
    }

    public List<AsynchronousJob__c> getScheduledObjects(final Integer maxJobsToReturn) {
        throw new AsynchronousV1.APIException('Access denied');
    }

    public Integer countSchedulableObjects() {
        throw new AsynchronousV1.APIException('Access denied');
    }

    public Integer countActiveObjects(final AsynchronousJob__c asyncJob) {
        throw new AsynchronousV1.APIException('Access denied');
    }

    public void persistObjects(final List<AsynchronousJob__c> asyncObjects) {
        throw new AsynchronousV1.APIException('Access denied');
    }

    public void persistObjects(final List<AsynchronousJob__c> asyncObjects, final List<Map<String, String>> states) {
        throw new AsynchronousV1.APIException('Access denied');
    }

    public void removeObjects(final List<AsynchronousJob__c> asyncObjects) {
        throw new AsynchronousV1.APIException('Access denied');
    }

    public void persistException(final AsynchronousJobException__c asyncError) {
        throw new AsynchronousV1.APIException('Access denied');
    }
}