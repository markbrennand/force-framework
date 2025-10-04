/**
 * @description
 * <p>
 * Implementation classes for Asynchronous API.
 * <p>
 * Implementation is private to prevent re-use.
 * <p>
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../LICENSE target="_blank">MIT License</a>.
 * 
 * @author Mark Brennand
 */
public with sharing class AsynchronousImpl {

    /**
     * @description
     * <p>
     * Class providing the implementation of the API.
     */
    private with sharing class API implements AsynchronousAPI.API {

        /**
         * @description
         * <p>
         * Creates a new instance of a job to be managed by the default API implementation.
         * <p>
         * The Apex class must implement the Runnable interface. If it doesn't, the implementation will throw an
         * exception.
         * <p>
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
                    ScheduledRunTime__c = CommonHelper.now(),
                    RetryNumber__c = 0
            );

            final AsynchronousV1.Job job = AsynchronousJob.fromSObject(asynchronousObject);
            job.setState(state);

            return job;
        }

        /**
         * @description
         * <p>
         * Schedules the given job for processing by the default API implementation.
         * <p>
         * Each job will have an AsynchronousJob__c object created for it. The job's state will be saved in the
         * AsynchronousState__c object.
         * <p>
         * The trigger on AsynchronousJob__c will validate the job. If the job is valid, the trigger will change the
         * Status to QUEUED and start an Asynchronous Scheduler to run the job.
         *
         * @param asyncJobs The jobs to schedule for processing.
         *
         * @return The jobs queued for processing.
         */
        public List<AsynchronousV1.Job> queueJobs(final List<AsynchronousV1.Job> asyncJobs) {
            AssertionV1.isNotNull(asyncJobs, 'argument: Asynchronous.queueJobs.asyncJobs');

            final List<AsynchronousJob__c> asyncObjects = new List<AsynchronousJob__c>();
            final List<Map<String, String>> states = new List<Map<String, String>>();

            for (AsynchronousV1.Job job : asyncJobs) {
                asyncObjects.add(AsynchronousJob.toSObject(job));
                states.add(job.getState());
            }

            AsynchronousDAO.impl.persistObjects(asyncObjects, states);

            return (List<AsynchronousV1.Job>) ArrayV1.over(asyncObjects)
                    .sharing(states)
                    .reduce(new JobUpdater(), new List<AsynchronousV1.Job>());
        }
    }

    /**
     * @description
     * <p>
     * Class called from Queueable for Apex Job.
     * <p>
     * Override the run method from a super-class to code the logic of the job.
     */
    public with sharing abstract class ApexJobRunnable implements AsynchronousV1.RunnableJob, Queueable {

        /**
         * @description
         * <p>
         * The sub-class of AsynchronousRunnable which is to be run for the Asynchronous__c object.
         */
        private final Type type;

        /**
         * @description
         * <p>
         * On execution, this field holds the Id of the Asynchronous__c object of the job being run.
         */
        @TestVisible
        private AsynchronousV1.Job asyncJob;

        /**
         * @description
         * <p>
         * Constructs an instance of the class which is a proxy for the sub-class to be run.
         *
         * @param type The sub-class to be run.
         */
        public ApexJobRunnable(final Type type) {
            this.type = type;
        }

        /**
         * @description
         * <p>
         * Called to execute the logic coded in the Runnable.
         * <p>
         * When the Asynchronous__c object is ready to run, an Apex job will be queued for it. When the Apex job reaches
         * the head of the run queue and is started, this method is called.
         * <p>
         * Any state changes made during the execution of the RunnableJob are preserved.
         * <p>
         * The run method must throw an Exception to indicate failure. If no Exception is thrown, the job will be
         * considered to have completed successfully.
         *
         * @param context The Salesforce context for the Apex job.
         */
        public void execute(final QueueableContext context) {
            final AsynchronousJob__c asynchronousJob = AsynchronousJob.toSObject(asyncJob);
            asynchronousJob.ApexJobId__c = context.getJobId();
            asynchronousJob.LastRunTime__c = CommonHelper.now();

            System.attachFinalizer(AsynchronousFinalizer.createFinalizer(asynchronousJob.Id));
            run(asyncJob, context.getJobId());

            AsynchronousDAO.impl.persistObjects(
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
         * <p>
         * The class of the RunnableJob's implementation.
         * <p>
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
         * <p>
         * Method called when the Apex job is being run.
         * <p>
         * The method is called from the execute method of this class.
         * <p>
         * A developer must override this method and code the business logic the job needs to perform.
         * <p>
         * Ideally, this method would not be here as it should be considered abstract as its in the interface. The
         * Apex compiler has other ideas!
         *
         * @param asyncJob The job being run.
         * @param apexJobId The Id of the Apex job for the RunnableJob.
         */
        public abstract void run(final AsynchronousV1.Job asyncJob, final String apexJobId);

        /**
         * @description
         * <p>
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
     * <p>
     * Class called when building the List of AsynchronousV1.Job records to return after the associated jobs have
     * been queued.
     */
    private with sharing class JobUpdater extends ArrayV1.Callback {
        public override OptionalV1 function(final Object element, final OptionalV1 currentValue, final Integer index) {
            final AsynchronousJob__c asyncObject = (AsynchronousJob__c) element;
            AssertionV1.isNotNull(asyncObject.Id, 'Asynchronous.Job object has not been assigned an Id');

            final AsynchronousV1.Job updatedJob = AsynchronousJob.fromSObject(asyncObject);
            updatedJob.setState(((List<Map<String, String>>) shared().get())[index]);

            ((List<AsynchronousV1.Job>) currentValue.get()).add(updatedJob);
            return currentValue;
        }
    }

    /**
     * @description
     * <p>
     * Creates the default API implementation.
     * <p>
     * The constructor for the implementation is protected. This prevents the Dependency framework constructing it.
     * We use the factory to defer the construction by injection to this class, which is able to construct it.
     */
    public with sharing class Factory implements TypesV1.Factory {

        /**
         * @description
         * <p>
         * Returns the implementation of the API.
         *
         * @return The API implementation.
         */
        public Object newInstance() {
            return new API();
        }
    }

}