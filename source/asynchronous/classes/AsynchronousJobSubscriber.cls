/**
 * @description
 * Class providing the Trigger logic for the AsynchronousJob__c object.
 * <br><br>
 * A Trigger API Subscriber is used to consume the Event published by the Trigger API.
 * <br><br>
 * The Subscriber implementation class is private to prevent its re-use.
 *
 * @author Mark Brennand
 */
public with sharing virtual class AsynchronousJobSubscriber {

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
            ArrayV1.over(event.getRecords()).forEach(new JobPreProcessor());
        }

        private void handleAfter(final TriggerV1.Event event) {
            final List<AsynchronousJob__c> toDelete = (List<AsynchronousJob__c>)
                    ArrayV1.over(event.getRecords()).sharing(event).reduce(
                            new JobsToDeleteBuilder(),
                            new List<AsynchronousJob__c>()
                    );

            final Boolean startScheduler = (Boolean)
                    ArrayV1.over(event.getRecords()).reduce(
                            new SchedulerStartCheck(),
                            false
                    );

            AsynchronousDAO.API.removeObjects(toDelete);

            if (startScheduler) {
                AsynchronousScheduler.queue(new Set<String>());
            }
        }
    }

    public class Factory implements TypesV1.Factory {
        private Implementation subscriber = new Implementation();

        public Object newInstance() {
            return subscriber;
        }
    }

    private with sharing class JobPreProcessor extends ArrayV1.Callback {
        public override Object function(final Object element, final Object currentValue, final Integer index) {
            final AsynchronousJob__c asyncObject = (AsynchronousJob__c) element;

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

            return null;
        }
    }

    private with sharing class JobsToDeleteBuilder extends ArrayV1.Callback {
        public override Object function(final Object element, final Object currentValue, final Integer index) {
            final AsynchronousJob__c asyncObject = (AsynchronousJob__c) element;
            final TriggerV1.Event event = (TriggerV1.Event) shared();

            if (asyncObject.Status__c == AsynchronousV1.Status.CANCELLED.name()
                    && event.hasOldValue(asyncObject)
                    && asyncObject.Status__c != ((AsynchronousJob__c) event.getOldValue(asyncObject)).Status__c
            ) {
                final AsynchronousV1.Job asyncJob = AsynchronousJob.fromSObject(asyncObject);
                if (!asyncJob.getRunnable().onCancellation(asyncJob)) {

                    // We cannot add the job as it is read only in an after update call.
                    ((List<AsynchronousJob__c>) currentValue).add(new AsynchronousJob__c(Id = asyncObject.Id));
                }
            }

            return currentValue;
        }
    }

    private with sharing class SchedulerStartCheck extends ArrayV1.Callback {
        public override Object function(Object element, Object currentValue, Integer index) {
            final AsynchronousJob__c asyncObject = (AsynchronousJob__c) element;
            final Boolean isScheduler = AsynchronousJob.fromSObject(asyncObject).getRunnable() instanceof AsynchronousScheduler;
            return (Boolean) currentValue || !isScheduler;
        }
    }
}