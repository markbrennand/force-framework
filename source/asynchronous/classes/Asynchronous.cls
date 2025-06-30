/**
 * @description
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../../LICENSE target="_blank">MIT License</a>.
 * <br><br>
 * Class defining the Asynchronous APIs.
 * <br><br>
 * The API interface defines the contract that implementations must provide to the methods of this class to create
 * and run jobs asynchronously. The implementation may be overridden using a Dependency Injection Binding to use
 * a bespoke implementation.
 * <br><br>
 * See <a href=../README.md target="_blank">README</a> for full details of the Asynchronous API.
 *
 * @author Mark Brennand
 */
global with sharing class Asynchronous {

    /**
     * @description
     * Exception thrown when an operation in the Asynchronous framework fails.
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
        Runnable getRunnable();

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
        void setState(Map<String, String> state);

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
    global interface Runnable {

        /**
         * @description
         * The class of the Runnable's implementation.
         * <br><br>
         * The class can either be a Runnable or Types.Factory implementation. In the case of the latter,
         * the class returned by the newInstance method must implement Runnable.
         *
         * @return The Apex class of the Runnable implementation.
         */
        Type getType();

        /**
         * @description
         * Concurrency is controlled by the Runnable's implementation.
         * <br><br>
         * The maximum active value defines how many instances of the Runnable's implementation may be active
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
         * @param apexJobId The Id of the Apex job for the Runnable.
         */
        void run(Job asyncJob, String apexJobId);

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
        Boolean onSuccess(Job asyncJob);

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
        Boolean onFailure(Job asyncJob, Exception exc);

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
        Boolean onCancellation(Job asyncJob);

        /**
         * @description
         * An API implementation must call this method each time an Exception is caught when running a job.
         * <br><br>
         * The Exception will be thrown from the Runnable.run method. A Status of QUEUED should be returned in
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
        Status onError(Job asyncJob, Exception exc);
    }


    /**
     * @description
     * Interface defining the SOQL and DML operations.
     */
    global interface DAO {

        /**
         * @description
         * Given the Id of an object, the object is retrieved.
         *
         * @param asyncObjectId The Id of the object to retrieve.
         *
         * @return The object.
         */
        AsynchronousJob__c getObject(Id asyncObjectId);

        /**
         * @description
         * Builds a List of the objects that are scheduled to run.
         * <br><br>
         * The List returned must be ordered chronologically, with the first entry being the job that has been
         * waiting the longest to run.
         *
         * @param maxJobsToReturn The maximum number of objects to return.
         *
         * @return The objects.
         */
        Set<AsynchronousJob__c> getScheduledObjects(Integer maxJobsToReturn);

        /**
         * @description
         * Determines the number os objects that remain to be run.
         * <br><br>
         * The remaining objects must includes all those that are in QUEUED or RUNNING state. The RUNNING must
         * be included as their job may fail and they will be scheduled to re-run if they have re-tries left.
         *
         * @return The number of objects that are scheduled or are running.
         */
        Integer countSchedulableObjects();

        /**
         * @description
         * Determines the number of active instances of the given object.
         * <br><br>
         * The Runnable in for the object determines the number of active instances.
         *
         * @param asyncObject The object to have its concurrency determined.
         *
         * @return The concurrency for the object.
         */
        Integer countActiveObjects(final AsynchronousJob__c asyncObject);

        /**
         * @description
         * Inserts or updates the given objects.
         *
         * @param asyncObjects The objects to persist.
         */
        void persistObjects(List<AsynchronousJob__c> asyncObjects);

        /**
         * @description
         * Inserts or updates the given objects and states.
         * <br><br>
         * The objects must be persisted first and then each state linked to its associated object before
         * persisting.
         *
         * @param asyncObjects The objects to persist.
         * @param states The states to persist.
         */
        void persistObjects(List<AsynchronousJob__c> asyncObjects, List<Map<String, String>> states);

        /**
         * @description
         * Deletes the given objects.
         *
         * @param asyncObjects The objects to remove.
         */
        void removeObjects(List<AsynchronousJob__c> asyncObjects);

        /**
         * @description
         * Inserts the given exception object.
         *
         * @param asyncErrorObject The exception object to persist.
         */
        void persistException(AsynchronousJobException__c asyncErrorObject);
    }

    /**
     * @description
     * Interface defining the actions required for Asynchronous job management.
     * <br><br>
     * A new implementation of the Asynchronous framework must implement all the methods of this
     * interface. It can then add a Dependency Injection Binding and it will be injected in the
     * static methods of this class which provide the application access to create and queue jobs.
     * <br><br>
     * Any new implementations must also use their own implementation of the Job interface.
     */
    public interface API {

        /**
         * @description
         * Creates a new instance of a job to be managed by the framework.
         * <br><br>
         * The Apex class must implement the Runnable interface. If it doesn't, the implementation must throw an
         * exception.
         * <br><br>
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
        Job createJob(
                Type type,
                String reference,
                Integer maximumRetries,
                Integer retryInterval,
                Map<String, String> state
        );

        /**
         * @description
         * Schedules the given job for processing.
         * <br><br>
         * The implementation should consider the jobs as available to run and take the appropriate action.
         *
         * @param asyncJobs The jobs to schedule for processing.
         *
         * @return The jobs queued for processing.
         */
        List<Job> queueJobs(List<Job> asyncJobs);
    }

    /**
     * Interface defining the calls that may be made from the Asynchronous Job LWC.
     */
    public interface LWC {

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
        List<Map<String, Object>> getJobs(Map<String, Object> filters, String ordering, Integer offset, Integer max);

        /**
         * @description
         * Deletes the given AsynchronousJob__c records.
         *
         * @param jobIds The ids of the jobs to delete.
         */
        void deleteJobs(List<Id> jobIds);

        /**
         * @description
         * Re-runs the given AsynchronousJob__c records.
         *
         * @param jobIds The ids of the jobs to re-run.
         */
        void runJobs(List<Id> jobIds);

        /**
         * @description
         * Calculates the total number of objects per status for the current user.
         *
         * @return The totals.
         */
        Map<String, Integer> getTotals();
    }

    /**
     * Class called from Queueable for Apex Job.
     * <br><br>
     * Override the run method from a super-class to code the logic of the job.
     */
    global with sharing abstract class ApexJobRunnable implements Asynchronous.Runnable, Queueable {

        /**
         * @description
         * The sub-class of AsynchronousRunnable which is to be run for the Asynchronous__c object.
         */
        private final Type type;

        /**
         * @description
         * On execution, this field holds the Id of the Asynchronous__c object of the job being run.
         */
        @TestVisible
        private Asynchronous.Job asyncJob;

        /**
         * @description
         * Constructs an instance of the class which is a proxy for the sub-class to be run.
         *
         * @param type The sub-class to be run.
         */
        public ApexJobRunnable(final Type type) {
            this.type = type;
        }

        /**
         * @description
         * Called to execute the logic coded in the Runnable.
         * <br><br>
         * When the Asynchronous__c object is ready to run, an Apex job will be queued for it. When the Apex job reaches
         * the head of the run queue and is started, this method is called.
         * <br><br>
         * Any state changes made during the execution of the Runnable are preserved.
         * <br><br>
         * The run method must throw an Exception to indicate failure. If no Exception is thrown, the job will be
         * considered to have completed successfully.
         *
         * @param context The Salesforce context for the Apex job.
         */
        public void execute(final QueueableContext context) {
            final AsynchronousJob__c asynchronousJob = AsynchronousJob.toSObject(asyncJob);
            asynchronousJob.ApexJobId__c = context.getJobId();
            asynchronousJob.LastRunTime__c = Datetime.now();

            System.attachFinalizer(AsynchronousFinalizer.createFinalizer(asynchronousJob.Id));
            run(asyncJob, context.getJobId());

            AsynchronousDAO.API.persistObjects(
                    new List<AsynchronousJob__c>{
                            asynchronousJob
                    },
                    new List<Map<String, String>>{
                            asyncJob.getState()
                    }
            );
        }

        /**
         * @description
         * The class of the Runnable's implementation.
         * <br><br>
         * The class can either be a Runnable or Types.Factory implementation. In the case of the latter,
         * the class returned by the newInstance method must implement Runnable.
         *
         * @return The Apex class of the Runnable implementation.
         */
        public Type getType() {
            return type;
        }

        /**
         * @description
         * Method called when the Apex job is being run.
         * <br><br>
         * The method is called from the execute method of this class.
         * <br><br>
         * A developer must override this method and code the business logic the job needs to perform.
         * <br><br>
         * Ideally, this method would not be here as it should be considered abstract as its in the interface. The
         * Apex compiler has other ideas!
         *
         * @param asyncJob The job being run.
         * @param apexJobId The Id of the Apex job for the Runnable.
         */
        global abstract void run(final Asynchronous.Job asyncJob, final String apexJobId);

        /**
         * @description
         * Gets the Queueable to be run by an Apex job.
         *
         * @param asyncJob The Job representing the Asynchronous__c object being run.
         *
         * @return The Runnable to be run in an Apex job.
         */
        public Asynchronous.Runnable forJob(final Asynchronous.Job asyncJob) {
            this.asyncJob = asyncJob;
            return this;
        }
    }
}
