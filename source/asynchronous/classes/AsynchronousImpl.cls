/**
 * @description
 * Class providing the default implementation of the Asynchronous API.
 * <br><br>
 * The default implementation of the API in this class uses the AsynchronousJob__c object to represent a job. The object
 * may be queried to find all the information about the job.
 * <br><br>
 * The implementation of the API is hidden in the private Implementation class. The class is hidden so an application
 * cannot access the class to mis-use it.
 * <br><br>
 * All application access is restricted to the API instance variable INJECT. This ensures the application can only
 * ever call the methods of the API interface.
 * <br><br>
 * The outer class implements the API only to allow it to be mocked. Any calls to the API method implementations
 * in the outer class will throw an Exception.
 * <br><br>
 * See <a href=../README.md target="_blank">README</a> for full details of the Asynchronous API.
 *
 * @author Mark Brennand
 */
public with sharing virtual class AsynchronousImpl implements AsynchronousV1.API {

    /**
     * @description
     * Active API instance.
     * <br><br>
     * The instance is injected from the Registry.
     * <br><br>
     * The instance is test visible so it can be mocked.
     */
    @TestVisible
    public static AsynchronousV1.API INJECT {
        public get {
            if (Test.isRunningTest() && INJECT != null) { // INJECT has been mocked.
                return INJECT;
            } else {
                return (AsynchronousV1.API) DependencyV1.inject(AsynchronousV1.API.class);
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
    protected AsynchronousImpl() {}

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
     * Class providing the implementation of the API.
     */
    private with sharing class Implementation implements AsynchronousV1.API {

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

            AsynchronousDAO.INJECT.persistObjects(asyncObjects, states);

            final List<AsynchronousV1.Job> returnList = new List<AsynchronousV1.Job>();
            Integer i = 0;

            for (AsynchronousJob__c asyncObject : asyncObjects) {
                Assertion.isNotNull(asyncObject.Id, 'Asynchronous.Job object has not been assigned an Id');

                final AsynchronousV1.Job updatedJob = AsynchronousJob.fromSObject(asyncObject);
                updatedJob.setState(states[i++]);
                returnList.add(updatedJob);
            }

            return returnList;
        }
    }

    /**
     * @description
     * Processes any persisted AsynchronousJob__c objects before they are added to the database.
     * <br><br>
     * Validation is performed on the objects.
     * <br><br>
     * If all objects are valid, their status is set to QUEUED and an Asynchronous Scheduler is started to run them.
     *
     * @param asyncObjects The persisted objects.
     */
    public static void onTriggerBefore(final List<AsynchronousJob__c> asyncObjects) {
        Boolean hasErrors = false;

        for (AsynchronousJob__c asyncObject : asyncObjects) {
            try {
                final Object runnable = TypesV1.newInstance(TypesV1.load(asyncObject.Runnable__c));
                if (! (runnable instanceof AsynchronousV1.Runnable)) {
                    asyncObject.addError('Class ' + asyncObject.Runnable__c + ' does not implement Asynchronous.Runnable');
                    hasErrors = true;

                } else if (asyncObject.Status__c == AsynchronousV1.Status.PENDING.name()) {
                    asyncObject.Status__c = AsynchronousV1.Status.QUEUED.name();
                    asyncObject.RetryNumber__c = 0;
                }

            } catch(Exception e) {
                asyncObject.addError(e.getMessage());
                hasErrors = true;
            }
        }
    }

    /**
     * @description
     * Processes any persisted AsynchronousJob__c objects after they have been added to the database.
     * <br><br>
     * Any new cancellations are processed.
     *
     * @param asyncObjects The persisted objects.
     * @param previousAsyncObjects The previous values of the persisted objects.
     */
    public static void onTriggerAfter(final List<AsynchronousJob__c> asyncObjects, final Map<Id, AsynchronousJob__c> previousAsyncObjects) {
        final List<AsynchronousJob__c> toDelete = new List<AsynchronousJob__c>();
        Boolean startScheduler = false;

        for (AsynchronousJob__c asyncObject : asyncObjects) {
            final Boolean isScheduler = AsynchronousJob.fromSObject(asyncObject).getRunnable() instanceof AsynchronousScheduler;

            if (asyncObject.Status__c == AsynchronousV1.Status.CANCELLED.name() &&
                    asyncObject.Status__c != previousAsyncObjects?.get(asyncObject.Id)?.Status__c
            ) {
                final AsynchronousV1.Job asyncJob = AsynchronousJob.fromSObject(asyncObject);
                if (!asyncJob.getRunnable().onCancellation(asyncJob)) {
                    toDelete.add(new AsynchronousJob__c(Id = asyncObject.Id));
                }
            } else if (!isScheduler) {
                startScheduler = true;
            }
        }

        AsynchronousDAO.INJECT.removeObjects(toDelete);

        if (startScheduler) {
            AsynchronousScheduler.queue(new Set<String>());
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

    // Set the default implementation of the API. This can be overridden using a Dependency Injection Binding.
    static {
        DependencyV1.bind(AsynchronousV1.API.class, Factory.class);
    }
}