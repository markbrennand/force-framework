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
public with sharing virtual class AsynchronousAPI implements Asynchronous.API {

    /**
     * @description
     * Active API instance.
     * <br><br>
     * The instance is injected from the Registry.
     * <br><br>
     * The instance is test visible so it can be mocked.
     */
    @TestVisible
    public static Asynchronous.API API {
        public get {
            if (Test.isRunningTest() && API != null) { // API has been mocked.
                return API;
            } else {
                return (Asynchronous.API) DependencyV1.inject(Asynchronous.API.class);
            }
        }
        private set;
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
    private with sharing class Implementation implements Asynchronous.API {

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
        public Asynchronous.Job createJob(
                final Type type,
                final String reference,
                final Integer maximumRetries,
                final Integer retryInterval,
                final Map<String, String> state
        ) {
            final AsynchronousJob__c asynchronousObject = new AsynchronousJob__c(
                    Status__c = Asynchronous.Status.PENDING.name(),
                    OwnerId = UserInfo.getUserId(),
                    Runnable__c = type.getName(),
                    Reference__c = reference,
                    MaximumRetries__c = maximumRetries,
                    RetryInterval__c = retryInterval,
                    ScheduledRunTime__c = Datetime.now(),
                    RetryNumber__c = 0
            );

            final Asynchronous.Job job = AsynchronousJob.fromSObject(asynchronousObject);
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
        public List<Asynchronous.Job> queueJobs(final List<Asynchronous.Job> asyncJobs) {
            Assertion.isNotNull(asyncJobs, 'argument: Asynchronous.queueJobs.asyncJobs');

            final List<AsynchronousJob__c> asyncObjects = new List<AsynchronousJob__c>();
            final List<Map<String, String>> states = new List<Map<String, String>>();

            for (Asynchronous.Job job : asyncJobs) {
                asyncObjects.add(AsynchronousJob.toSObject(job));
                states.add(job.getState());
            }

            AsynchronousDAO.API.persistObjects(asyncObjects, states);

            final List<Asynchronous.Job> returnList = new List<Asynchronous.Job>();
            Integer i = 0;

            for (AsynchronousJob__c asyncObject : asyncObjects) {
                Assertion.isNotNull(asyncObject.Id, 'Asynchronous.Job object has not been assigned an Id');

                final Asynchronous.Job updatedJob = AsynchronousJob.fromSObject(asyncObject);
                updatedJob.setState(states[i++]);
                returnList.add(updatedJob);
            }

            return returnList;
        }
    }

    /**
     * @description
     * Method is solely for mocking use.
     */
    public Asynchronous.Job createJob(
            final Type type,
            final String reference,
            final Integer maximumRetries,
            final Integer retryInterval,
            final Map<String, String> state
    ) {
        throw new Asynchronous.APIException('Access denied');
    }

    /**
     * @description
     * Method is solely for mocking use.
     */
    public List<Asynchronous.Job> queueJobs(final List<Asynchronous.Job> asyncJobs) {
        throw new Asynchronous.APIException('Access denied');
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
     * Class providing check on Binding made to AsynchronousV1.API.
     */
    public with sharing class BindingCheck implements Dependency.BindingCheck {

        /**
         * @description
         * Checks that a valid binding has been made to AsynchronousV1.API.
         *
         * @param forType The type being bound to, AsynchronousV1.API.
         * @param withImpl The implementation being bound to AsynchronousV1.API.
         *
         * @return The result of the validation.
         */
        public Dependency.ValidationResult validate(Type forType, Type withImpl) {
            return DependencyHelper.buildValidationResult(
                    TypesV1.newInstance(withImpl) instanceof Asynchronous.API,
                    true,
                    forType,
                    withImpl
            );
        }
    }

    // Set the default implementation of API. This can be overridden using a Dependency Injection Binding.
    static {
        DependencyV1.bind(Asynchronous.API.class, AsynchronousAPI.Factory.class);
    }
}
