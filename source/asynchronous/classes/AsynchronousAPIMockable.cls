/**
 * @description
 * <p>
 * Class providing a mockable implementation of the Asynchronous API.
 * <p>
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../LICENSE target="_blank">MIT License</a>.
 * 
 * @author Mark Brennand
 */
@SuppressWarnings('PMD.ApexDoc')
public with sharing virtual class AsynchronousAPIMockable implements AsynchronousAPI.API {

    public AsynchronousV1.Job createJob(
            final Type type,
            final String reference,
            final Integer maximumRetries,
            final Integer retryInterval,
            final Map<String, String> state
    ) {
        throw new AsynchronousV1.APIException('Access denied');
    }
    public List<AsynchronousV1.Job> queueJobs(final List<AsynchronousV1.Job> asyncJobs) {
        throw new AsynchronousV1.APIException('Access denied');
    }
}