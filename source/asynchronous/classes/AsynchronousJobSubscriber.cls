/**
 * @description
 * <p>
 * Class providing the Trigger logic for the AsynchronousJob__c object.
 * <p>
 * A Trigger API Subscriber is used to consume the Event published by the Trigger API.
 * <p>
 * The Subscriber implementation class is private to prevent its re-use.
 * <p>
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../LICENSE target="_blank">MIT License</a>.
 *
 * @author Mark Brennand
 */
public with sharing class AsynchronousJobSubscriber {

    /**
     * @description
     * <p>
     * Prevent construction outside class.
     */
    @SuppressWarnings('PMD.EmptyStatementBlock')
    private AsynchronousJobSubscriber() {}

    /**
     * @description
     * <p>
     * Factory to create the pre processor subscriber.
     */
    public class PreProcessorFactory implements TypesV1.Factory {
        private final PreProcessorSubscriber subscriber = new PreProcessorSubscriber();

        /**
         * @description
         * Constructs a new instance of the trigger subscriber.
         *
         * @return The trigger subscriber.
         */
        public Object newInstance() {
            return subscriber;
        }
    }

    /**
     * @description
     * <p>
     * Factory to create the pre processor subscriber.
     */
    public class CancellationsFactory implements TypesV1.Factory {
        private final CancellationsSubscriber subscriber = new CancellationsSubscriber();

        /**
         * @description
         * Constructs a new instance of the trigger subscriber.
         *
         * @return The trigger subscriber.
         */
        public Object newInstance() {
            return subscriber;
        }
    }

    /**
     * @description
     * <p>
     * Factory to create the start scheduler subscriber class.
     */
    public class StartSchedulerFactory implements TypesV1.Factory {
        private final StartSchedulerSubscriber subscriber = new StartSchedulerSubscriber();

        /**
         * @description
         * Constructs a new instance of the start scheduler subscriber.
         *
         * @return The trigger subscriber.
         */
        public Object newInstance() {
            return subscriber;
        }
    }

    /**
     * @description
     * <p>
     * Filter returning only AsynchronousJob__c objects that have changed status to Cancelled and whose associated
     * Runnable requires that the object is deleted on cancellation.
     */
    public with sharing class CancellationsFilter extends ArrayV1.Callback {

        /**
         * @description
         * <p>
         * Does AsynchronousJob__c object meet the criteria for deletion.
         *
         * @param element The AsynchronousJob__c object.
         * @param currentValue The value accumulated over the array iteration.
         * @param index The positional index of the array element.
         *
         * @return Optional of true if job is to be deleted.
         */
        public override OptionalV1 function(final Object element, final OptionalV1 currentValue, final Integer index) {
            final OptionalV1 oldValues = (OptionalV1) shared();
            final AsynchronousJob__c asyncObject = (AsynchronousJob__c) element;
            if (oldValues.isPresent()
                    && asyncObject.Status__c != ((AsynchronousJob__c) ((ImmutableV1.ReadOnlyMap) oldValues.get()).get(asyncObject.Id)).Status__c
                    && asyncObject.Status__c == AsynchronousV1.Status.CANCELLED.name())
            {
                final AsynchronousV1.Job asyncJob = AsynchronousJob.fromSObject(asyncObject);
                return OptionalV1.of(!asyncJob.getRunnable().onCancellation(asyncJob));
            }

            return OptionalV1.of(false);
        }
    }

    /**
     * @description
     * <p>
     * Filter to determine whether AsynchronousJob__c object is for running the Scheduler.
     */
    public with sharing class StartSchedulerFilter extends ArrayV1.Callback {
        private final String schedulerClassName = AsynchronousScheduler.RunNextAvailable.class.getName();

        /**
         * @description
         * <p>
         * Is AsynchronousJob__c object runnable the Scheduler.
         *
         * @param element The AsynchronousJob__c object.
         * @param currentValue The value accumulated over the array iteration.
         * @param index The positional index of the array element.
         *
         * @return Optional of true if job is to be deleted.
         */
        public override OptionalV1 function(final Object element, final OptionalV1 currentValue, final Integer index) {
            final AsynchronousJob__c asyncObject = (AsynchronousJob__c) element;
            return OptionalV1.of(asyncObject.Runnable__c != schedulerClassName);
        }
    }

    /**
     * @description
     * <p>
     * Subscriber called to pro-process Asynchronous Job objects.
     * <p>
     * The class is private to prevent re-use outside this class.
     */
    private with sharing class PreProcessorSubscriber implements TriggerV1.Subscriber {

        /**
         * @description
         * <p>
         * Processes the event generated by the trigger API when DML is performed.
         *
         * @param event The trigger API event.
         */
        public void onEvent(final TriggerV1.Event event) {
            ArrayV1.over(event.getRecords()).forEach(new PreProcessor());
        }
    }

    /**
     * @description
     * <p>
     * Subscriber called to process cancelled Asynchronous Jobs.
     * <p>
     * The class is private to prevent re-use outside this class.
     */
    private with sharing class CancellationsSubscriber implements TriggerV1.Subscriber {

        /**
         * @description
         * <p>
         * Processes the event generated by the trigger API when DML is performed.
         *
         * @param event The trigger API event.
         */
        public void onEvent(final TriggerV1.Event event) {
            final List<AsynchronousJob__c> toDelete = new List<AsynchronousJob__c>();
            for (Object record : event.getRecords()) {
                toDelete.add(new AsynchronousJob__c(Id = ((AsynchronousJob__c) record).Id));
            }
            AsynchronousDAO.impl.removeObjects(toDelete);
        }
    }

    /**
     * @description
     * <p>
     * Called to start Scheduler.
     * <p>
     * The subscriber is only invoked if the filter has determined that there are non Scheduler jobs to be started.
     * <p>
     * The class is private to prevent re-use outside this class.
     */
    private with sharing class StartSchedulerSubscriber implements TriggerV1.Subscriber {

        /**
         * @description
         * <p>
         * Processes the event generated by the trigger API when DML is performed.
         *
         * @param event The trigger API event.
         */
        public void onEvent(final TriggerV1.Event event) {
            AsynchronousScheduler.queue(new Set<String>());
        }
    }

    /**
     * @description
     * <p>
     * Pre processes AsynchroousJob__c objects prior to persistence.
     */
    private with sharing class PreProcessor extends ArrayV1.Callback {

        /**
         * @description
         * <p>
         * Checks if class set in AsynchronousJob__c object implements Runnable.
         * <p>
         * Marks the job as ready to run.
         *
         * @param element The AsynchronousJob__c object.
         * @param currentValue The accumulator.
         * @param index The positional index of the AsynchronousJob__c object in the List being processed.
         *
         * @return An optional with the new value or an empty optional if no value update is required.
         */
        public override OptionalV1 function(final Object element, final OptionalV1 currentValue, final Integer index) {
            final AsynchronousJob__c asyncObject = (AsynchronousJob__c) element;

            try {
                final Object runnable = TypesV1.newInstance(TypesV1.load(asyncObject.Runnable__c));
                if (!(runnable instanceof AsynchronousV1.RunnableJob)) {
                    asyncObject.addError(AsynchronousJob__c.Runnable__c, 'Class ' + asyncObject.Runnable__c + ' does not implement AsynchronousV1.RunnableJob');

                } else if (asyncObject.Status__c == AsynchronousV1.Status.PENDING.name()) {
                    asyncObject.Status__c = AsynchronousV1.Status.QUEUED.name();
                    asyncObject.ScheduledRunTime__c = CommonHelper.now();
                    asyncObject.RetryNumber__c = 0;
                }
            } catch (Exception e) {
                asyncObject.addError(e.getMessage());
            }

            return OptionalV1.empty();
        }
    }
}