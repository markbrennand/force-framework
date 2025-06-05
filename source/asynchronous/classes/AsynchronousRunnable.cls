/**
 * @description
 * Implementation of Runnable that classes may extend to make coding the logic of a job simpler.
 *
 * Default implementations of all the methods are coded in this class. They may be overridden.
 *
 * The run() method will need to be overridden to code the logic for the job.
 *
 * Classes extending this class must have a no-op constructor which calls the constructor for this class with
 * the Type of the extending class.
 *
 * @author Mark Brennand
 */
global with sharing virtual class AsynchronousRunnable implements Asynchronous.Runnable, Queueable {

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
    private Asynchronous.Job asyncJob;

    /**
     * @description
     * Constructs an instance of the class which is a proxy for the sub-class to be run.
     *
     * @param type The sub-class to be run.
     */
    global AsynchronousRunnable(final Type type) {
        this.type = type;
    }

    /**
     * @description
     * Called to execute the logic coded in the Runnable.
     *
     * When the Asynchronous__c object is ready to run, an Apex job will be queued for it. When the Apex job reaches
     * the head of the run queue and is started, this method is called.
     *
     * Any state changes made during the execution of the Runnable are preserved.
     *
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

        AsynchronousDAO.INJECT.persistObjects(
                new List<AsynchronousJob__c> { asynchronousJob },
                new List<Map<String, String>> { asyncJob.getState() }
        );
    }

    /**
     * @description
     * Method called when the Apex job for the Asynchronous__c object is being run.
     *
     * The method is called from the execute method of this class.
     *
     * A developer must override this method and code the business logic the job needs to perform.
     *
     * @param asyncJob The job being run.
     * @param apexJobId The Id of the Apex job for the Runnable.
     */
    global virtual void run(final Asynchronous.Job asyncJob, final String apexJobId) {}

    /**
     * @description
     * Returns the sub-class being proxied by its super-class.
     *
     * @return The Class of the sub-class.
     */
    global Type getType() {
        return type;
    }

    /**
     * @description
     * Returns the maximum number of concurrent executions of the Runnable that are allowed.
     *
     * If the concurrency is exceeded, a job will not be started.
     *
     * @return Maximum concurrent executions.
     */
    global virtual Integer getMaximumActive() {
        return 1;
    }

    /**
     * @description
     * Called on successful completion of the Asynchronous__c object for the class.
     *
     * To succeed, the class's run method must not have thrown an Exception when called.
     *
     * @param asyncJob The job that has succeeded.
     *
     * @return True if the Asynchronous__c object is to be kept, false if not.
     */
    global virtual Boolean onSuccess(final Asynchronous.Job asyncJob) {
        return true;
    }

    /**
     * @description
     * Called on failure to run the job after exhausting the Asynchronous__c object's re-tries.
     *
     * To fail, the class's run method must have thrown an Exception every time it was called.
     *
     * @param asyncJob The job that has failed.
     * @param exc The Exception that caused the last re-try for the job to fail.
     *
     * @return True if the Asynchronous__c object is to be kept, false if not.
     */
    global virtual Boolean onFailure(final Asynchronous.Job asyncJob, final Exception exc) {
        return true;
    }

    /**
     * @description
     * Called when an Asynchronous__c object has its status changed to CANCELLED.
     *
     * @param asyncJob The job that has been cancelled.
     *
     * @return True if the Asynchronous__c object is to be kept, false if not.
     */
    global virtual Boolean onCancellation(final Asynchronous.Job asyncJob) {
        return true;
    }

    /**
     * @description
     * Called when an Exception occurs during the running of an Asynchronous__c object and there are re-tries left to
     * be made.
     *
     * The status value returned by this method determines what happens to the job. Return QUEUED to re-try the
     * job. Return CANCELLED if the job is not to be re-tried and no further processing of it is to be made. The
     * onCancellation method of this class will be called.
     *
     * @param asyncJob The job the Exception was thrown for.
     * @param exc The Exception that was thrown.
     *
     * @return The new status for the job.
     */
    global virtual Asynchronous.Status onError(final Asynchronous.Job asyncJob, final Exception exc) {
        return Asynchronous.Status.QUEUED;
    }

    /**
     * @description
     * Gets the Queueable to be run by an Apex job.
     *
     * @param asyncJob The Job representing the Asynchronous__c object being run.
     *
     * @return The Runnable to be run in an Apex job.
     */
    public Asynchronous.Runnable forJob(final Asynchronous.Job asyncJob) {
        this.asyncJob = asyncJob;
        return this;
    }
}