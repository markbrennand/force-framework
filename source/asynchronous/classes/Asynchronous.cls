/**
 * @description
 * Class providing the Asynchronous framework.
 *
 * All access to the framework must be through this class.
 *
 * The API interface defines the contract that implementations must provide to the methods of this class to create
 * and run jobs asynchronously. The implementation may be overridden using an Injection Binding.
 *
 * The default implementation of the API in this class uses the Asynchronous__c object to represent a job. The object
 * may be queried to find all the information about the job.
 *
 * See [Asynchronous](https://github.com/markbrennand/sf-frameworks/blob/main/source/asynchronous/README.md)
 *
 * @author Mark Brennand
 */
global with sharing virtual class Asynchronous implements API {

    /**
     * @description
     * Defines the status of an AsynchronousJob__c object under the control of this framework.
     *
     * A job can only be in a single state at any one time.
     *
     * PENDING - The job has been created but a job has not been queued for it.
     *
     * QUEUED - The job has been queued for processing.
     *
     * RUNNING - The job is running.
     *
     * SUCCEEDED - The job ran to completion successfully.
     *
     * FAILED - The last job failed to run and the maximum number of retries has been exceeded.
     *
     * CANCELLED - The job has been cancelled.
     */
    global enum Status {
        PENDING,
        QUEUED,
        RUNNING,
        SUCCEEDED,
        FAILED,
        CANCELLED
    }

    /**
     * @description
     * Interface defining the actions required for Asynchronous job management.
     *
     * All implementations must also use their own implementation of the Job interface.
     */
    global interface API {

        /**
         * @description
         * Creates a new instance of a job to be managed by the framework.
         *
         * The Apex class must implement the Runnable interface. If it doesn't, the implementation must throw an
         * exception.
         *
         * The state is data specific to the job. It is passed to the Runnable for the job when it is invoked. It
         * can contain any data an application chooses. For example, it may include arguments specific to the job.
         *
         * @param type The Apex class of the job to be run.
         * @param reference The user's reference for the job.
         * @param maximumRetries The maximum number of retries to make before failing the job.
         * @param retryInterval The number of milliseconds between each re-try event.
         * @param state Job specific data.
         *
         * @return The job specific to the implementation.
         */
        Job apiCreateJob(
                Type type,
                String reference,
                Integer maximumRetries,
                Integer retryInterval,
                Map<String, String> state
        );

        /**
         * @description
         * Schedules the given job for processing.
         *
         * The implementation should consider the jobs as available to run and take the appropriate action.
         *
         * @param asyncJobs The jobs to schedule for processing.
         */
        void apiQueueJobs(List<Job> asyncJobs);
    }

    /**
     * @description
     * Interface defining the logic specific to a job run by the framework.
     *
     * When the job is run by the framework, the job specific implementation of this interface is created and
     * its run method is called. As a new Runnable instance is created each time the job is run, implementations
     * of this interface cannot preserve state in member variables. The Job's state can be used for that.
     *
     * Concurrency is controlled by the maximum active value. Any implementation of the API must guarantee that
     * no more than this number of instances of the Runnable may be active at any one time.
     *
     * The AsynchronousRunnable class provides a full implementation of this interface. If possible you should
     * use this class and only override the methods you need behaviour other than the default for.
     */
    global interface Runnable {

        /**
         * @description
         * The class of the Runnable's implementation.
         *
         * The class can either be a Runnable or TypeHelper.Factory implementation. In the case of the latter,
         * the class returned by the newInstance method must implement Runnable.
         *
         * @return The Apex class of the Runnable implementation.
         */
        Type getType();

        /**
         * @description
         * Concurrency is controlled by the Runnable's implementation.
         *
         * The maximum active value defines how many instances of the Runnable's implementation may be active
         * concurrently. Any implementation of the API interface must guarantee that this value is enforced.
         *
         * @return The maximum number of active instances.
         */
        Integer getMaximumActive();

        /**
         * @description
         * Called when the job is run by the framework.
         *
         * Any job specific data set in the state when the job was created can be accessed from the state in the job
         * argument.
         *
         * @param asyncJob The job being run.
         */
        void run(Job asyncJob);

        /**
         * @description
         * Called when a job has run to completion successfully in the framework.
         *
         * The return value indicates whether the API implementation is to keep a record of the job or delete it.
         *
         * @param asyncJob The job that ran to completion.
         *
         * @return Whether to delete a record of the job or not.
         */
        Boolean onSuccess(Job asyncJob);

        /**
         * @description
         * Called when a job has failed to run and all is re-tries have been exhausted.
         *
         * The return value indicates whether the API implementation is to keep a record of the job or delete it.
         *
         * @param asyncJob The job that failed.
         * @param exc The Exception that caused the job to fail on its last execution.
         *
         * @return Whether to delete a record of the job or not.
         */
        Boolean onFailure(Job asyncJob, Exception exc);

        /**
         * @description
         * Called when a job has been cancelled.
         *
         * The return value indicates whether the API implementation is to keep a record of the job or delete it.
         *
         * @param asyncJob The job that has been cancelled.
         *
         * @return Whether to delete a record of the job or not.
         */
        Boolean onCancellation(Job asyncJob);

        /**
         * @description
         * An API implementation must call this method each time an Exception is caught when running a job.
         *
         * The Exception will be thrown from the Runnable.run method. A Status of QUEUED should be returned in
         * most circumstances to re-try the job. Say, for example though, that a particular type of Exception was
         * thrown that meant the job would always fail, a Status of CANCELLED could be returned to indicate no
         * further re-tries are to be performed.
         *
         * The return value indicates new Status value to assign to the job.
         *
         * @param asyncJob The job that has been cancelled.
         * @param exc The exception caught by the framework whilst running the job.
         *
         * @return The new Status of the job.
         */
        Status onError(Job asyncJob, Exception exc);
    }

    /**
     * @description
     * Information about a job being managed by the framework.
     *
     * The implementation will be specific to the API implementation.
     */
    global interface Job {

        /**
         * @description
         * Return the current status of the job managed by the API implementation.
         *
         * @return The jobs's status.
         */
        Status getStatus();

        /**
         * @description
         * Returns the id of the user the job is being run for by the API implementation.
         *
         * @return The user id.
         */
        String getOwnerId();

        /**
         * @description
         * Returns the Runnable implementation for ths job managed by the API implementation.
         *
         * @return The Runnable implementation.
         */
        Runnable getRunnable();

        /**
         * @description
         * Returns the state information assigned to the job on creation by the API implementation.
         *
         * The state may be updated by the call to Runnable.run for the job, though only when no Exception is thrown
         * by the method.
         *
         * @return The job's state.
         */
        Map<String, String> getState();

        /**
         * @description
         * Sets a new state for the job managed by the API implementation
         *
         * New state will only be preserved if the Apex request it is set within does not throw an Exception.
         *
         * @param state The new state.
         */
        void setState(Map<String, String> state);

        /**
         * @description
         * Reurns the user's reference assigned to the job on creation by the API implementation.
         *
         * @return The reference.
         */
        String getReference();

        /**
         * @description
         * Returns the maximum number of re-tries to be made to process the job by the API implementation if it fails
         * to run.
         *
         * Each re-try will be made if the Runnable.run method throws an Exception.
         *
         * @return The maximum number.
         */
        Integer getMaximumRetries();

        /**
         * @description
         * The current number of re-tries made by the API implementation for the job.
         *
         * Re-try number 0 is the first attempt to run it.
         *
         * @return The current re-try number.
         */
        Integer getRetryNumber();

        /**
         * @description
         * Returns the number of re-tries that are remaining to be made by the API implementation for the job.
         *
         * @return Number of re-tries remaining.
         */
        Integer getRetriesRemaining();

        /**
         * @description
         * Returns the number of milliseconds that the implementation of the API will wait between re-try attempts.
         *
         * @return The number of milliseconds.
         */
        Integer getRetryInterval();

        /**
         * @description
         * Returns the date and time at which the API implementation is next scheduled to run the job.
         *
         * @return The date and time.
         */
        Datetime getScheduledRunTime();

        /**
         * @description
         * Returns the date and time at which the API implementation last run the job.
         *
         * @return The date and time.
         */
        Datetime getLastRunTime();
    }

    /**
     * @description
     * Exception thrown when an operation in the Asynchronous framework fails.
     */
    global with sharing class APIException extends Exception {}

    /**
     * @description
     * Allow extension but not construction.
     *
     * This is also required to support the Apex mocking classes. A private constructor cannot be mocked.
     */
    protected Asynchronous() {}

    /**
     * @description
     * Creates a new instance of a job to be managed by the default API implementation.
     *
     * The Apex class must implement the Runnable interface. If it doesn't, the implementation will throw an
     * exception.
     *
     * The state is data specific to the job. It is passed to the Runnable for the job when it is invoked. It
     * can contain any data an application chooses. For example, it may include arguments specific to the job.
     *
     * @param type The Apex class of the job to be run.
     * @param reference The user's reference for the job.
     * @param maximumRetries The maximum number of retries to make before failing the job.
     * @param retryInterval The number of milliseconds between each re-try event.
     * @param state Job specific data.
     *
     * @return The job.
     */
    public Job apiCreateJob(
            final Type type,
            final String reference,
            final Integer maximumRetries,
            final Integer retryInterval,
            final Map<String, String> state
    ) {
        final Asynchronous__c asynchronousObject = new Asynchronous__c(
                Status__c = Status.PENDING.name(),
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

    /**
     * @description
     * Schedules the given job for processing by the default API implementation.
     *
     * Each job will have an Asynchronous__c object created for it. The job's state will be saved in the
     * AsynchronousState__c object.
     *
     * The trigger on Asynchronous__c will validate the job. If the job is valid, the trigger will change the
     * Status to QUEUED and start an Asynchronous Scheduler to run the job.
     *
     * @param asyncJobs The jobs to schedule for processing.
     */
    public void apiQueueJobs(final List<Asynchronous.Job> asyncJobs) {
        Assertion.isNotNull(asyncJobs, 'parameter; Asynchronous.queueJobs.asyncJobs');

        final List<Asynchronous__c> asyncObjects = new List<Asynchronous__c>();
        final List<Map<String, String>> states = new List<Map<String, String>>();

        for (Asynchronous.Job job : asyncJobs) {
            asyncObjects.add(AsynchronousJob.toSObject(job));
            states.add(job.getState());
        }

        AsynchronousDAO.persistAsynchronous(asyncObjects, states);
    }

    /**
     * @description
     * Creates a new instance of a job to be managed by the framework.
     *
     * All job creation by an application must be solely through this method.
     *
     * The job, once created, can be started by calling the queue method.
     *
     * @param type The Apex class of the job to be run.
     * @param reference The user's reference for the job.
     * @param maximumRetries The maximum number of retries to make before failing the job.
     * @param retryInterval The number of milliseconds between each re-try event.
     * @param state Job specific data.
     *
     * @return The job.
     *
     * @example
     * // Creates a job with reference 'Test'.
     * // The Runnable implementation class it MyTest.
     * // The maximum number of re-tries is 4 with an interval of 10 seconds between each.
     * // The 'argument' for the job can be obtained by MyTest.run(asyncJob) from AsyncJob.getState().get('argument').
     * Asynchronous.Job example = Asynchronous.create(
     *     MyJob.class,
     *     'Test',
     *     4,
     *     10000,
     *     new Map<String, String> { 'argument' => 'Example' }
     * );
     */
    global static Job createJob(
            final Type type,
            final String reference,
            final Integer maximumRetries,
            final Integer retryInterval,
            final Map<String, String> state
    ) {
        return INSTANCE.apiCreateJob(type, reference, maximumRetries, retryInterval, state);
    }

    /**
     * @description
     * Schedules the given job for processing by the framework.
     *
     * All job scheduling by an application must be solely through this method.
     *
     * @param asyncJobs The jobs to schedule for processing.
     *
     * @example
     * // Queues a job for processing.
     * Asynchronous.Job example = Asynchronous.create(
     *     MyJob.class,
     *     'Test',
     *     4,
     *     10000,
     *     new Map<String, String> { 'argument' => 'Example' }
     * );
     *
     * Asynchronous.queue(new List<Asynchronous.Job> { example });
     */
    global static void queueJobs(final List<Asynchronous.Job> asyncJobs) {
        INSTANCE.apiQueueJobs(asyncJobs);
    }

    /**
     * @description
     * Creates the default API implementation.
     *
     * The constructor for the implementation is protected. This prevents the Injection framework constructing it.
     * We use the factory to defer the construction by injection to this class, which is able to construct it.
     */
    public with sharing class Factory implements TypeHelper.Factory {
        public Object newInstance() {
            return new Asynchronous();
        }
    }

    /**
     * @description
     * Processes any persisted Asynchronous__c objects before they are added to the database.
     *
     * Validation is performed on the objects.
     *
     * If all objects are valid, their status is set to QUEUED and an Asynchronous Scheduler is started to run them.
     *
     * @param asyncObjects The persisted objects.
     */
    public static void onTriggerBefore(final List<Asynchronous__c> asyncObjects) {
        Boolean hasErrors = false;
        Boolean startScheduler = false;

        for (Asynchronous__c asyncObject : asyncObjects) {
            try {
                if (!(TypeHelper.newInstance(TypeHelper.loadType(asyncObject.Runnable__c)) instanceof Asynchronous.Runnable)) {
                    asyncObject.addError('Class ' + asyncObject.Runnable__c + ' does not implement Asynchronous.Runnable');
                    hasErrors = true;

                } else if (asyncObject.Status__c == Asynchronous.Status.PENDING.name()) {
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
     * Processes any persisted Asynchronous__c objects after they have been added to the database.
     *
     * Any new cancellations are processed.
     *
     * @param asyncObjects The persisted objects.
     * @param previousAsyncObjects The previous values of the persisted objects.
     */
    public static void onTriggerAfter(final List<Asynchronous__c> asyncObjects, final Map<Id, Asynchronous__c> previousAsyncObjects) {
        final List<Asynchronous__c> toDelete = new List<Asynchronous__c>();

        for (Asynchronous__c asyncObject : asyncObjects) {
            if (asyncObject.Status__c == Asynchronous.Status.CANCELLED.name() &&
                    asyncObject.Status__c != previousAsyncObjects.get(asyncObject.Id)?.Status__c
            ) {
                final Asynchronous.Job asyncJob = AsynchronousJob.fromSObject(asyncObject);
                if (!asyncJob.getRunnable().onCancellation(asyncJob)) {
                    toDelete.add(new Asynchronous__c(Id = asyncObject.Id));
                }
            }
        }

        AsynchronousDAO.removeAsynchronous(toDelete);
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

    // Set the default implementation of the API. This can be overridden using an Injection Binding.
    static {
        Injection.bind(API.class, Asynchronous.Factory.class);
    }

    /**
     * @description
     * Active API instance.
     *
     * The instance is wired in from the Registry.
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