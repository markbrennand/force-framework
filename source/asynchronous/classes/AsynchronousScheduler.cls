/**
 * MIT License
 *
 * Copyright (c) 2025 Mark Brennand
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */
/**
 * @description
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

    /*
     * Initialise the registry.
     *
     * We have to do this before the property wiring of the CONFIGURATION.
     */
    static {
        DependencyV1.bind(Map<String, Integer>.class, CONFIG_ACTION, Configuration.class);
        DependencyV1.reload();
    }

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
     * The number of jobs to be run that the Scheduler should select in the queue method.
     */
    @TestVisible
    private final static String MAXIMUM_JOBS_TO_START_PROPERTY = 'maximumJobsToStart';

    /**
     * @description
     * Configuration options for thge Scheduler.
     *
     * Test visible to it can be overridden from unit tests.
     */
    @TestVisible
    private static Map<String, Integer> CONFIGURATION =
            (Map<String, Integer>) DependencyV1.inject(Map<String, Integer>.class, CONFIG_ACTION);

    /**
     * @description
     * Constructor for the Scheduler.
     *
     * The constructor is private to prevent construction from anywhere other than the factory (QueueNext class).
     */
    @TestVisible
    private AsynchronousScheduler() {
        super(RunNextAvailable.class);
        Assertion.isNotNull(CONFIGURATION.get(NO_JOBS_TO_RUN_DELAY_PROPERTY), 'property; ' + CONFIG_ACTION + '.' + NO_JOBS_TO_RUN_DELAY_PROPERTY);
        Assertion.isNotNull(CONFIGURATION.get(MAXIMUM_JOBS_TO_START_PROPERTY), 'property; ' + CONFIG_ACTION + '.' + MAXIMUM_JOBS_TO_START_PROPERTY);
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

        final Set<String> jobsToStart = (Set<String>)
                JSON.deserialize(asyncJob.getState().get(AsynchronousFinalizer.JOBS_TO_START), Set<String>.class);

        if (jobsToStart.isEmpty()) {
            delayWhenNoJobsToRun(CONFIGURATION.get(NO_JOBS_TO_RUN_DELAY_PROPERTY));

        } else {
            final String jobId = jobsToStart.iterator().next();

            try {
                final AsynchronousJob__c asyncObject = AsynchronousDAO.API.getObject(jobId);
                asyncObject.ApexJobId__c = apexJobId;
                AsynchronousHelper.API.queueJob(asyncObject);

            } catch(Assertion.AssertionException ae) {
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
     *
     * @param jobsLeftToStart The jobs that are left to start from the previous scheduler run.
     */
    public static void queue(final Set<String> jobsLeftToStart) {
        final Asynchronous.Job asyncJob;

        if (!jobsLeftToStart.isEmpty()) {
            asyncJob = AsynchronousAPI.API.createJob(
                    RunNextAvailable.class,
                    null,
                    0,
                    0,
                    new Map<String, String> { AsynchronousFinalizer.JOBS_TO_START => JSON.serialize(jobsLeftToStart) }
            );

        } else {
            final Set<String> newJobsToStart = getJobIdsToStart(CONFIGURATION.get(MAXIMUM_JOBS_TO_START_PROPERTY));
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
     *
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
                        ((Asynchronous.Runnable) TypesV1.newInstance(TypesV1.load(asyncObject.Runnable__c)))
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
     *
     * This allows the Scheduler class to be inaccessible from outside this class.
     */
    public with sharing class RunNextAvailable implements TypesV1.Factory {
        public Object newInstance() {
            return new AsynchronousScheduler();
        }
    }
}
