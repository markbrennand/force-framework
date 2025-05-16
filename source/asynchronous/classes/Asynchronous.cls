/**
 * @description
 * Class providing asynchronous job creation and management.
 *
 * @author Mark Brennand
 */
global with sharing virtual class Asynchronous implements API {

    static {
        Injection.add(API.class, Asynchronous.Factory.class);
    }

    /**
     * @description
     * Defines the status of a AsynchronousJob__c under the control of this framework.
     *
     * A job can only be in a single state at any one time.
     *
     * CREATED - The job has been created but no AsynchronousJob__c object has been persisted for it.
     *
     * QUEUED - The AsynchronousJob__c has been queued for processing.
     *
     * RUNNING - An Apex job has been created for the AsynchronousJob__c and scheduled.
     *
     * FINISHED - The Apex Job for the AsynchronousJob__c ran successfully.
     *
     * FAILED - The last Apex Job for the AsynchronousJob__c failed to run and the maximum number of retries has been exceeded.
     */
    global enum Status {
        CREATED,
        QUEUED,
        RUNNING,
        FINISHED,
        FAILED,
        CANCELLED
    }

    global interface API {
        Job createJob(
                Type type,
                String reference,
                Integer maximumRetries,
                Integer retryInterval,
                Map<String, String> state
        );

        void queueJobs(List<Job> asyncJobs);
    }

    global interface Runnable {
        Type getType();
        Integer getMaximumActive();
        void run(Job asyncJob);
        Boolean onSuccess(Job asyncJob);
        Boolean onFailure(Job asyncJob);
        Boolean onCancel(Job asyncJob);
        Status onError(Job asyncJob, Exception exc);
    }

    global interface Job {
        Status getStatus();
        String getOwnerId();
        Runnable getRunnable();
        Map<String, String> getState();
        void setState(Map<String, String> state);
        String getReference();
        Integer getMaximumRetries();
        Integer getRetryNumber();
        Integer getRetriesRemaining();
        Integer getRetryInterval();
        Datetime getScheduledRunTime();
        Datetime getLastRunTime();
    }

    /**
     * @description
     * Exception thrown when an asynchronous operation fails.
     */
    global with sharing class APIException extends Exception {}

    protected Asynchronous() {}

    public Job createJob(
            final Type type,
            final String reference,
            final Integer maximumRetries,
            final Integer retryInterval,
            final Map<String, String> state
    ) {
        final Asynchronous__c asynchronousObject = new Asynchronous__c(
                Status__c = Status.CREATED.name(),
                OwnerId = UserInfo.getUserId(),
                Runnable__c = type.getName(),
                Reference__c = reference,
                MaximumRetries__c = maximumRetries,
                RetryInterval__c = retryInterval,
                ScheduledRunTime__c = Datetime.now(),
                RetryNumber__c = 0
        );

        final Job job = AsynchronousJob.fromSObject(asynchronousObject);
        job.setState(state);

        return job;
    }

    public void queueJobs(final List<Asynchronous.Job> asyncJobs) {
        Assert.isNotNull(asyncJobs, 'parameter; Asynchronous.queueJobs.asyncJobs');

        final List<Asynchronous__c> asyncObjects = new List<Asynchronous__c>();
        final List<Map<String, String>> states = new List<Map<String, String>>();

        for (Asynchronous.Job job : asyncJobs) {
            asyncObjects.add(AsynchronousJob.toSObject(job));
            states.add(job.getState());
        }

        AsynchronousDAO.persist(asyncObjects, states);
    }

    global static Job create(
            final Type type,
            final String reference,
            final Integer maximumRetries,
            final Integer retryInterval,
            final Map<String, String> state
    ) {
        return INSTANCE.createJob(type, reference, maximumRetries, retryInterval, state);
    }

    global static void queue(final List<Asynchronous.Job> asyncJobs) {
        INSTANCE.queueJobs(asyncJobs);
    }

    public with sharing class Factory implements TypeHelper.Factory {
        public Object newInstance() {
            return new Asynchronous();
        }
    }

    public static void onTriggerBefore(final List<Asynchronous__c> asyncObjects) {
        Boolean hasErrors = false;
        Boolean startScheduler = false;

        for (Asynchronous__c asyncObject : asyncObjects) {
            try {
                if (!(TypeHelper.newInstance(TypeHelper.loadType(asyncObject.Runnable__c)) instanceof Asynchronous.Runnable)) {
                    asyncObject.addError('Class ' + asyncObject.Runnable__c + ' does not implement Asynchronous.Runnable');
                    hasErrors = true;
                } else if (asyncObject.Status__c == Asynchronous.Status.CREATED.name()) {
                    asyncObject.Status__c = Asynchronous.Status.QUEUED.name();
                    asyncObject.RetryNumber__c = 0;
                    if (asyncObject.Runnable__c != AsynchronousScheduler.class.getName()) {
                        startScheduler = true;
                    }
                }
            } catch(Exception e) {
                asyncObject.addError(e.getMessage());
                hasErrors = true;
            }
        }

        if (!hasErrors && startScheduler) {
            AsynchronousScheduler.queue();
        }
    }

    /**
     * @description
     * Class providing check on Binding made to Asynchronous.API.
     */
    public with sharing class BindingCheck implements Injection.BindingCheck {

        /**
         * @description
         * Checks that a valid binding has been made to Asynchronous.API.
         *
         * @param forType The type being bound to, Asynchronous.API.
         * @param withImpl The implementation being bound to Asynchronous.API.
         *
         * @return The result of the validation.
         */
        public Injection.ValidationResult validate(Type forType, Type withImpl) {
            if (TypeHelper.newInstance(withImpl) instanceof Asynchronous.API) {
                return new Injection.ValidationResult(true, null);
            } else {
                return new Injection.ValidationResult(
                        false,
                        'Class ' + withImpl.getName() + ' does not implement ' + forType.getName()
                );
            }
        }
    }

    /**
     * @description
     * Active API instance.
     *
     * The instance is wired in from the registry.
     *
     * The instance is test visible so it can be mocked.
     */
    @TestVisible
    private static API INSTANCE {
        private get {
            if (INSTANCE == null) {
                INSTANCE = (API) Injection.wire(API.class);
            }
            return INSTANCE;
        }
        private set;
    }
}