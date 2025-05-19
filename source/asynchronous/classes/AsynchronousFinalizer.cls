/**
 * @description
 * Finalizer called on completion of an Apex job.
 *
 * @author Mark Brennand
 */

public with sharing class AsynchronousFinalizer {

    public static Finalizer createFinalizer(final Id asyncObjectId) {
        return new ApexFinalizer(asyncObjectId);
    }

    private with sharing class ApexFinalizer implements Finalizer {
        private final Id asyncObjectId;

        public ApexFinalizer(final Id asyncObjectId) {
            this.asyncObjectId = asyncObjectId;
        }

        public void execute(final FinalizerContext context) {
            final Asynchronous__c asyncObject = AsynchronousDAO.get(asyncObjectId);

            try {
                if (context.getResult() == ParentJobResult.SUCCESS) {
                    onSuccess(asyncObject);
                } else {
                    onFailure(asyncObject, context.getException());
                }
            } catch(Exception exc) {
                AsynchronousHelper.internalFailure(asyncObject, exc);
            }

            try {
                if (AsynchronousDAO.countScheduled(false) > 0) {
                    AsynchronousScheduler.queue();
                }
            } catch(Exception exc) {
                AsynchronousHelper.internalFailure(asyncObject, exc);
            }
        }

        private void onSuccess(final Asynchronous__c asyncObject) {
            final Asynchronous.Job asyncJob = AsynchronousJob.fromSObject(asyncObject);

            if (asyncJob.getRunnable().onCompletion(asyncJob)) {
                asyncObject.Status__c = Asynchronous.Status.COMPLETED.name();
                AsynchronousDAO.persist(new List<Asynchronous__c> { asyncObject });
            } else {
                AsynchronousDAO.remove(new List<Asynchronous__c> { asyncObject });
            }
        }

        private void onFailure(final Asynchronous__c asyncObject, final Exception exc) {
            final Integer maximumRetries = (Integer) asyncObject.MaximumRetries__c;
            final Integer retryNumber = (Integer) asyncObject.RetryNumber__c;
            final Asynchronous.Job asyncJob = AsynchronousJob.fromSObject(asyncObject);

            AsynchronousHelper.recordException(asyncObject, exc);

            if (retryNumber == maximumRetries) {
                if (asyncJob.getRunnable().onFailure(asyncJob)) {
                    asyncObject.Status__c = Asynchronous.Status.FAILED.name();
                    AsynchronousDAO.persist(new List<Asynchronous__c> { asyncObject });
                } else {
                    AsynchronousDAO.remove(new List<Asynchronous__c> { asyncObject });
                }
            } else {
                asyncObject.RetryNumber__c = retryNumber + 1;
                asyncObject.Status__c = asyncJob.getRunnable().onError(asyncJob, exc).name();
                asyncObject.ScheduledRunTime__c =
                        Datetime.newInstance(System.currentTimeMillis() + asyncJob.getRetryInterval());

                AsynchronousDAO.persist(new List<Asynchronous__c> { asyncObject });
            }
        }
    }
}