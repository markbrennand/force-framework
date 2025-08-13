/**
 * @description
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../LICENSE target="_blank">MIT License</a>.
 * <br><br>
 * The Scheduler is responsible for finding and starting the next job that can be run based on its scheduled time.
 * <br><br>
 * The Scheduler queue method is the controller for the concurrency. The Scheduler selects the jobs that are runnable.
 * The number of active instances of each job is checked against its maximum concurrency. If there is concurrency
 * available the Id of the job is added to a Set jobs to start. A Scheduler job is started passing in the Set
 * as an argument.
 * <br><br>
 * The Scheduler job starts the first job in the Set and removes the Id of the job from the Set. The new Set is
 * saved in the Set.
 * <br><br>
 * The Finalizer, if finalizing, a Scheduler, extracts the Set from the job. It calls the Scheduler's queue method
 * passing the Set as argument. If the Set is not empty, a new Scheduler is started, passing in the new Set as
 * argument. This pattern is repeated till the Set is empty.
 * <br><br>
 * When an empty Set is passed to the queue method, the Scheduler builds the next Set of job ids that can be run.
 * <br><br>
 * Due to the Queueable limit of only 1 Apex job being allowed to be started, a Scheduler will be run for every
 * job that is started.
 *
 * @author Mark Brennand
 */
