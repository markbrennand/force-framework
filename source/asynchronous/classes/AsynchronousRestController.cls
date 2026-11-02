/**
 * @description
 * <p>
 * Class providing the REST accessible services of the Asynchronous job framework.
 * <p>
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../LICENSE target="_blank">MIT License</a>.
 * 
 * @author Mark Brennand
 */
@RestResource(UrlMapping='/async/jobs/start')
global with sharing class AsynchronousRestController {

    /**
     * @description
     * Starts the job ids in the JSON of the body.
     *
     * @param ids The JSON encoded set of job ids to start.
     */
    @HttpPost
    global static void post(String ids) {
        final RestRequest request = RestContext.request;
        final RestResponse response = RestContext.response;

        try {
            final AsynchronousDAO.API dao = AsynchronousDAO.impl;
            final AsynchronousHelper.API helper = AsynchronousHelper.impl;
            final Set<Id> jobIds = (Set<Id>) JSON.deserialize(ids, Set<Id>.class);
            final List<AsynchronousJob__c> jobsToStart = dao.getObjects(jobIds);

            for (AsynchronousJob__c job : jobsToStart) {
                helper.queueJob(job);
            }

            response.statusCode = 200;

        } catch(Exception e) {
            response.responseBody = Blob.valueOf('Error: ' + e.getMessage());
            response.statusCode = 500;
        }
    }
}