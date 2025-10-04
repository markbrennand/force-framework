/**
 * @description
 * <p>
 * Class providing the default implementation of the Asynchronous LWC API.
 * <p>
 * The implementation of the API is hidden in the private Implementation class. The class is hidden so an application
 * cannot access the class to mis-use it.
 * <p>
 * All application access is restricted to the API instance variable API. This ensures the application can only
 * ever call the methods of the API interface.
 * <p>
 * The outer class implements the API only to allow it to be mocked. Any calls to the API method implementations
 * in the outer class will throw an Exception.
 * <p>
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../LICENSE target="_blank">MIT License</a>.
 *
 * @author Mark Brennand
 */
public with sharing virtual class AsynchronousLWC extends AsynchronousLWCMockable {

    /**
     * @description
     * <p>
     * Active LWC instance.
     * <p>
     * The instance is injected from the Registry. As the instance is injected, a development version of the
     * interface could be used to provide data to the LWC during development. This would allow the LWC to be
     * developed in isolation from the real implementation being developed.
     * <p>
     * The instance is test visible so it can be mocked.
     */
    public static API impl {
        public get {
            if (Test.isRunningTest() && impl != null) { // API has been mocked.
                return impl;
            } else {
                return (API) DependencyV1.inject(API.class);
            }
        }
        private set;
    }

    /**
     * @description
     * <p>
     * Interface defining the calls that may be made from the Asynchronous Job LWC.
     */
    public interface API {

        /**
         * @description
         * <p>
         * Returns a List of the AsynchronousJob__c objects matching the filter criteria.
         *
         * @param filters Query filters to be applied.
         * @param ordering The order to return the results in.
         * @param offset The record to return results from.
         * @param max  The maximum number of records to return.
         *
         * @return A list of the matching objects.
         */
        List<Map<String, Object>> getJobs(final Map<String, Object> filters, final String ordering, final Integer offset, final Integer max);

        /**
         * @description
         * <p>
         * Deletes the given AsynchronousJob__c records.
         *
         * @param jobIds The ids of the jobs to delete.
         */
        void deleteJobs(final List<Id> jobIds);

        /**
         * @description
         * <p>
         * Re-runs the given AsynchronousJob__c records.
         *
         * @param jobIds The ids of the jobs to re-run.
         */
        void runJobs(final List<Id> jobIds);

        /**
         * @description
         * <p>
         * Calculates the total number of objects per status for the current user.
         *
         * @return The totals.
         */
        Map<String, Integer> getTotals();
    }

    /**
     * @description
     * <p>
     * Allow extension but not construction.
     * <p>
     * This is also required to support the Apex mocking classes. A private constructor cannot be mocked.
     */
    @SuppressWarnings('PMD.EmptyStatementBlock')
    protected AsynchronousLWC() {}

    // Set the default implementations of API and LWC. This can be overridden using a Dependency Injection Binding.
    static {
        DependencyV1.bind(API.class, AsynchronousLWCImpl.Factory.class);
    }
}