/**
 * @description
 * @author Mark Brennand
 */
public with sharing virtual class AsynchronousJobSubscriber {

    /**
     * @description
     * Flag determining whether to run the triggers or not.
     * <br><br>
     * When persisting an AsynchronousJob__c object in all places other than job creation, the triggers should be
     * disabled as they add a lot of overhead. And there is no need to try and start an Asynchronous Scheduler
     * for the updates made to the object.
     */
    public static Boolean skipTriggers = false;

    /**
     * @description
     * Prevent re-use.
     */
    private AsynchronousJobSubscriber() {}

    private with sharing class Implementation implements TriggerV1.Subscriber {

        public Set<TriggerV1.Operation> forOperations() {
            return new Set<TriggerV1.Operation> { TriggerV1.Operation.INSERTING, TriggerV1.Operation.UPDATING };
        }

        public void onEvent(final TriggerV1.Event event) {
            if (event.isBefore()) {
                handleBefore(event);
            } else {
                handleAfter(event);
            }
        }

        private void handleBefore(final TriggerV1.Event event) {
            if (skipTriggers) {
                return;
            }

            for (AsynchronousJob__c asyncObject : (List<AsynchronousJob__c>) event.getRecords()) {
                try {
                    final Object runnable = TypesV1.newInstance(TypesV1.load(asyncObject.Runnable__c));
                    if (!(runnable instanceof AsynchronousV1.RunnableJob)) {
                        asyncObject.addError(AsynchronousJob__c.Runnable__c, 'Class ' + asyncObject.Runnable__c + ' does not implement AsynchronousV1.RunnableJob');

                    } else if (asyncObject.Status__c == AsynchronousV1.Status.PENDING.name()) {
                        asyncObject.Status__c = AsynchronousV1.Status.QUEUED.name();
                        asyncObject.ScheduledRunTime__c = Datetime.now();
                        asyncObject.RetryNumber__c = 0;
                    }

                } catch (Exception e) {
                    asyncObject.addError(e.getMessage());
                }
            }
        }

        private void handleAfter(final TriggerV1.Event event) {
            if (skipTriggers) {
                return;
            }

            final List<AsynchronousJob__c> toDelete = new List<AsynchronousJob__c>();
            Boolean startScheduler = false;

            for (AsynchronousJob__c asyncObject : (List<AsynchronousJob__c>) event.getRecords()) {
                final Boolean isScheduler = AsynchronousJob.fromSObject(asyncObject).getRunnable() instanceof AsynchronousScheduler;

                if (asyncObject.Status__c == AsynchronousV1.Status.CANCELLED.name()
                        && event.hasOldValue(asyncObject)
                        && asyncObject.Status__c != ((AsynchronousJob__c) event.getOldValue(asyncObject)).Status__c
                ) {
                    final AsynchronousV1.Job asyncJob = AsynchronousJob.fromSObject(asyncObject);
                    if (!asyncJob.getRunnable().onCancellation(asyncJob)) {
                        toDelete.add(new AsynchronousJob__c(Id = asyncObject.Id));
                    }
                } else if (!isScheduler) {
                    startScheduler = true;
                }
            }

            AsynchronousDAO.API.removeObjects(toDelete);

            if (startScheduler) {
                AsynchronousScheduler.queue(new Set<String>());
            }
        }
    }

    public class Factory implements TypesV1.Factory {
        public Object newInstance() {
            return new Implementation();
        }
    }
}