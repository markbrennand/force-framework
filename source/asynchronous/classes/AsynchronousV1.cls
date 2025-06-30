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
 * The DAO interface defines the SOQL and DML actions performed by the default Asynchronous API implementation.
 * It may be overridden using a Dependency Injection Binding to use a bespoke implementation.
 * <br><br>
 * See <a href=../README.md target="_blank">README</a> for full details of the Asynchronous API.
 *
 * @author Mark Brennand
 */
global with sharing virtual class AsynchronousV1 {

    /**
     * @description
     * Implementation of Runnable that classes may extend to make coding the logic of a job simpler.
     * <br><br>
     * Default implementations of all the methods are coded in this class. They may be overridden.
     * <br><br>
     * The Asynchronous.ApexJobRunnable.run() method will need to be implemented to code the logic for the job.
     * <br><br>
     * Classes extending this class must have a no-op constructor which calls the constructor for this class with
     * the Type of the extending class.
     */
    global with sharing abstract class Runnable extends Asynchronous.ApexJobRunnable {

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
        global virtual Boolean onSuccess(final Asynchronous.Job asyncJob) {
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
        global virtual Boolean onFailure(final Asynchronous.Job asyncJob, final Exception exc) {
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
        global virtual Boolean onCancellation(final Asynchronous.Job asyncJob) {
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
        global virtual Asynchronous.Status onError(final Asynchronous.Job asyncJob, final Exception exc) {
            return Asynchronous.Status.QUEUED;
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
    global static Asynchronous.Job createJob(
            final Type type,
            final String reference,
            final Integer maximumRetries,
            final Integer retryInterval,
            final Map<String, String> state
    ) {
        if (! (TypesV1.newInstance(type) instanceof AsynchronousV1.Runnable)) {
            throw new Asynchronous.APIException('Class ' + type.getName() + ' does not extend AsynchronousV1.Runnable');
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
    global static List<Asynchronous.Job> queueJobs(final List<Asynchronous.Job> asyncJobs) {
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
    public static List<Map<String, Object>> getJobs(final Map<String, Object> filters, String ordering, Integer offset, Integer max) {
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