public with sharing class AsynchronousScheduler extends AsynchronousV1.Runnable {

    /**
     * @description
     * The action in the Registry for the configuration Dependency injection.
     */
    private final static String CONFIG_ACTION = 'AsynchronousScheduler';

    /**
     * @description
     * The number of milliseconds to wait if there are no jobs available to run.
     * <br><br>
     * Be careful of the value used here as a large value will cause the CPU governor limit to be hit.
     */
    @TestVisible
    private final static String NO_JOBS_TO_RUN_DELAY_PROPERTY = 'noJobsToRunDelay';

    /**
     * @description
     * The number of jobs to be run that the Scheduler should select in the queue method.
     */
    @TestVisible
    private final static String MAXIMUM_JOBS_TO_START_PROPERTY = 'maximumJobsToStart';

    /*
     * Initialise the registry.
     *
     * We have to do this before the property wiring of configuration.
     */
    static {
        DependencyV1.bind(Map<String, Integer>.class, CONFIG_ACTION, Configuration.class);
        DependencyV1.reload();
    }

    /**
     * @description
     * Configuration options for the Scheduler.
     * <br><br>
     * Test visible to it can be overridden from unit tests.
     */
    @TestVisible
    private static Map<String, Integer> configuration =
            (Map<String, Integer>) DependencyV1.inject(Map<String, Integer>.class, CONFIG_ACTION);

    /**
     * @description
     * Constructor for the Scheduler.
     * <br><br>
     * The constructor is private to prevent construction from anywhere other than the factory (QueueNext class).
     */
    @TestVisible
    private AsynchronousScheduler() {
        super(RunNextAvailable.class);
        AssertionV1.isNotNull(configuration.get(NO_JOBS_TO_RUN_DELAY_PROPERTY), 'property; ' + CONFIG_ACTION + '.' + NO_JOBS_TO_RUN_DELAY_PROPERTY);
        AssertionV1.isNotNull(configuration.get(MAXIMUM_JOBS_TO_START_PROPERTY), 'property; ' + CONFIG_ACTION + '.' + MAXIMUM_JOBS_TO_START_PROPERTY);
    }

    /**
     * @description
     * Called to queue the next, non Scheduler job, to be run.
     * <br><br>
     * If there are no jobs to run, a pause is taken before qetting the next job to run.
     * <br><br>
     * Synchronisation is performed in the next job query to ensure that no more than one Scheduler tries to start
     * the same job.
     *
     * @param asyncJob The Asynchronous job for the Scheduler.
     * @param apexJobId The Id of the Apex job for the Runnable.
     */
    @SuppressWarnings('PMD.EmptyCatchBlock')
    public override void run(final AsynchronousV1.Job asyncJob, final String apexJobId) {
        AssertionV1.isNotNull(asyncJob, 'argument: AsynchronousScheduler.run.asyncJob');

        final Set<String> jobsToStart = (Set<String>)
                JSON.deserialize(asyncJob.getState().get(AsynchronousFinalizer.JOBS_TO_START), Set<String>.class);

        if (jobsToStart.isEmpty()) {
            delayWhenNoJobsToRun(configuration.get(NO_JOBS_TO_RUN_DELAY_PROPERTY));

        } else {
            final String jobId = jobsToStart.iterator().next();

            try {
                final AsynchronousJob__c asyncObject = AsynchronousDAO.API.getObject(jobId);
                asyncObject.ApexJobId__c = apexJobId;
                AsynchronousHelper.API.queueJob(asyncObject);

            } catch(AssertionV1.AssertionException ae) {
                // An assertion exception indicates a problem with the job, so just ignore it.
                // The most likely cause is that the job has been deleted but was identified to start and so
                // still in the list of jobs to start.
            }

            jobsToStart.remove(jobId);

            asyncJob.setState(
                    new Map<String, String> {
                            AsynchronousFinalizer.JOBS_TO_START => JSON.serialize(jobsToStart)
                    }
            );
        }
    }

    /**
     * @description
     * A simple implementation of sleep.
     * <br><br>
     * Apex lacks a sleep method. To prevent having to go into a tight loop, a query that takes 20+ ms to complete
     * is run as often as possible.
     *
     * @param delay The number of milliseconds to delay processing for.
     */
    @SuppressWarnings('PMD.ApexCRUDViolation,PMD.UnusedLocalVariable,PMD.OperationWithLimitsInLoop')
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
     * <br><br>
     * Running more than one Scheduler concurrently would break the synchronisation, so always use 1.
     *
     * @return The Scheduler concurrency.
     */
    public override Integer getMaximumActive() {
        return 1;
    }

    /**
     * @description
     * Called on successful execution of the Apex job for the Scheduler.
     *
     * @param asyncJob The Asynchronous job for the Scheduler.
     *
     * @return False to indicate that the Asynchronous__c for the job is to be deleted.
     */
    public override Boolean onSuccess(final AsynchronousV1.Job asyncJob) {
        AssertionV1.isNotNull(asyncJob, 'argument: AsynchronousScheduler.onSuccess.asyncJob');
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
    public override Boolean onFailure(final AsynchronousV1.Job asyncJob, final Exception exc) {
        AssertionV1.isNotNull(asyncJob, 'argument: AsynchronousScheduler.onFailure.asyncJob');
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
    public override Boolean onCancellation(final AsynchronousV1.Job asyncJob) {
        AssertionV1.isNotNull(asyncJob, 'argument: AsynchronousScheduler.onCancellation.asyncJob');
        return false;
    }

    /**
     * @description
     * Creates and queues for processing a new Scheduler job.
     * <br><br>
     * The processing logic for the Scheduler requires that the Asynchronous__c object for the new Scheduler job
     * is only persisted if an Apex job could be created for it.
     *
     * @param jobsLeftToStart The jobs that are left to start from the previous scheduler run.
     */
    public static void queue(final Set<String> jobsLeftToStart) {
        final AsynchronousV1.Job asyncJob;

        if (!jobsLeftToStart.isEmpty()) {
            asyncJob = AsynchronousAPI.API.createJob(
                    RunNextAvailable.class,
                    null,
                    0,
                    0,
                    new Map<String, String> { AsynchronousFinalizer.JOBS_TO_START => JSON.serialize(jobsLeftToStart) }
            );

        } else {
            final Set<String> newJobsToStart = getJobIdsToStart(configuration.get(MAXIMUM_JOBS_TO_START_PROPERTY));
            if (newJobsToStart.isEmpty() && (AsynchronousDAO.API.countSchedulableObjects() == 0)) {
                return;
            }

            asyncJob = AsynchronousAPI.API.createJob(
                    RunNextAvailable.class,
                    null,
                    0,
                    0,
                    new Map<String, String> { AsynchronousFinalizer.JOBS_TO_START => JSON.serialize(newJobsToStart) }
            );
        }

        // More than one running Scheduler would cause the synchronisation to fail.
        if (AsynchronousDAO.API.countActiveObjects(new AsynchronousJob__c(Runnable__c = RunNextAvailable.class.getName())) < 1) {
            AsynchronousJob__c asyncObject = AsynchronousJob.toSObject(asyncJob);
            AsynchronousDAO.API.persistObjects(
                    new List<AsynchronousJob__c> { asyncObject},
                    new List<Map<String, String>> { asyncJob.getState() }
            );
            AsynchronousHelper.API.queueJob(asyncObject);
        }
    }

    /**
     * @description
     * Returns the ids of all the jobs that can be started.
     * <br><br>
     * The concurrency of the jobs is used to determine whether the job can be started.
     *
     * @param maxToStart The maximum number of jobs to return.
     *
     * @return The ids of the jobs that can be started.
     */
    private static Set<String> getJobIdsToStart(final Integer maxToStart) {
        final Set<String> jobIds = new Set<String>();
        final Map<String, Integer> activeCountCache = new Map<String, Integer>();
        final Map<String, Integer> activeCache = new Map<String, Integer>();

        for (AsynchronousJob__c asyncObject : AsynchronousDAO.API.getScheduledObjects(maxToStart)) {
            final String runnable = asyncObject.Runnable__c;
            final Integer maxActive;
            final Integer active;

            if (activeCountCache.containsKey(runnable)) {
                maxActive = activeCountCache.get(runnable);

            } else {
                maxActive =
                        ((AsynchronousV1.RunnableJob) TypesV1.newInstance(TypesV1.load(asyncObject.Runnable__c)))
                                .getMaximumActive();

                activeCountCache.put(runnable, maxActive);
            }

            if (activeCache.containsKey(runnable)) {
                active = activeCache.get(runnable);

            } else {
                active = AsynchronousDAO.API.countActiveObjects(asyncObject);
                activeCache.put(runnable, active);
            }

            if (active < maxActive) {
                jobIds.add(asyncObject.Id);
                activeCache.put(runnable, active+1);
            }
        }

        return jobIds;
    }

    /**
     * @description
     * Default Scheduler configuration to be injected.
     */
    public with sharing class Configuration implements TypesV1.Factory {

        /**
         * @description
         * Creates a new instance of the configuration.
         *
         * @return The new instance.
         */
        public Object newInstance() {
            return new Map<String, Integer> {
                    NO_JOBS_TO_RUN_DELAY_PROPERTY => 2000,
                    MAXIMUM_JOBS_TO_START_PROPERTY => 1
            };
        }
    }

    /**
     * @description
     * Load the Scheduler from a factory.
     * <br><br>
     * This allows the Scheduler class to be inaccessible from outside this class.
     */
    public with sharing class RunNextAvailable implements TypesV1.Factory {

        /**
         * @description
         * Creates a new instance of the scheduler.
         *
         * @return The scheduler instance.
         */
        public Object newInstance() {
            return new AsynchronousScheduler();
        }
    }
}