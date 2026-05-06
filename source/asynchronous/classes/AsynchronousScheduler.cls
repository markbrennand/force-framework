/**
 * @description
 * <p>
 * The Scheduler is responsible for finding and starting the next job that can be run based on its scheduled time.
 * <p>
 * The Scheduler queue method is the controller for the concurrency. The Scheduler selects the jobs that are runnable.
 * The number of active instances of each job is checked against its maximum concurrency. If there is concurrency
 * available the Id of the job is added to a Set jobs to start. A Scheduler job is started passing in the Set
 * as an argument.
 * <p>
 * The Scheduler job starts the first job in the Set and removes the Id of the job from the Set. The new Set is
 * saved in the Set.
 * <p>
 * The Finalizer, if finalizing, a Scheduler, extracts the Set from the job. It calls the Scheduler's queue method
 * passing the Set as argument. If the Set is not empty, a new Scheduler is started, passing in the new Set as
 * argument. This pattern is repeated till the Set is empty.
 * <p>
 * When an empty Set is passed to the queue method, the Scheduler builds the next Set of job ids that can be run.
 * <p>
 * Due to the Queueable limit of only 1 Apex job being allowed to be started, a Scheduler will be run for every
 * job that is started.
 * <p>
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../LICENSE target="_blank">MIT License</a>.
 *
 * @author Mark Brennand
 */
