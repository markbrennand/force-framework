/**
 * @description
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../../LICENSE target="_blank">MIT License</a>.
 * <br><br>
 * Class providing the default implementation of the Asynchronous API.
 * <br><br>
 * The default implementation of the API in this class uses the AsynchronousJob__c object to represent a job. The object
 * may be queried to find all the information about the job.
 * <br><br>
 * The implementation of the API is hidden in the private Implementation class. The class is hidden so an application
 * cannot access the class to mis-use it.
 * <br><br>
 * All application access is restricted to the API instance variable API. This ensures the application can only
 * ever call the methods of the API interface.
 * <br><br>
 * The outer class implements the API only to allow it to be mocked. Any calls to the API method implementations
 * in the outer class will throw an Exception.
 * <br><br>
 * See <a href=../README.md target="_blank">README</a> for full details of the Asynchronous API.
 *
 * @author Mark Brennand
 */
public with sharing virtual class AsynchronousAPI implements API {

    /**
     * @description
     * Active API instance.
     * <br><br>
     * The instance is injected from the Registry.
     * <br><br>
     * The instance is test visible so it can be mocked.
     */
    @TestVisible
    public static API API {
        public get {
            if (Test.isRunningTest() && API != null) { // API has been mocked.
                return API;
            } else {
                return (API) DependencyV1.inject(API.class);
            }
        }
        private set;
    }

    /**
     * @description
     * Interface defining the actions required for Asynchronous job management.
     * <br><br>
     * A new implementation of the Asynchronous framework must implement all the methods of this
     * interface. It can then add a Dependency Injection Binding and it will be injected in the
     * static methods of this class which provide the application access to create and queue jobs.
     * <br><br>
     * Any new implementations must also use their own implementation of the Job interface.
     */
    public interface API {

        /**
         * @description
         * Creates a new instance of a job to be managed by the framework.
         * <br><br>
         * The Apex class must implement the Runnable interface. If it doesn't, the implementation must throw an
         * exception.
         * <br><br>
         * The state is data specific to the job. It is passed to the Runnable for the job when it is invoked. It
         * can contain any data an application chooses. For example, it may include arguments specific to the job.
         *
         * @param type The Apex class of the job to be run.
         * @param reference The user's reference for the job.
         * @param maximumRetries The maximum number of retries to make before failing the job.
         * @param retryInterval The number of milliseconds between each re-try after failure.
         * @param state Job specific data.
         *
         * @return The job specific to the implementation.
         */
        AsynchronousV1.Job createJob(
                final Type type,
                final String reference,
                final Integer maximumRetries,
                final Integer retryInterval,
                final Map<String, String> state
        );

        /**
         * @description
         * Schedules the given job for processing.
         * <br><br>
         * The implementation should consider the jobs as available to run and take the appropriate action.
         *
         * @param asyncJobs The jobs to schedule for processing.
         *
         * @return The jobs queued for processing.
         */
        List<AsynchronousV1.Job> queueJobs(final List<AsynchronousV1.Job> asyncJobs);
    }

    /**
     * @description
     * Allow extension but not construction.
     * <br><br>
     * This is also required to support the Apex mocking classes. A private constructor cannot be mocked.
     */
    protected AsynchronousAPI() {}

    /**
     * @description
     * Class providing the implementation of the API.
     */
    private with sharing class Implementation implements API {

        /**
         * @description
         * Creates a new instance of a job to be managed by the default API implementation.
         * <br><br>
         * The Apex class must implement the Runnable interface. If it doesn't, the implementation will throw an
         * exception.
         * <br><br>
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
        public AsynchronousV1.Job createJob(
                final Type type,
                final String reference,
                final Integer maximumRetries,
                final Integer retryInterval,
                final Map<String, String> state
        ) {
            final AsynchronousJob__c asynchronousObject = new AsynchronousJob__c(
                    Status__c = AsynchronousV1.Status.PENDING.name(),
                    OwnerId = UserInfo.getUserId(),
                    Runnable__c = type.getName(),
                    Reference__c = reference,
                    MaximumRetries__c = maximumRetries,
                    RetryInterval__c = retryInterval,
                    ScheduledRunTime__c = Datetime.now(),
                    RetryNumber__c = 0
            );

            final AsynchronousV1.Job job = AsynchronousJob.fromSObject(asynchronousObject);
            job.setState(state);

            return job;
        }

        /**
         * @description
         * Schedules the given job for processing by the default API implementation.
         * <br><br>
         * Each job will have an AsynchronousJob__c object created for it. The job's state will be saved in the
         * AsynchronousState__c object.
         * <br><br>
         * The trigger on AsynchronousJob__c will validate the job. If the job is valid, the trigger will change the
         * Status to QUEUED and start an Asynchronous Scheduler to run the job.
         *
         * @param asyncJobs The jobs to schedule for processing.
         *
         * @return The jobs queued for processing.
         */
        public List<AsynchronousV1.Job> queueJobs(final List<AsynchronousV1.Job> asyncJobs) {
            Assertion.isNotNull(asyncJobs, 'argument: Asynchronous.queueJobs.asyncJobs');

            final List<AsynchronousJob__c> asyncObjects = new List<AsynchronousJob__c>();
            final List<Map<String, String>> states = new List<Map<String, String>>();

            for (AsynchronousV1.Job job : asyncJobs) {
                asyncObjects.add(AsynchronousJob.toSObject(job));
                states.add(job.getState());
            }

            AsynchronousDAO.API.persistObjects(asyncObjects, states);

            return (List<AsynchronousV1.Job>) ArrayV1.over(asyncObjects)
                    .sharing(states)
                    .reduce(new JobUpdater(), new List<AsynchronousV1.Job>());
        }
    }

    /**
     * Class called from Queueable for Apex Job.
     * <br><br>
     * Override the run method from a super-class to code the logic of the job.
     */
    public with sharing abstract class ApexJobRunnable implements AsynchronousV1.RunnableJob, Queueable {

        /**
         * @description
         * The sub-class of AsynchronousRunnable which is to be run for the Asynchronous__c object.
         */
        private final Type type;

        /**
         * @description
         * On execution, this field holds the Id of the Asynchronous__c object of the job being run.
         */
        @TestVisible
        private AsynchronousV1.Job asyncJob;

        /**
         * @description
         * Constructs an instance of the class which is a proxy for the sub-class to be run.
         *
         * @param type The sub-class to be run.
         */
        public ApexJobRunnable(final Type type) {
            this.type = type;
        }

        /**
         * @description
         * Called to execute the logic coded in the Runnable.
         * <br><br>
         * When the Asynchronous__c object is ready to run, an Apex job will be queued for it. When the Apex job reaches
         * the head of the run queue and is started, this method is called.
         * <br><br>
         * Any state changes made during the execution of the RunnableJob are preserved.
         * <br><br>
         * The run method must throw an Exception to indicate failure. If no Exception is thrown, the job will be
         * considered to have completed successfully.
         *
         * @param context The Salesforce context for the Apex job.
         */
        public void execute(final QueueableContext context) {
            final AsynchronousJob__c asynchronousJob = AsynchronousJob.toSObject(asyncJob);
            asynchronousJob.ApexJobId__c = context.getJobId();
            asynchronousJob.LastRunTime__c = Datetime.now();

            System.attachFinalizer(AsynchronousFinalizer.createFinalizer(asynchronousJob.Id));
            run(asyncJob, context.getJobId());

            AsynchronousDAO.API.persistObjects(
                    new List<AsynchronousJob__c>{
                            asynchronousJob
                    },
                    new List<Map<String, String>>{
                            asyncJob.getState()
                    }
            );
        }

        /**
         * @description
         * The class of the RunnableJob's implementation.
         * <br><br>
         * The class can either be a RunnableJob or Types.Factory implementation. In the case of the latter,
         * the class returned by the newInstance method must implement RunnableJob.
         *
         * @return The Apex class of the RunnableJob implementation.
         */
        public Type getType() {
            return type;
        }

        /**
         * @description
         * Method called when the Apex job is being run.
         * <br><br>
         * The method is called from the execute method of this class.
         * <br><br>
         * A developer must override this method and code the business logic the job needs to perform.
         * <br><br>
         * Ideally, this method would not be here as it should be considered abstract as its in the interface. The
         * Apex compiler has other ideas!
         *
         * @param asyncJob The job being run.
         * @param apexJobId The Id of the Apex job for the RunnableJob.
         */
        public abstract void run(final AsynchronousV1.Job asyncJob, final String apexJobId);

        /**
         * @description
         * Gets the Queueable to be run by an Apex job.
         *
         * @param asyncJob The Job representing the Asynchronous__c object being run.
         *
         * @return The RunnableJob to be run in an Apex job.
         */
        public AsynchronousV1.RunnableJob forJob(final AsynchronousV1.Job asyncJob) {
            this.asyncJob = asyncJob;
            return this;
        }
    }

    /**
     * @description
     * Creates the default API implementation.
     * <br><br>
     * The constructor for the implementation is protected. This prevents the Dependency framework constructing it.
     * We use the factory to defer the construction by injection to this class, which is able to construct it.
     */
    public with sharing class Factory implements TypesV1.Factory {
        public Object newInstance() {
            return new Implementation();
        }
    }

    /**
     * @description
     * Class providing check on Binding made to AsynchronousAPI.API.
     */
    public with sharing class BindingCheck implements DependencyV1.BindingCheck {

        /**
         * @description
         * Checks that a valid binding has been made to AsynchronousAPI.API.
         *
         * @param forType The type being bound to, AsynchronousAPI.API.
         * @param withImpl The implementation being bound to AsynchronousAPI.API.
         *
         * @return The result of the validation.
         */
        public DependencyV1.ValidationResult validate(final Type forType, final Type withImpl) {
            return DependencyHelper.buildValidationResult(
                    TypesV1.newInstance(withImpl) instanceof API,
                    true,
                    forType,
                    withImpl
            );
        }
    }

    /**
     * @description
     * Class called when building the List of AsynchronousV1.Job records to return after the associated jobs have
     * bgeen queued.
     */
    private with sharing class JobUpdater extends ArrayV1.Callback {
        public override Optional function(final Object element, final Optional currentValue, final Integer index) {
            final AsynchronousJob__c asyncObject = (AsynchronousJob__c) element;
            Assertion.isNotNull(asyncObject.Id, 'Asynchronous.Job object has not been assigned an Id');

            final AsynchronousV1.Job updatedJob = AsynchronousJob.fromSObject(asyncObject);
            updatedJob.setState(((List<Map<String, String>>) shared().get())[index]);

            ((List<AsynchronousV1.Job>) currentValue.get()).add(updatedJob);
            return Optional.of(currentValue.get());
        }
    }

    /**
     * @description
     * Method is solely for mocking use.
     */
    public AsynchronousV1.Job createJob(
            final Type type,
            final String reference,
            final Integer maximumRetries,
            final Integer retryInterval,
            final Map<String, String> state
    ) {
        throw new AsynchronousV1.APIException('Access denied');
    }

    /**
     * @description
     * Method is solely for mocking use.
     */
    public List<AsynchronousV1.Job> queueJobs(final List<AsynchronousV1.Job> asyncJobs) {
        throw new AsynchronousV1.APIException('Access denied');
    }

    // Set the default implementation of API. This can be overridden using a Dependency Injection Binding.
    static {
        DependencyV1.bind(API.class, Factory.class);
    }
}
