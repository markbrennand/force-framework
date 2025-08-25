/**
 * @description
 * <p/>
 * Finalizer called on completion of an Apex job.
 * <p/>
 * Success or failure of the job is determined from the context.
 * <p/>
 * If successful, the Asynchronous job's Runnable onSuccess method will be called.
 * <p/>
 * If the job has failed, the job's Runnable onError method will be called. The return value will indicate
 * whether processing of the job is to be continued.
 * <p/>
 * If processing is to be continued and the number of re-tries has been reached for the job, the job's Runnable
 * onFailure method will be called.
 * <p/>
 * If the number of re-tries hasn't been reached, the job's Status is set to QUEUED and the re-try number is
 * incremented.
 * <p/>
 * If there are scheduled jobs left to process, a new Asynchronous scheduler is queued.
 * <p/>
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../LICENSE target="_blank">MIT License</a>.
 *
 * @author Mark Brennand
 */
public with sharing class AsynchronousFinalizer {

    /**
     * @description
     * <p/>
     * Set of job Ids that remain to be started.
     */
    public final static String JOBS_TO_START = 'JobsToStart';

    /**
     * @description
     * <p/>
     * Factory method to create a new Finalizer.
     * <p/>
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
     * <p/>
     * Finalizer for the Asynchronous framework.
     */
    private with sharing class ApexFinalizer implements Finalizer {

        /**
         * @description
         * <p/>
         * The Id of the AsynchronousJob__c object the Apex Job has been created to run.
         */
        private final Id asyncObjectId;

        /**
         * @description
         * <p/>
         * Constructs a new Finalizer for the given AsynchronousJob__c object Id.
         *
         * @param asyncObjectId The Asynchronous_c object Id.
         */
        public ApexFinalizer(final Id asyncObjectId) {
            this.asyncObjectId = asyncObjectId;
        }

        /**
         * @description
         * <p/>
         * Called when the Apex job has completed.
         * <p/>
         * The context is used to determine the status of the job.
         * <p/>
         * If the job succeeded, the Runnable onSuccess method is called. The return value
         * from the call indicates whether to keep the AsynchronousJob__c object or delete it.
         * <p/>
         * If the job failed and there are more re-tries available, the Runnable onError method
         * is called. The return value from the method indicates the new Status to assign to the
         * job.
         * <p/>
         * If the job failed and the re-tries have been exhausted, the Runnable onFailure method
         * is called. The return value from the call indicates whether to keep the AsynchronousJob__c
         * object or delete it.
         *
         * @param context Information about job result.
         */
        public void execute(final FinalizerContext context) {
            final AsynchronousJob__c asyncObject = AsynchronousDAO.impl.getObject(asyncObjectId);

            try {
                if (context.getResult() == ParentJobResult.SUCCESS) {
                    onSuccess(asyncObject);
                } else {
                    onFailure(asyncObject, context.getException());
                }
            } catch(Exception exc) {
                AsynchronousHelper.impl.recordInternalException(asyncObject, new AsynchronousV1.APIException('Wrapper', exc));
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
                AsynchronousHelper.impl.recordInternalException(asyncObject, new AsynchronousV1.APIException('Wrapper', exc));
            }
        }

        /**
         * @description
         * <p/>
         * Method handling the successful processing of a job.
         *
         * @param asyncObject The AsynchronousJob__c object for the job.
         */
        private void onSuccess(final AsynchronousJob__c asyncObject) {
            final AsynchronousV1.Job asyncJob = AsynchronousJob.fromSObject(asyncObject);

            if (asyncJob.getRunnable().onSuccess(asyncJob)) {
                asyncObject.Status__c = AsynchronousV1.Status.SUCCEEDED.name();
                AsynchronousDAO.impl.persistObjects(new List<AsynchronousJob__c> { asyncObject });
            } else {
                AsynchronousDAO.impl.removeObjects(new List<AsynchronousJob__c> { asyncObject });
            }
        }

        /**
         * @description
         * <p/>
         * Method handling the failed processing of a job.
         * <p/>
         * If re-tries are available, and the Status returned by the Runnable onError method
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

            AsynchronousHelper.impl.recordException(asyncObject, new AsynchronousV1.APIException('Wrapper', exc));

            if (retryNumber == maximumRetries) {
                if (asyncJob.getRunnable().onFailure(asyncJob, exc)) {
                    asyncObject.Status__c = AsynchronousV1.Status.FAILED.name();
                    AsynchronousDAO.impl.persistObjects(new List<AsynchronousJob__c> { asyncObject });
                } else {
                    AsynchronousDAO.impl.removeObjects(new List<AsynchronousJob__c> { asyncObject });
                }
            } else {
                asyncObject.Status__c = asyncJob.getRunnable().onError(asyncJob, exc).name();
                if (asyncObject.Status__c == AsynchronousV1.Status.QUEUED.name()) {
                    asyncObject.RetryNumber__c = retryNumber + 1;
                    asyncObject.ScheduledRunTime__c =
                            Datetime.newInstance(System.currentTimeMillis() + asyncJob.getRetryInterval());
                }

                AsynchronousDAO.impl.persistObjects(new List<AsynchronousJob__c> { asyncObject });
            }
        }
    }
}