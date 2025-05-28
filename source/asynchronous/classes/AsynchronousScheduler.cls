/**
 * @description
 * The Scheduler is responsible for finding and starting the next job that can be run based on its scheduled time.
 *
 * The Scheduler is the controller for the concurrency. The job that is to be run next will have its status set
 * to RUNNING and will be locked for update to prevent any other Scheduler jobs running it. The job itself is
 * queued to be run by Apex. When control is returned to SF from the run method, the job status change is committed
 * which prevents other Schedulers selecting the job as its status is now RUNNING. The status change to RUNNING also
 * means it is counted in the query to find the number of running jobs for the Runnable, allowing an accurate count
 * of the number of active jobs for the Runnable to be determined.
 *
 * Due to the Queueable limit of only 1 Apex job being allowed to be started, a Scheduler will be run for every
 * job that is started.
 *
 * @author Mark Brennand
 */
public with sharing class AsynchronousScheduler extends AsynchronousRunnable {

    /**
     * @description
     * The action in the Registry for the configuration Dependency injection.
     */
    private final static String CONFIG_ACTION = 'AsynchronousConfiguration';

    /**
     * @description
     * The maximum number of Schedulers that may be active concurrently.
     */
    @TestVisible
    private final static String MAX_SCHEDULERS_PROPERTY = 'maxSchedulers';

    /**
     * @description
     * The number of milliseconds to wait if there are no jobs available to run.
     *
     * Be careful of the value used here as a large value will cause the CPU governor limit to be hit.
     */
    @TestVisible
    private final static String NO_JOBS_TO_RUN_DELAY_PROPERTY = 'noJobsToRunDelay';

    /**
     * @description
     * Configuration options for thge Scheduler.
     *
     * Test visible to it can be overridden from unit tests.
     */
    @TestVisible
    private Map<String, Integer> configuration =
            (Map<String, Integer>) Dependency.inject(Map<String, Integer>.class, CONFIG_ACTION);

    /**
     * @description
     * Constructor for the Scheduler.
     *
     * The constructor is private to prevent construction from anywhere other than the factory (QueueNext class).
     */
    @TestVisible
    private AsynchronousScheduler() {
        super(QueueNext.class);
        Assertion.isNotNull(configuration.get(MAX_SCHEDULERS_PROPERTY), 'property; ' + CONFIG_ACTION + '.' + MAX_SCHEDULERS_PROPERTY);
        Assertion.isNotNull(configuration.get(NO_JOBS_TO_RUN_DELAY_PROPERTY), 'property; ' + CONFIG_ACTION + '.' + NO_JOBS_TO_RUN_DELAY_PROPERTY);
    }

    /**
     * @description
     * Called to queue the next, non Scheduler job, to be run.
     *
     * If there are no jobs to run, a pause is taken before qetting the next job to run.
     *
     * Synchronisation is performed in the next job query to ensure that no more than one Scheduler tries to start
     * the same job.
     *
     * @param asyncJob The Asynchronous job for the Scheduler.
     * @param apexJobId The Id of the Apex job for the Runnable.
     */
    public override void run(final Asynchronous.Job asyncJob, final String apexJobId) {
        Assertion.isNotNull(asyncJob, 'argument: AsynchronousScheduler.run.asyncJob');

        if (AsynchronousDAO.countScheduledObjects(true) == 0) {
            delayWhenNoJobsToRun(configuration.get(NO_JOBS_TO_RUN_DELAY_PROPERTY));
        }

        final AsynchronousJob__c scheduledAsyncObject = AsynchronousDAO.getNextScheduled();

        if (scheduledAsyncObject != null) {
            scheduledAsyncObject.ApexJobId__c = apexJobId;

            final Boolean jobStarted = AsynchronousHelper.queueJob(scheduledAsyncObject);
            asyncJob.setState(
                    new Map<String, String> {
                            AsynchronousFinalizer.START_SCHEDULER_ARGUMENT => String.valueOf(jobStarted)
                    }
            );
        }
    }

    /**
     * @description
     * A simple implementation of sleep.
     *
     * Apex lacks a sleep method. To prevent having to go into a tight loop, a query that takes 20+ ms to complete
     * is run as often as possible.
     *
     * @param delay The number of milliseconds to delay processing for.
     */
    private void delayWhenNoJobsToRun(final Integer delay) {
        final Long startTime = System.currentTimeMillis();
        final Long endTime = startTime + delay;

        for (; System.currentTimeMillis() < endTime; ) {
            if (Limits.getAggregateQueries() < 250) {
                List<SObject> ignore = [
                        SELECT Id,
                                (SELECT Id FROM Badges WHERE ImageUrl != 'ab'),
                                (SELECT Id FROM CombinedAttachments WHERE ContentUrl != 'ab'),
                                (SELECT Id FROM CommSubscriptionConsents WHERE ConsentCapturedSource != 'ab'),
                                (SELECT Id FROM ContactCleanInfoReviewers WHERE City != 'ab'),
                                (SELECT Id FROM ContactRequests WHERE Name != 'ab')
                        FROM User
                        ORDER BY Country DESC, EmployeeNumber DESC, DigestFrequency DESC, DefaultGroupNotificationFrequency DESC
                        LIMIT 1
                ];
            }
        }
    }

    /**
     * @description
     * Returns the maximum number of Schedulers that may be active for the user at any one time.
     *
     * If there are jobs available to run now, the maximum number set in the configuration is returned. Otherwise,
     * 1 is returned if there are jobs to run in the future.
     *
     * If there are no jobs to run at all, 1 is returned. This is to make it the Finalizer's decision not to start
     * a new Scheduler.
     *
     * @return The Scheduler concurrency.
     */
    public override Integer getMaximumActive() {
        final Integer scheduledObjectCount = AsynchronousDAO.countScheduledObjects(false);
        if (scheduledObjectCount > 0) {
            if (AsynchronousDAO.countScheduledObjects(true) > 0) {
                // If several Schedulers all run at the same time, their RUNNING counts will include the other
                // schedulers that are completing. Their active counts will thus be skewed by the other jobs
                // that are also completing and have a status of SUCCEEDED or FAILED which has not yet been
                // committed.
                //
                // To counter for this scenario, we drop the limit each time by 1, for the Scheduler that has
                // completed.
                return Math.max(
                        Math.max(1, AsynchronousDAO.countActiveObjects(new AsynchronousJob__c(Runnable__c = QueueNext.class.getName())) - 1),
                        Math.min(scheduledObjectCount, configuration.get(MAX_SCHEDULERS_PROPERTY))
                );
            } else {
                return 1;
            }
        } else {
            return 1;
        }
    }

    /**
     * @description
     * Called on successful execution of the Apex job for the Scheduler.
     *
     * @param asyncJob The Asynchronous job for the Scheduler.
     *
     * @return False to indicate that the Asynchronous__c for the job is to be deleted.
     */
    public override Boolean onSuccess(final Asynchronous.Job asyncJob) {
        Assertion.isNotNull(asyncJob, 'argument: AsynchronousScheduler.onSuccess.asyncJob');
        return false;
    }

    /**
     * @description
     * Called on failed execution of the Apex job for the Scheduler.
     *
     * @param asyncJob The Asynchronous job for the Scheduler.
     * @param exc The Exception that caused the job to fail.
     *
     * @return True to indicate that the Asynchronous__c for the job is to be kept.
     */
    public override Boolean onFailure(final Asynchronous.Job asyncJob, final Exception exc) {
        Assertion.isNotNull(asyncJob, 'argument: AsynchronousScheduler.onFailure.asyncJob');
        return true;
    }

    /**
     * @description
     * Called if the Scheduler job is cancelled.
     *
     * @param asyncJob The Asynchronous job for the Scheduler.
     *
     * @return False to indicate that the Asynchronous__c for the job is to be deleted.
     */
    public override Boolean onCancellation(final Asynchronous.Job asyncJob) {
        Assertion.isNotNull(asyncJob, 'argument: AsynchronousScheduler.onCancellation.asyncJob');
        return false;
    }

    /**
     * @description
     * Creates and queues for processing a new Scheduler job.
     *
     * The processing logic for the Scheduler requires that the Asynchronous__c object for the new Scheduler job
     * is only persisted if an Apex job could be created for it.
     */
    public static void queue() {
        Asynchronous.Job asyncJob = Asynchronous.createJob(
                QueueNext.class,
                null,
                0,
                0,
                new Map<String, String> {}
        );

        AsynchronousHelper.queueJob(AsynchronousJob.toSObject(asyncJob));
    }

    /**
     * @description
     * Default Scheduler configuration to be injected.
     */
    public with sharing class Configuration implements TypeHelper.Factory {
        public Object newInstance() {
            return new Map<String, Integer> {
                    MAX_SCHEDULERS_PROPERTY => 1,
                    NO_JOBS_TO_RUN_DELAY_PROPERTY => 2000
            };
        }
    }

    /**
     * @description
     * Load the Scheduler from a factory.
     *
     * This allows the Scheduler class to be inaccessible from outside this class.
     */
    public with sharing class QueueNext implements TypeHelper.Factory {
        public Object newInstance() {
            return new AsynchronousScheduler();
        }
    }

    // Initialise the registry to use the default configuration.
    static {
        Dependency.bind(Map<String, Integer>.class, CONFIG_ACTION, Configuration.class);
        Dependency.reload();
    }
}