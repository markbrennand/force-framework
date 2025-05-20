/**
 * @description
 * Implementation of Runnable that classes may extend to make coding the logic for a job simpler.
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
    private final Type type;
    private Asynchronous.Job asyncJob;

    global AsynchronousRunnable(final Type type) {
        this.type = type;
    }

    /**
     * @description
     * Called to execute the logic coded in the Runnable.
     *
     * When the job is ready to run, an Apex job will be queued for it. When the Apex job reaches the head of the run
     * queue and is started, this method is called.
     *
     * Any state changes made during the execution of the Runnable are preserved.
     *
     * The run method must return an Exception to indicate failure. If no Exception is thrown, the job will be
     * considered to have completed successfully.
     *
     * @param context The Salesforce context for the Apex job.
     */
    public void execute(final QueueableContext context) {
        final Asynchronous__c asynchronousJob = AsynchronousJob.toSObject(asyncJob);
        asynchronousJob.LastRunTime__c = Datetime.now();

        System.attachFinalizer(AsynchronousFinalizer.createFinalizer(asynchronousJob.Id));
        run(asyncJob);

        AsynchronousDAO.persistAsynchronous(
                new List<Asynchronous__c> { asynchronousJob },
                new List<Map<String, String>> { asyncJob.getState() }
        );
    }

    global virtual void run(Asynchronous.Job asyncJob) {}

    global Type getType() {
        return type;
    }

    global virtual Integer getMaximumActive() {
        return 1;
    }

    global virtual Boolean onSuccess(final Asynchronous.Job asyncJob) {
        return true;
    }

    global virtual Boolean onFailure(final Asynchronous.Job asyncJob, final Exception exc) {
        return true;
    }

    global virtual Boolean onCancellation(final Asynchronous.Job asyncJob) {
        return true;
    }

    global virtual Asynchronous.Status onError(final Asynchronous.Job asyncJob, final Exception exc) {
        return Asynchronous.Status.QUEUED;
    }

    public Asynchronous.Runnable forJob(final Asynchronous.Job asyncJob) {
        this.asyncJob = asyncJob;
        return this;
    }
}