public with sharing class AsynchronousScheduler extends AsynchronousV1.Runnable {

    /**
     * @description
     * <p>
     * The action in the Registry for the configuration Dependency injection.
     */
    private final static String CONFIG_ACTION = 'AsynchronousScheduler';

    /**
     * @description
     * <p>
     * The number of milliseconds to wait if there are no jobs available to run.
     * <p>
     * Be careful of the value used here as a large value will cause the CPU governor limit to be hit.
     */
    @TestVisible
    private final static String NO_JOBS_TO_RUN_DELAY_PROPERTY = 'noJobsToRunDelay';

    /**
     * @description
     * <p>
     * Reference to assign to async. jab running Scheduler.
     */
    private final static String SCHEDULER_JOB_REFERENCE = 'Scheduler({0})';

    /**
     * @description
     * <p>
     * The number of jobs to be run that the Scheduler should select in the queue method.
     */
    @TestVisible
    private final static String MAXIMUM_JOBS_TO_START_PROPERTY = 'maximumJobsToStart';

    /**
     * @description
     * <p>
     * The number of seconds for the time window in which a job must be in active state to be considered when
     * determining concurrency. The time window is the current time to the given number of seconds in the past.
     */
    private final static String ACTIVE_JOBS_WINDOW_PROPERTY = 'activeJobsWindow';

    /**
     * @description
     * <p>
     * The number of seconds for the time window in which a job must be in active state to be considered when
     * determining concurrency. The time window is the current time to the given number of seconds in the past.
     */
    private final static String MAXIMUM_JOBS_TO_SWEEP_PROPERTY = 'maximumJobsToSweep';

    /**
     * @description
     * <p>
     * The minimum number of seconds for the active window size.
     */
    private final static Integer MIN_ACTIVE_JOB_WINDOW_SIZE = 300;

    /**
     * @description
     * <p>
     * Default value for the active window size.
     */
    private final static Integer DEFAULT_ACTIVE_JOB_WINDOW_SIZE = 900;

    /**
     * @description
     * <p>
     * Minimum value for maximum jobs to sweep.
     */
    private final static Integer MIN_MAX_JOBS_TO_SWEEP = 1;

    /**
     * @description
     * <p>
     * Default value for maximum jobs to sweep.
     */
    private final static Integer DEFAULT_MAX_JOBS_TO_SWEEP = 100;

    /**
     * @description
     * <p>
     * Set of job Ids that remain to be started.
     */
    @TestVisible
    private final static String JOBS_TO_START = 'JobsToStart';

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
     * <p>
     * Configuration options for the Scheduler.
     * <p>
     * Test visible to it can be overridden from unit tests.
     */
    @TestVisible
    private static ImmutableV1.ReadOnlyMap configuration =
            ImmutableV1.of((Map<String, Integer>) DependencyV1.inject(Map<String, Integer>.class, CONFIG_ACTION));

    /**
     * @description
     * <p>
     * Constructor for the Scheduler.
     * <p>
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
     * <p>
     * Called to queue the next, non Scheduler job, to be run.
     * <p>
     * If there are no jobs to run, a pause is taken before getting the next job to run.
     * <p>
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
                JSON.deserialize(asyncJob.getState().get(JOBS_TO_START), Set<String>.class);

        if (jobsToStart.isEmpty()) {
            delayWhenNoJobsToRun((Integer) configuration.get(NO_JOBS_TO_RUN_DELAY_PROPERTY));

        } else {
            final String jobId = jobsToStart.iterator().next();

            try {
                final AsynchronousJob__c asyncObject = AsynchronousDAO.impl.getObject(jobId);
                asyncObject.ApexJobId__c = apexJobId;
                AsynchronousHelper.impl.queueJob(asyncObject);

            } catch(AssertionV1.AssertionException ae) {
                // An assertion exception indicates a problem with the job, so just ignore it.
                // The most likely cause is that the job has been deleted but was identified to start and so
                // still in the list of jobs to start.
            }

            jobsToStart.remove(jobId);
            asyncJob.setState(new Map<String, String> { JOBS_TO_START => JSON.serialize(jobsToStart) });
        }
    }

    /**
     * @description
     * <p>
     * A simple implementation of sleep.
     * <p>
     * Apex lacks a sleep method. To prevent having to go into a tight loop, a query that takes 20+ ms to complete
     * is run as often as possible.
     *
     * @param delay The number of milliseconds to delay processing for.
     */
    @SuppressWarnings('PMD.ApexCRUDViolation,PMD.UnusedLocalVariable,PMD.OperationWithLimitsInLoop')
    private static void delayWhenNoJobsToRun(final Integer delay) {
        final Long startTime = System.currentTimeMillis();
        final Long endTime = startTime + delay;

        for (; System.currentTimeMillis() < endTime; ) {
            if (Limits.getAggregateQueries() < 250) {
                List<SObject> ignore = [
                        SELECT Id,
                                (SELECT Id FROM Badges WHERE ImageUrl != 'ab'),
                                (SELECT Id FROM CombinedAttachments WHERE ContentUrl != 'ab'),
                                (SELECT Id FROM CommSubscriptionConsents WHERE ConsentCapturedSource != 'ab'),
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
     * <p>
     * Returns the maximum number of Schedulers that may be active for the user at any one time.
     * <p>
     * Running more than one Scheduler concurrently would break the synchronisation, so always use 1.
     *
     * @return The Scheduler concurrency.
     */
    public override Integer getMaximumActive() {
        return 1;
    }

    /**
     * @description
     * <p>
     * Called on successful execution of the Apex job for the Scheduler.
     *
     * @param asyncJob The Asynchronous job for the Scheduler.
     *
     * @return False to indicate that the Asynchronous__c for the job is to be deleted.
     */
    public override Boolean onSuccess(final AsynchronousV1.Job asyncJob) {
        AssertionV1.isNotNull(asyncJob, 'argument: AsynchronousScheduler.onSuccess.asyncJob');
        AsynchronousScheduler.queue(
                (Set<String>) JSON.deserialize(asyncJob.getState().get(JOBS_TO_START), Set<String>.class),
                1
        );
        return false;
    }

    /**
     * @description
     * <p>
     * Called on failed execution of the Apex job for the Scheduler.
     *
     * @param asyncJob The Asynchronous job for the Scheduler.
     * @param exc The Exception that caused the job to fail.
     *
     * @return True to indicate that the Asynchronous__c for the job is to be kept.
     */
    public override Boolean onFailure(final AsynchronousV1.Job asyncJob, final Exception exc) {
        AssertionV1.isNotNull(asyncJob, 'argument: AsynchronousScheduler.onFailure.asyncJob');
        AsynchronousScheduler.queue(
                (Set<String>) JSON.deserialize(asyncJob.getState().get(JOBS_TO_START), Set<String>.class),
                2   // Use 2 as Scheduler job being finalized will be in RUNNING or FINALIZING state,
        );
        return true;
    }

    /**
     * @description
     * <p>
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
     * <p>
     * Creates and queues for processing a new Scheduler job.
     * <p>
     * The processing logic for the Scheduler requires that the Asynchronous__c object for the new Scheduler job
     * is only persisted if an Apex job could be created for it.
     * <p>
     * The maxRunningSchedulers will be set to 2 in any calls from onSuccess or onFailure. This is because the
     * job being processed is for the scheduler and will still be set to FINALISING.
     *
     * @param jobsLeftToStart The jobs that are left to start from the previous scheduler run.
     * @param maxRunningSchedulers Do not start scheduler is it exceeds this value.
     */
    public static void queue(final Set<String> jobsLeftToStart, final Integer maxRunningSchedulers) {
        final AsynchronousV1.Job asyncJob;

        if (!jobsLeftToStart.isEmpty()) {
            asyncJob = AsynchronousAPI.impl.createJob(
                    RunNextAvailable.class,
                    String.format(SCHEDULER_JOB_REFERENCE, new List<Object> { jobsLeftToStart.size() }),
                    0,
                    0,
                    new Map<String, String> { JOBS_TO_START => JSON.serialize(jobsLeftToStart) }
            );

        } else {
            final Integer maximumJobs = (Integer) configuration.get(MAXIMUM_JOBS_TO_START_PROPERTY);
            final Set<String> newJobsToStart = getJobIdsToStart(maximumJobs);
            if (newJobsToStart.isEmpty() && (AsynchronousDAO.impl.countSchedulableObjects(maximumJobs, getActiveWindowSize()) == 0)) {
                return;
            }

            asyncJob = AsynchronousAPI.impl.createJob(
                    RunNextAvailable.class,
                    String.format(SCHEDULER_JOB_REFERENCE, new List<Object> { newJobsToStart.size() }),
                    0,
                    0,
                    new Map<String, String> { JOBS_TO_START => JSON.serialize(newJobsToStart) }
            );
        }

        // More than one running Scheduler would cause the synchronisation to fail.
        if (AsynchronousDAO.impl.countActiveObjects(
                new AsynchronousJob__c(Runnable__c = RunNextAvailable.class.getName()),
                getActiveWindowSize()
        ) < maxRunningSchedulers) {
            AsynchronousJob__c asyncObject = AsynchronousJob.toSObject(asyncJob);
            AsynchronousDAO.impl.persistObjects(
                    new List<AsynchronousJob__c> { asyncObject},
                    new List<Map<String, String>> { asyncJob.getState() }
            );
            AsynchronousHelper.impl.queueJob(asyncObject);
        }
    }

    /**
     * @description
     * <p>
     * Returns the ids of all the jobs that can be started.
     * <p>
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

        for (AsynchronousJob__c asyncObject : AsynchronousDAO.impl.getScheduledObjects(maxToStart)) {
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
                active = AsynchronousDAO.impl.countActiveObjects(asyncObject, getActiveWindowSize());
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
     * <p>
     * Determines the active window size.
     *
     * @return The active window size in seconds.
     */
    private static Integer getActiveWindowSize() {
        final Integer windowSize = (Integer) configuration.get(ACTIVE_JOBS_WINDOW_PROPERTY);
        return windowSize == null ? MIN_ACTIVE_JOB_WINDOW_SIZE : Math.max(windowSize, MIN_ACTIVE_JOB_WINDOW_SIZE);
    }

    /**
     * @description
     * <p>
     * Determines the number of jobs to be swept.
     *
     * @return The number of job to be swept.
     */
    private static Integer getMaximumJobsToSweep() {
        final Integer jobsToSweep = (Integer) configuration.get(MAXIMUM_JOBS_TO_SWEEP_PROPERTY);
        return jobsToSweep == null ? DEFAULT_MAX_JOBS_TO_SWEEP : Math.min(jobsToSweep, MIN_MAX_JOBS_TO_SWEEP);
    }

    /**
     * @description
     * <p>
     * Default Scheduler configuration to be injected.
     */
    public with sharing class Configuration implements TypesV1.Factory {
        @SuppressWarnings('PMD.ApexDoc')
        public Object newInstance() {
            return new Map<String, Integer> {
                    NO_JOBS_TO_RUN_DELAY_PROPERTY => 10000,
                    MAXIMUM_JOBS_TO_START_PROPERTY => 1,
                    ACTIVE_JOBS_WINDOW_PROPERTY => DEFAULT_ACTIVE_JOB_WINDOW_SIZE,
                    ACTIVE_JOBS_WINDOW_PROPERTY => DEFAULT_MAX_JOBS_TO_SWEEP
            };
        }
    }

    /**
     * @description
     * <p>
     * Load the Scheduler from a factory.
     * <p>
     * This allows the Scheduler class to be inaccessible from outside this class.
     */
    public with sharing class RunNextAvailable implements TypesV1.Factory {
        @SuppressWarnings('PMD.ApexDoc')
        public Object newInstance() {
            return new AsynchronousScheduler();
        }
    }

    /**
     * @description
     * <p>
     * Load the Sweeper from a factory.
     * <p>
     * This allows the Sweeper class to be inaccessible from outside this class.
     */
    public with sharing class RunSweeper implements TypesV1.Factory {
        @SuppressWarnings('PMD.ApexDoc')
        public Object newInstance() {
            return new Sweeper();
        }
    }

    /**
     * @description
     * <p>
     * Builds an optional Sweeper job that cleans up stale AsynchronousJob__c records.
     * <p>
     * A job is considered stale if:
     * <ul>
     *   <li>It is owned by the current user,</li>
     *   <li>Its Status__c is RUNNING or FINALIZING, and</li>
     *   <li>Its LastRunTime__c is older than the configured active window.</li>
     * </ul>
     * If no stale jobs are found, returns OptionalV1.empty(). Otherwise, returns an OptionalV1 containing
     * an AsynchronousV1.Job configured to execute the Sweeper (RunSweeper) with the stale jobs passed
     * in the job state as JSON (key: "staleJobs").
     *
     * @return Optional containing the Sweeper job if stale jobs exist; otherwise OptionalV1.empty().
     */
    public static OptionalV1 getSweeper() {
        if (AsynchronousDAO.impl.getSweepableObjects(1, getActiveWindowSize()).size() == 0) {
            return OptionalV1.empty();
        }

        return OptionalV1.of(
                AsynchronousV1.createJob(
                        RunSweeper.class,
                        'Sweeper',
                        0,
                        0,
                        new Map<String, String>()
                )
        );
    }

    /**
     * @description
     * Executes the Sweeper job that remediates stale AsynchronousJob__c records.
     * <p>
     * Stale jobs are those owned by the current user that have remained in an active state
     * (RUNNING or FINALIZING) beyond the configured active window. The Sweeper:
     * - Deserializes the list of stale jobs from the job state (key: "staleJobs").
     * - For Scheduler jobs: marks them FAILED and records an internal APIException.
     * - For non-Scheduler jobs: normalizes their Status__c to either QUEUED (if was RUNNING)
     *   or SUCCEEDED (if was FINALIZING), and stages them for update.
     * - Persists the updated AsynchronousJob__c records.
     * <p>
     * The class is constructed via the RunSweeper factory and should not be instantiated directly.
     */
    private with sharing class Sweeper extends AsynchronousV1.Runnable {

        public Sweeper() {
            super(RunSweeper.class);
        }

        public override void run(AsynchronousV1.Job asyncJob, String apexJobId) {
            final List<StaleJob> staleJobs = (List<StaleJob>)
                    ImmutableV1.of(AsynchronousDAO.impl.getSweepableObjects(getMaximumJobsToSweep(), getActiveWindowSize()))
                        .transform(new ToStaleJob(), new List<StaleJob>());

            final List<AsynchronousJob__c> updates = new List<AsynchronousJob__c>();
            for (StaleJob staleJob : staleJobs) {
                final OptionalV1 error = staleJob.getError();
                if (error.isPresent()) {
                    AsynchronousHelper.impl.recordInternalException(
                            staleJob.job,
                            (AsynchronousV1.APIException) error.get()
                    );
                } else {
                    updates.add(staleJob.job);
                }
            }

            // We cannot use the DAO as it disables the trigger.
            AsynchronousDAO.impl.persistObjects(updates, true);
        }
    }

    /**
     * @description
     * <p>
     * Callback implementation that transforms each queried AsynchronousJob__c into a StaleJob wrapper.
     */
    private with sharing class ToStaleJob extends ArrayV1.Callback {
        public override OptionalV1 function(Object element, OptionalV1 currentValue, Integer index) {
            final AsynchronousJob__c job = ((AsynchronousJob__c) element).clone(true);
            return OptionalV1.of(new StaleJob(job));
        }
    }

    /**
    * @description
    * <p>
    * Lightweight value object representing a “stale” AsynchronousJob__c detected by the Sweeper.
    * <p>
    * A job is considered stale when it remains in an active state (RUNNING or FINALIZING) beyond the
    * configured active window. The Sweeper converts the raw AsynchronousJob__c record into this wrapper
    * to:
    * <ul>
    *   <li>Normalize its next Status__c based on whether it is a Scheduler or a non-Scheduler job.</li>
    *   <li>Provide an OptionalV1 error describing why a Scheduler job is being failed.</li>
    * </ul>
    * <p>
    * Use getError() to retrieve the error to record for stale Scheduler jobs. Non-Scheduler jobs return empty.
    */
    @TestVisible
    private with sharing class StaleJob {
        public final AsynchronousJob__c job {
            public get;
            private set;
        }

        public StaleJob(final AsynchronousJob__c job) {
            this.job = job;
            if (isScheduler()) {
                job.Status__c = AsynchronousV1.Status.FAILED.name();
            } else {
                job.Status__c = job.Status__c == AsynchronousV1.Status.FINALIZING.name()
                        ? AsynchronousV1.Status.SUCCEEDED.name()
                        : AsynchronousV1.Status.PENDING.name();
            }
        }

        public OptionalV1 getError() {
            return isScheduler()
                    ? OptionalV1.of(
                            new AsynchronousV1.APIException(
                                    'Wrapper',
                                    new AsynchronousV1.APIException('Stale Scheduler found by Sweeper')
                            )
                    )
                    : OptionalV1.empty();
        }

        private Boolean isScheduler() {
            return job.Runnable__c == RunNextAvailable.class.getName();
        }
    }
}