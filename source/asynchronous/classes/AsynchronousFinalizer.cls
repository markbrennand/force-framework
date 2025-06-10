/**
 * @description
 * Finalizer called on completion of an Apex job.
 *
 * Success or failure of the job is determined from the context.
 *
 * If successful, the Asynchronous job's Runnable's onSuccess method will be called.
 *
 * If the job has failed, the job's Runnable's onError method will be called. The return value will indicate
 * whether processing of the job is to be continued.
 *
 * If processing is to be continued and the number of re-tries has been reached for the job, the job's Runnable's
 * on Failure method will be called.
 *
 * If the number of re-tries hasn't been reached, the job's Status is set to QUEUED and the re-try number is
 * incremented.
 *
 * If there are scheduled jobs left to process, a new Asynchronous scheduler is queued.
 *
 * @author Mark Brennand
 */
public with sharing class AsynchronousFinalizer {

    /**
     * @description
     * Set of job Ids that remain to be started.
     */
    public final static String JOBS_TO_START = 'JobsToStart';

    /**
     * @description
     * Factory method to create a new Finalizer.
     *
     * The implementation is hidden to prevent re-use outside the framework.
     *
     * @param asyncObjectId The id of the Asynchronous object.
     *
     * @return A new finalizer.
     */
    public static Finalizer createFinalizer(final Id asyncObjectId) {
        return new ApexFinalizer(asyncObjectId);
    }

    /**
     * @description
     * Finalizer for the Asynchronous framework.
     */
    private with sharing class ApexFinalizer implements Finalizer {

        /**
         * @description
         * The Id of the AsynchronousJob__c object the Apex Job has been created to run.
         */
        private final Id asyncObjectId;

        /**
         * @description
         * Constructs a new Finalizer for the given AsynchronousJob__c object Id.
         *
         * @param asyncObjectId The Asynchronous_c object Id.
         */
        public ApexFinalizer(final Id asyncObjectId) {
            this.asyncObjectId = asyncObjectId;
        }

        /**
         * @description
         * Called when the Apex job has completed.
         *
         * The context is used to determine the status of the job.
         *
         * If the job succeeded, the Runnable's onSuccess method is called. The return value
         * from the call indicates whether to keep the AsynchronousJob__c object or delete it.
         *
         * If the job failed and there are more re-tries available, the Runnable's onError method
         * is called. The return value from the method indicates the new Status to assign to the
         * job.
         *
         * If the job failed and the re-tries have been exhausted, the Runnable's onFailure method
         * is called. The return value from the call indicates whether to keep the AsynchronousJob__c
         * object or delete it.
         *
         * @param context Information about job result.
         */
        public void execute(final FinalizerContext context) {
            final AsynchronousJob__c asyncObject = AsynchronousDAO.INJECT.getObject(asyncObjectId);

            try {
                if (context.getResult() == ParentJobResult.SUCCESS) {
                    onSuccess(asyncObject);
                } else {
                    onFailure(asyncObject, context.getException());
                }
            } catch(Exception exc) {
                AsynchronousHelper.INJECT.recordInternalException(asyncObject, new AsynchronousV1.APIException('Wrapper', exc));
            }

            try {
                final AsynchronousV1.Job asyncJob = AsynchronousJob.fromSObject(asyncObject);
                if (asyncJob.getRunnable() instanceof AsynchronousScheduler) {
                    AsynchronousScheduler.queue(
                            (Set<String>) JSON.deserialize(
                                    asyncJob.getState().get(JOBS_TO_START), Set<String>.class)
                    );
                }

            } catch(Exception exc) {
                AsynchronousHelper.INJECT.recordInternalException(asyncObject, new AsynchronousV1.APIException('Wrapper', exc));
            }
        }

        /**
         * @description
         * Method handling the successful processing of a job.
         *
         * @param asyncObject The AsynchronousJob__c object for the job.
         */
        private void onSuccess(final AsynchronousJob__c asyncObject) {
            final AsynchronousV1.Job asyncJob = AsynchronousJob.fromSObject(asyncObject);

            if (asyncJob.getRunnable().onSuccess(asyncJob)) {
                asyncObject.Status__c = AsynchronousV1.Status.SUCCEEDED.name();
                AsynchronousDAO.INJECT.persistObjects(new List<AsynchronousJob__c> { asyncObject });
            } else {
                AsynchronousDAO.INJECT.removeObjects(new List<AsynchronousJob__c> { asyncObject });
            }
        }

        /**
         * @description
         * Method handling the failed processing of a job.
         *
         * If re-tries are available, and the Status returned by the Runnable's onError method
         * is QUEUED, then the job is scheduled to run again in the number of milliseconds given
         * by the job's Retry Interval.
         *
         * @param asyncObject The AsynchronousJob__c object for the job.
         * @param exc The Exception that caused the job to fail.
         */
        private void onFailure(final AsynchronousJob__c asyncObject, final Exception exc) {
            final Integer maximumRetries = (Integer) asyncObject.MaximumRetries__c;
            final Integer retryNumber = (Integer) asyncObject.RetryNumber__c;
            final AsynchronousV1.Job asyncJob = AsynchronousJob.fromSObject(asyncObject);

            AsynchronousHelper.INJECT.recordException(asyncObject, new AsynchronousV1.APIException('Wrapper', exc));

            if (retryNumber == maximumRetries) {
                if (asyncJob.getRunnable().onFailure(asyncJob, exc)) {
                    asyncObject.Status__c = AsynchronousV1.Status.FAILED.name();
                    AsynchronousDAO.INJECT.persistObjects(new List<AsynchronousJob__c> { asyncObject });
                } else {
                    AsynchronousDAO.INJECT.removeObjects(new List<AsynchronousJob__c> { asyncObject });
                }
            } else {
                asyncObject.Status__c = asyncJob.getRunnable().onError(asyncJob, exc).name();
                if (asyncObject.Status__c == AsynchronousV1.Status.QUEUED.name()) {
                    asyncObject.RetryNumber__c = retryNumber + 1;
                    asyncObject.ScheduledRunTime__c =
                            Datetime.newInstance(System.currentTimeMillis() + asyncJob.getRetryInterval());
                }

                AsynchronousDAO.INJECT.persistObjects(new List<AsynchronousJob__c> { asyncObject });
            }
        }
    }
}