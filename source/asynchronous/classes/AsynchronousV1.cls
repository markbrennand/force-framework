/**
 * @description
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../../LICENSE target="_blank">MIT License</a>.
 * <br><br>
 * Class defining the services offered by the Asynchronous API.
 * <br><br>
 * All access to the API must be through this class.
 * <br><br>
 * Asynchronous jobs should first be created using the createJob method. They can then be run by calling the
 * queueJobs method.
 * <br><br>
 * See <a href=../README.md target="_blank">README</a> for full details of the Asynchronous API.
 *
 * @author Mark Brennand
 */
@SuppressWarnings('PMD.AvoidGlobalModifier')
global with sharing virtual class AsynchronousV1 {

    /**
     * @description
     * Exception thrown when an operation in the Asynchronous API fails.
     */
    global with sharing class APIException extends Exception {}

    /**
     * @description
     * Defines the status of an AsynchronousJob__c object under the control of this framework.
     * <br><br>
     * A job can only be in a single state at any one time.
     * <br><br>
     * PENDING - The job has been created but a job has not been queued for it.
     * <br><br>
     * QUEUED - The job has been queued for processing.
     * <br><br>
     * RUNNING - The job is running.
     * <br><br>
     * SUCCEEDED - The job ran to completion successfully.
     * <br><br>
     * FAILED - The last job failed to run and the maximum number of retries has been exceeded.
     * <br><br>
     * CANCELLED - The job has been cancelled.
     */
    global enum Status {
        PENDING,
        QUEUED,
        RUNNING,
        SUCCEEDED,
        FAILED,
        CANCELLED
    }

    /**
     * @description
     * Information about a job being managed by the framework.
     * <br><br>
     * The implementation will be specific to the API implementation.
     */
    global interface Job {

        /**
         * @description
         * Return the current status of the job managed by the API implementation.
         *
         * @return The jobs's status.
         */
        Status getStatus();

        /**
         * @description
         * Returns the id of the user the job is being run for by the API implementation.
         *
         * @return The user id.
         */
        String getOwnerId();

        /**
         * @description
         * Returns the Runnable implementation for ths job managed by the API implementation.
         *
         * @return The Runnable implementation.
         */
        RunnableJob getRunnable();

        /**
         * @description
         * Returns the state information assigned to the job on creation by the API implementation.
         * <br><br>
         * The state may be updated by the call to Runnable.run for the job, though only when no Exception is thrown
         * by the method.
         *
         * @return The job's state.
         */
        Map<String, String> getState();

        /**
         * @description
         * Sets a new state for the job managed by the API implementation
         * <br><br>
         * New state will only be preserved if the Apex request it is set within does not throw an Exception.
         *
         * @param state The new state.
         */
        void setState(final Map<String, String> state);

        /**
         * @description
         * Returns the user's reference assigned to the job on creation by the API implementation.
         *
         * @return The reference.
         */
        String getReference();

        /**
         * @description
         * Returns the maximum number of re-tries to be made to process the job by the API implementation if it fails
         * to run.
         * <br><br>
         * Each re-try will be made if the Runnable.run method throws an Exception.
         *
         * @return The maximum number.
         */
        Integer getMaximumRetries();

        /**
         * @description
         * The current number of re-tries made by the API implementation for the job.
         * <br><br>
         * Re-try number 0 is the first attempt to run it.
         *
         * @return The current re-try number.
         */
        Integer getRetryNumber();

        /**
         * @description
         * Returns the number of re-tries that are remaining to be made by the API implementation for the job.
         *
         * @return Number of re-tries remaining.
         */
        Integer getRetriesRemaining();

        /**
         * @description
         * Returns the number of milliseconds that the implementation of the API will wait between re-try attempts.
         *
         * @return The number of milliseconds.
         */
        Integer getRetryInterval();

        /**
         * @description
         * Returns the date and time at which the API implementation is next scheduled to run the job.
         *
         * @return The date and time.
         */
        Datetime getScheduledRunTime();

        /**
         * @description
         * Returns the date and time at which the API implementation last run the job.
         *
         * @return The date and time.
         */
        Datetime getLastRunTime();
    }


    /**
     * @description
     * Interface defining the logic specific to a job run by the framework.
     * <br><br>
     * When the job is run by the framework, the job specific implementation of this interface is created and
     * its run method is called. As a new Runnable instance is created each time the job is run, implementations
     * of this interface cannot preserve state in member variables. The Job's state can be used for that.
     * <br><br>
     * Concurrency is controlled by the maximum active value. Any implementation of the API must guarantee that
     * no more than this number of instances of the Runnable may be active at any one time.
     * <br><br>
     * The AsynchronousRunnable class provides a full implementation of this interface. If possible you should
     * use this class and only override the methods you need behaviour other than the default for.
     */
    global interface RunnableJob {

        /**
         * @description
         * The class of the RunnableJob's implementation.
         * <br><br>
         * The class can either be a Runnable or Types.Factory implementation. In the case of the latter,
         * the class returned by the newInstance method must implement Runnable.
         *
         * @return The Apex class of the RunnableJob implementation.
         */
        Type getType();

        /**
         * @description
         * Concurrency is controlled by the RunnableJob's implementation.
         * <br><br>
         * The maximum active value defines how many instances of the RunnableJob's implementation may be active
         * concurrently. Any implementation of the API interface must guarantee that this value is enforced.
         *
         * @return The maximum number of active instances.
         */
        Integer getMaximumActive();

        /**
         * @description
         * Called when the job is run by the framework.
         * <br><br>
         * Any job specific data set in the state when the job was created can be accessed from the state in the job
         * argument.
         *
         * @param asyncJob The job being run.
         * @param apexJobId The Id of the Apex job for the RunnableJob.
         */
        void run(final Job asyncJob, final String apexJobId);

        /**
         * @description
         * Called when a job has run to completion successfully in the framework.
         * <br><br>
         * The return value indicates whether the API implementation is to keep a record of the job or delete it.
         *
         * @param asyncJob The job that ran to completion.
         *
         * @return Whether to delete a record of the job or not.
         */
        Boolean onSuccess(final Job asyncJob);

        /**
         * @description
         * Called when a job has failed to run and all is re-tries have been exhausted.
         * <br><br>
         * The return value indicates whether the API implementation is to keep a record of the job or delete it.
         *
         * @param asyncJob The job that failed.
         * @param exc The Exception that caused the job to fail on its last execution.
         *
         * @return Whether to delete a record of the job or not.
         */
        Boolean onFailure(final Job asyncJob, final Exception exc);

        /**
         * @description
         * Called when a job has been cancelled.
         * <br><br>
         * The return value indicates whether the API implementation is to keep a record of the job or delete it.
         *
         * @param asyncJob The job that has been cancelled.
         *
         * @return Whether to delete a record of the job or not.
         */
        Boolean onCancellation(final Job asyncJob);

        /**
         * @description
         * An API implementation must call this method each time an Exception is caught when running a job.
         * <br><br>
         * The Exception will be thrown from the RunnableJob.run method. A Status of QUEUED should be returned in
         * most circumstances to re-try the job. Say, for example though, that a particular type of Exception was
         * thrown that meant the job would always fail, a Status of CANCELLED could be returned to indicate no
         * further re-tries are to be performed.
         * <br><br>
         * The return value indicates new Status value to assign to the job.
         *
         * @param asyncJob The job that has been cancelled.
         * @param exc The exception caught by the framework whilst running the job.
         *
         * @return The new Status of the job.
         */
        Status onError(final Job asyncJob, final Exception exc);
    }

    /**
     * @description
     * Implementation of RunnableJob that classes may extend to make coding the logic of a job simpler.
     * <br><br>
     * Default implementations of all the methods are coded in this class. They may be overridden.
     * <br><br>
     * The Asynchronous.ApexJobRunnable.run() method will need to be implemented to code the logic for the job.
     * <br><br>
     * Classes extending this class must have a no-op constructor which calls the constructor for this class with
     * the Type of the extending class.
     */
    global with sharing abstract class Runnable extends AsynchronousAPI.ApexJobRunnable {

        /**
         * @description
         * Constructs an instance of the class which is a proxy for the sub-class to be run.
         *
         * @param type The sub-class to be run.
         */
        global Runnable(final Type type) {
            super(type);
        }

        /**
         * @description
         * Returns the maximum number of concurrent executions of the Runnable that are allowed.
         * <br><br>
         * If the concurrency is exceeded, a job will not be started.
         *
         * @return Maximum concurrent executions.
         */
        global virtual Integer getMaximumActive() {
            return 1;
        }

        /**
         * @description
         * Called on successful completion of the Asynchronous__c object for the class.
         * <br><br>
         * To succeed, the class's run method must not have thrown an Exception when called.
         *
         * @param asyncJob The job that has succeeded.
         *
         * @return True if the Asynchronous__c object is to be kept, false if not.
         */
        global virtual Boolean onSuccess(final Job asyncJob) {
            return true;
        }

        /**
         * @description
         * Called on failure to run the job after exhausting the Asynchronous__c object's re-tries.
         * <br><br>
         * To fail, the class's run method must have thrown an Exception every time it was called.
         *
         * @param asyncJob The job that has failed.
         * @param exc The Exception that caused the last re-try for the job to fail.
         *
         * @return True if the Asynchronous__c object is to be kept, false if not.
         */
        global virtual Boolean onFailure(final Job asyncJob, final Exception exc) {
            return true;
        }

        /**
         * @description
         * Called when an Asynchronous__c object has its status changed to CANCELLED.
         *
         * @param asyncJob The job that has been cancelled.
         *
         * @return True if the Asynchronous__c object is to be kept, false if not.
         */
        global virtual Boolean onCancellation(final Job asyncJob) {
            return true;
        }

        /**
         * @description
         * Called when an Exception occurs during the running of an Asynchronous__c object and there are re-tries left to
         * be made.
         * <br><br>
         * The status value returned by this method determines what happens to the job. Return QUEUED to re-try the
         * job. Return CANCELLED if the job is not to be re-tried and no further processing of it is to be made. The
         * onCancellation method of this class will be called.
         *
         * @param asyncJob The job the Exception was thrown for.
         * @param exc The Exception that was thrown.
         *
         * @return The new status for the job.
         */
        global virtual Status onError(final Job asyncJob, final Exception exc) {
            return Status.QUEUED;
        }
    }

    /**
     * @description
     * Creates a new instance of a job to be managed by the injected API implementation.
     * <br><br>
     * The Apex class must implement the Runnable interface. If it doesn't, the implementation will throw an
     * exception.
     * <br><br>
     * The state is data specific to the job. It is passed to the Runnable for the job when it is invoked. It
     * can contain any data an application chooses. For example, it may include arguments specific to the job.
     *
     * @param type The Apex class of the job to be run.
     * @param reference The user's reference for the job.
     * @param maximumRetries The maximum number of retries to make before failing the job.
     * @param retryInterval The number of milliseconds between each re-try event.
     * @param state Job specific data.
     *
     * @return The job.
     */
    global static Job createJob(
            final Type type,
            final String reference,
            final Integer maximumRetries,
            final Integer retryInterval,
            final Map<String, String> state
    ) {
        if (! (TypesV1.newInstance(type) instanceof Runnable)) {
            throw new APIException('Class ' + type.getName() + ' does not extend AsynchronousV1.Runnable');
        }

        return AsynchronousAPI.API.createJob(type, reference, maximumRetries, retryInterval, state);
    }

    /**
     * @description
     * Schedules the given job for processing by the injected API implementation.
     *
     * @param asyncJobs The jobs to schedule for processing.
     *
     * @return The jobs queued for processing.
     */
    global static List<Job> queueJobs(final List<Job> asyncJobs) {
        return AsynchronousAPI.API.queueJobs(asyncJobs);
    }

    /**
     * @description
     * Returns a List of the AsynchronousJob__c objects matching the filter criteria.
     *
     * @param filters Query filters to be applied.
     * @param ordering The ordering to apply to the results.
     * @param offset The record to return results from.
     * @param max  The maximum number of records to return.
     *
     * @return A list of the matching objects.
     */
    @AuraEnabled(Cacheable=false)
    public static List<Map<String, Object>> getJobs(
            final Map<String, Object> filters,
            final String ordering,
            final Integer offset,
            final Integer max
    ) {
        return AsynchronousLWC.API.getJobs(filters, ordering, offset, max);
    }

    /**
     * @description
     * Deletes the given AsynchronousJob__c records.
     *
     * @param jobIds The ids of the jobs to delete.
     */
    @AuraEnabled(Cacheable=false)
    public static void deleteJobs(final List<Id> jobIds) {
        AsynchronousLWC.API.deleteJobs(jobIds);
    }

    /**
     * @description
     * Re-runs the given AsynchronousJob__c records.
     *
     * @param jobIds The ids of the jobs to re-run.
     */
    @AuraEnabled(Cacheable=false)
    public static void runJobs(final List<Id> jobIds) {
        AsynchronousLWC.API.runJobs(jobIds);
    }

    /**
     * @description
     * Calculates the total number of objects per status for the current user.
     *
     * @return The totals.
     */
    @AuraEnabled(Cacheable=false)
    public static Map<String, Integer> getTotals() {
        return AsynchronousLWC.API.getTotals();
    }
}