/**
 * @description
 * <p>
 * Class providing the default implementation of the Asynchronous API.
 * <p>
 * The default implementation of the API in this class uses the AsynchronousJob__c object to represent a job. The object
 * may be queried to find all the information about the job.
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
 * See <a href=../README.md target="_blank">README</a> for full details of the Asynchronous API.
 * <p>
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../LICENSE target="_blank">MIT License</a>.
 *
 * @author Mark Brennand
 */
public with sharing virtual class AsynchronousAPI extends AsynchronousAPIMockable {

    /**
     * @description
     * <p>
     * Active API instance.
     * <p>
     * The instance is injected from the Registry.
     * <p>
     * The instance is test visible so it can be mocked.
     */
    @TestVisible
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
     * Interface defining the actions required for Asynchronous job management.
     * <p>
     * A new implementation of the Asynchronous framework must implement all the methods of this
     * interface. It can then add a Dependency Injection Binding and it will be injected in the
     * static methods of this class which provide the application access to create and queue jobs.
     * <p>
     * Any new implementations must also use their own implementation of the Job interface.
     */
    public interface API {

        /**
         * @description
         * <p>
         * Creates a new instance of a job to be managed by the framework.
         * <p>
         * The Apex class must implement the Runnable interface. If it doesn't, the implementation must throw an
         * exception.
         * <p>
         * The state is data specific to the job. It is passed to the Runnable for the job when it is invoked. It
         * can contain any data an application chooses. For example, it may include arguments specific to the job.
         *
         * @param type The Apex class of the job to be run.
         * @param reference The user's reference for the job.
         * @param maximumRetries The maximum number of retries to make before failing the job.
         * @param retryInterval The number of milliseconds between each re-try after failure.
         * @param state Job specific data.
         *
         * @return The job specific to the implementation.
         */
        AsynchronousV1.Job createJob(
                final Type type,
                final String reference,
                final Integer maximumRetries,
                final Integer retryInterval,
                final Map<String, String> state
        );

        /**
         * @description
         * <p>
         * Schedules the given job for processing.
         * <p>
         * The implementation should consider the jobs as available to run and take the appropriate action.
         *
         * @param asyncJobs The jobs to schedule for processing.
         *
         * @return The jobs queued for processing.
         */
        List<AsynchronousV1.Job> queueJobs(final List<AsynchronousV1.Job> asyncJobs);
    }

    /**
     * @description
     * <p>
     * Allow extension but not construction.
     * <p>
     * This is also required to support the Apex mocking classes. A private constructor cannot be mocked.
     */
    @SuppressWarnings('PMD.EmptyStatementBlock')
    protected AsynchronousAPI() {}

    // Set the default implementation of API. This can be overridden using a Dependency Injection Binding.
    static {
        DependencyV1.bind(API.class, AsynchronousImpl.Factory.class);
    }
}
