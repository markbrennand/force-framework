/**
 * @description
 * The Scheduler is responsible for finding the next job that can be run based on its scheduled time and that starting
 * the job would not exceed its concurrency.
 *
 * @author Mark Brennand
 */
public with sharing class AsynchronousScheduler extends AsynchronousRunnable {
    private final static String CONFIG_ACTION = 'AsynchronousConfiguration';
    private final static String MAX_SCHEDULERS_PROPERTY = 'maxSchedulers';
    private final static String NO_JOBS_TO_RUN_DELAY_PROPERTY = 'noJobsToRunDelay';

    static {
        Injection.bind(Map<String, Integer>.class, CONFIG_ACTION, Configuration.class);
        Injection.reload();
    }

    final Map<String, Integer> configuration =
            (Map<String, Integer>) Injection.wire(Map<String, Integer>.class, CONFIG_ACTION);

    public AsynchronousScheduler() {
        super(AsynchronousScheduler.class);
        Assertion.isNotNull(configuration.get(MAX_SCHEDULERS_PROPERTY), 'property; ' + CONFIG_ACTION + '.' + MAX_SCHEDULERS_PROPERTY);
        Assertion.isNotNull(configuration.get(NO_JOBS_TO_RUN_DELAY_PROPERTY), 'property; ' + CONFIG_ACTION + '.' + NO_JOBS_TO_RUN_DELAY_PROPERTY);
    }

    public override void run(final Asynchronous.Job ignoreAsyncJob) {
        Assertion.isNotNull(ignoreAsyncJob, 'parameter; AsynchronousScheduler.run.ignoreAsyncJob');

        if (AsynchronousDAO.countScheduledObjects(true) == 0) {
            delayWhenNoJobsToRun(configuration.get(NO_JOBS_TO_RUN_DELAY_PROPERTY));
        }

        final Asynchronous__c scheduledAsyncObject = AsynchronousDAO.getNextScheduled();
        if (scheduledAsyncObject != null) {
            AsynchronousJob.queueJob(scheduledAsyncObject);
        }
    }

    public static void delayWhenNoJobsToRun(final Integer delay) {
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

    public override Integer getMaximumActive() {
        if (AsynchronousDAO.countScheduledObjects(false) > 0) {
            if (AsynchronousDAO.countScheduledObjects(true) > 0) {
                return configuration.get(MAX_SCHEDULERS_PROPERTY);
            } else {
                return 1;
            }
        } else {
            return 1;
        }
    }

    public override Boolean onSuccess(final Asynchronous.Job asyncJob) {
        Assertion.isNotNull(asyncJob, 'parameter; AsynchronousScheduler.onSuccess.asyncJob');
        return false;
    }

    public override Boolean onFailure(final Asynchronous.Job asyncJob, final Exception exc) {
        Assertion.isNotNull(asyncJob, 'parameter; AsynchronousScheduler.onFailure.asyncJob');
        return true;
    }

    public override Boolean onCancellation(final Asynchronous.Job asyncJob) {
        Assertion.isNotNull(asyncJob, 'parameter; AsynchronousScheduler.onCancellation.asyncJob');
        return false;
    }

    public static void queue() {
        Asynchronous.Job asyncJob = Asynchronous.createJob(
                AsynchronousScheduler.class,
                null,
                0,
                0,
                new Map<String, String>()
        );

        AsynchronousJob.queueJob(AsynchronousJob.toSObject(asyncJob));
    }

    public with sharing class Configuration implements TypeHelper.Factory {
        public Object newInstance() {
            return new Map<String, Integer> {
                    MAX_SCHEDULERS_PROPERTY => 1,
                    NO_JOBS_TO_RUN_DELAY_PROPERTY => 2000
            };
        }
    }
}