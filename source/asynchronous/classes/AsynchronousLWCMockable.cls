/**
 * @description
 * <p>
 *
 * <p>
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../LICENSE target="_blank">MIT License</a>.
 * 
 * @author Mark Brennand
 */
public with sharing virtual class AsynchronousLWCMockable implements AsynchronousLWC.API {

    public List<Map<String, Object>> getJobs(final Map<String, Object> filters, final String ordering, final Integer offset, final Integer max) {
        throw new AsynchronousV1.APIException('Access denied');
    }

    public void deleteJobs(final List<Id> jobIds) {
        throw new AsynchronousV1.APIException('Access denied');
    }

    public void runJobs(final List<Id> jobIds) {
        throw new AsynchronousV1.APIException('Access denied');
    }

    public Map<String, Integer> getTotals() {
        throw new AsynchronousV1.APIException('Access denied');
    }
}