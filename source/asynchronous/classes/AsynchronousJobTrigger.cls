/**
 * @description
 * @author Mark Brennand
 */
public with sharing virtual class AsynchronousJobTrigger {

    /**
     * @description
     * Flag determining whether to run the triggers or not.
     * <br><br>
     * When persisting an AsynchronousJob__c object in all places other than job creation, the triggers should be
     * disabled as they add a lot of overhead. And there is no need to try and start an Asynchronous Scheduler
     * for the updates made to the object.
     */
    public static Boolean skipTriggers = false;

    protected AsynchronousJobTrigger() {}

    private with sharing class Implementation extends TriggersV1.Event {

        /**
         * @description
         * Processes any persisted AsynchronousJob__c objects before they are added to the database.
         * <br><br>
         * Validation is performed on the objects.
         * <br><br>
         * If all objects are valid, their status is set to QUEUED and an Asynchronous Scheduler is started to run them.
         *
         * @param records The persisted objects.
         */
        public override void onBeforeInsert(final List<SObject> records) {
            handleBefore((List<AsynchronousJob__c>) records);
        }

        /**
         * @description
         * Processes any persisted AsynchronousJob__c objects before they are added to the database.
         * <br><br>
         * Validation is performed on the objects.
         * <br><br>
         * If all objects are valid, their status is set to QUEUED and an Asynchronous Scheduler is started to run them.
         *
         * @param records The persisted objects.
         */
        public override void onBeforeUpdate(final List<SObject> records) {
            handleBefore((List<AsynchronousJob__c>) records);
        }

        /**
         * @description
         * Processes any persisted AsynchronousJob__c objects before they are added to the database.
         * <br><br>
         * Validation is performed on the objects.
         * <br><br>
         * If all objects are valid, their status is set to QUEUED and an Asynchronous Scheduler is started to run them.
         *
         * @param records The persisted objects.
         */
        public override void onAfterInsert(final List<SObject> records) {
            handleAfter((List<AsynchronousJob__c>) records);
        }

        /**
         * @description
         * Processes any persisted AsynchronousJob__c objects after they have been added to the database.
         * <br><br>
         * Any new cancellations are processed.
         *
         * @param records The persisted objects.
         */
        public override void onAfterUpdate(final List<SObject> records) {
            handleAfter((List<AsynchronousJob__c>) records);
        }

        private void handleAfter(final List<AsynchronousJob__c> asyncObjects) {
            if (skipTriggers) {
                return;
            }

            final List<AsynchronousJob__c> toDelete = new List<AsynchronousJob__c>();
            Boolean startScheduler = false;

            for (AsynchronousJob__c asyncObject : asyncObjects) {
                final Boolean isScheduler = AsynchronousJob.fromSObject(asyncObject).getRunnable() instanceof AsynchronousScheduler;

                if (asyncObject.Status__c == Asynchronous.Status.CANCELLED.name()
                        && hasOldValue(asyncObject)
                        && asyncObject.Status__c != ((AsynchronousJob__c) getOldValue(asyncObject)).Status__c
                ) {
                    final Asynchronous.Job asyncJob = AsynchronousJob.fromSObject(asyncObject);
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

        private void handleBefore(final List<AsynchronousJob__c> asyncObjects) {
            if (skipTriggers) {
                return;
            }

            for (AsynchronousJob__c asyncObject : asyncObjects) {
                try {
                    final Object runnable = TypesV1.newInstance(TypesV1.load(asyncObject.Runnable__c));
                    if (!(runnable instanceof Asynchronous.Runnable)) {
                        asyncObject.addError(AsynchronousJob__c.Runnable__c, 'Class ' + asyncObject.Runnable__c + ' does not implement Asynchronous.Runnable');

                    } else if (asyncObject.Status__c == Asynchronous.Status.PENDING.name()) {
                        asyncObject.Status__c = Asynchronous.Status.QUEUED.name();
                        asyncObject.ScheduledRunTime__c = Datetime.now();
                        asyncObject.RetryNumber__c = 0;
                    }

                } catch (Exception e) {
                    asyncObject.addError(e.getMessage());
                }
            }
        }
    }

    public class Factory implements TypesV1.Factory {
        public Object newInstance() {
            return new Implementation();
        }
    }
}