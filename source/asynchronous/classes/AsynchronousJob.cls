/**
 * @description
 * <p>
 * Implementation of the Asynchronous.Job interface for use by the default implementation of the framework.
 * <p>
 * The class is virtual so other implementations may re-use it. The constructor, though, is protected so the
 * class may only be extended and never instantiated outside the default implementation.
 * <p>
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../LICENSE target="_blank">MIT License</a>.
 *
 * @author Mark Brennand
 */
public with sharing virtual class AsynchronousJob implements AsynchronousV1.Job {

    /**
     * @description
     * <p>
     * The Id of the AsynchronousJob__c object in the data store for the job.
     */
    @TestVisible
    private String asyncObjectId;

    /**
     * @description
     * <p>
     * Current status of the job.
     */
    private AsynchronousV1.Status status;

    /**
     * @description
     * <p>
     * The Id of the user the Asynchronous framework is managing the job for.
     */
    private String ownerId;

    /**
     * @description
     * <p>
     * The runnable class providing the logic to be run asynchronously.
     */
    private AsynchronousV1.Runnable runnable;

    /**
     * @description
     * <p>
     * The active state for the job.
     * <p>
     * The state is the work area for the job. It can be used to pass arguments to the job. Store data to be
     * saved on job completion. Modify data between retries. etc.
     * <p>
     * State can be updated by the Runnable. Any changes will be preserved on return of control to the Asynchronous
     * framework. The state will not be preserved if the Runnable throws an Exception.
     */
    private Map<String, String> state;

    /**
     * @description
     * <p>
     * The user assigned reference for the job.
     */
    private String reference;

    /**
     * @description
     * <p>
     * The maximum number of retries that will be made to re-run the job after initial failure.
     */
    private Integer maximumRetries;

    /**
     * @description
     * <p>
     * The number of milliseconds to wait between retries.
     */
    private Integer retryInterval;

    /**
     * @description
     * <p>
     * The number of retries made or that will be made when the job is next run.
     */
    private Integer retryNumber;

    /**
     * @description
     * <p>
     * The date and time at which the job is next scheduled to run.
     */
    private Datetime scheduledRunTime;

    /**
     * @description
     * <p>
     * The date and time at which the job last ran.
     * <p>
     * The value in this field will be set by the Asynchronous Scheduler when the Apex job is queued. If the
     * Runnable called by the job does not throw an Exception, the value will be updated to the timestamp at
     * which the Runnable's run method was called.
     */
    private Datetime lastRunTime;

    /**
     * @description
     * <p>
     * Allow extension but not modification.
     */
    @SuppressWarnings('PMD.EmptyStatementBlock')
    protected AsynchronousJob() {}

    /**
     * @description
     * <p>
     * Gets the id of the AsynchronousJob__c object representing the job.
     *
     * @return The object Id.
     */
    private String getAsyncObjectId() {
        return asyncObjectId;
    }

    /**
     * @description
     * <p>
     * Sets the id of the AsynchronousJob__c object representing the job.
     *
     * @param asyncObjectId The new job id.
     *
     * @return The current instance of the class, so the calls can be chained.
     */
    private AsynchronousJob withAsyncObjectId(final String asyncObjectId) {
        this.asyncObjectId = asyncObjectId;
        return this;
    }

    /**
     * @description
     * <p>
     * Returns the current status of the job.
     *
     * @return The job status.
     */
    public AsynchronousV1.Status getStatus() {
        return status;
    }

    /**
     * @description
     * <p>
     * Sets the status of the job to new value.
     *
     * @param status The new status for the job.
     *
     * @return The current instance of the class, so the calls can be chained.
     */
    private AsynchronousJob withStatus(final String status) {
        AssertionV1.isNotNull(status, 'argument: AsynchronousJob.withStatus.status');
        this.status = AsynchronousV1.Status.valueOf(status);
        return this;
    }

    /**
     * @description
     * <p>
     * Gets the Id of the user the Asynchronous framework is managing the job for.
     *
     * @return The Id of the user.
     */
    public String getOwnerId() {
        return ownerId;
    }

    /**
     * @description
     * <p>
     * Sets the owner id of the job to new value.
     *
     * @param ownerId The new owner id for the job.
     *
     * @return The current instance of the class, so the calls can be chained.
     */
    private AsynchronousJob withOwnerId(final String ownerId) {
        AssertionV1.isNotNull(ownerId, 'argument: AsynchronousJob.withOwnerId.ownerId');
        this.ownerId = ownerId;
        return this;
    }

    /**
     * @description
     * <p>
     * Gets the runnable class providing the logic to be executed asynchronously.
     *
     * @return The runnable class.
     */
    public AsynchronousV1.RunnableJob getRunnable() {
        return runnable;
    }

    /**
     * @description
     * <p>
     * Sets the class providing the logic to be executed asynchronously.
     *
     * @param runnableTypeName The class providing the logic.
     *
     * @return The current instance of the class, so the calls can be chained.
     */
    private AsynchronousJob withRunnable(final String runnableTypeName) {
        AssertionV1.isNotNull(runnableTypeName, 'argument: AsynchronousJob.withRunnable.runnableTypeName');

        final Object runnable = TypesV1.newInstance(TypesV1.load(runnableTypeName));
        AssertionV1.isTrue(
                 runnable instanceof AsynchronousV1.Runnable,
                'The class ' + runnableTypeName + ' does not implement AsynchronousV1.Runnable'
        );

        this.runnable = (AsynchronousV1.Runnable) runnable;
        return this;
    }

    /**
     * @description
     * <p>
     * Gets the active state associated with the job.
     *
     * @return The active state.
     */
    public Map<String, String> getState() {
        return state;
    }

    /**
     * @description
     * <p>
     * Sets the active state for the job.
     *
     * @param state The state.
     */
    public void setState(final Map<String, String> state) {
        AssertionV1.isNotNull(state, 'argument: AsynchronousJob.setState.state');
        this.state = state;
    }

    /**
     * @description
     * <p>
     * Gets the user assigned reference for the job.
     *
     * @return The reference.
     */
    public String getReference() {
        return reference;
    }

    /**
     * @description
     * <p>
     * Sets the user assigned reference for the job.
     *
     * @param reference The reference.
     *
     * @return The current instance of the class, so the calls can be chained.
     */
    private AsynchronousJob withReference(final String reference) {
        this.reference = reference;
        return this;
    }

    /**
     * @description
     * <p>
     * Gets the maximum number of retries that will be made to re-run the job after initial failure.
     *
     * @return The number of retries.
     */
    public Integer getMaximumRetries() {
        return maximumRetries;
    }

    /**
     * @description
     * <p>
     * Sets the maximum number of retries that will be made to re-run the job after initial failure.`
     *
     * @param maximumRetries The number of retries.
     *
     * @return The current instance of the class, so the calls can be chained.
     */
    private AsynchronousJob withMaximumRetries(final Integer maximumRetries) {
        AssertionV1.isNotNull(maximumRetries, 'argument: AsynchronousJob.withMaximumRetries.maximumRetries');
        AssertionV1.isTrue(maximumRetries >= 0, 'Maximum retries must be 0 or greater');
        this.maximumRetries = maximumRetries;
        return this;
    }

    /**
     * @description
     * <p>
     * Gets the number of milliseconds to wait between retries.
     *
     * @return The number of milliseconds.
     */
    public Integer getRetryInterval() {
        return retryInterval;
    }

    /**
     * @description
     * <p>
     * Sets the number of milliseconds to wait between retries.
     *
     * @param retryInterval The number of milliseconds.
     *
     * @return The current instance of the class, so the calls can be chained.
     */
    private AsynchronousJob withRetryInterval(final Integer retryInterval) {
        AssertionV1.isNotNull(retryInterval, 'argument: AsynchronousJob.withRetryInterval.retryInterval');
        AssertionV1.isTrue(retryInterval >= 0, 'Retry interval must be 0 or greater');
        this.retryInterval = retryInterval;
        return this;
    }

    /**
     * @description
     * <p>
     * Gets number of retries made or that will be made when the job is next run.
     *
     * @return The number of retries made.
     */
    public Integer getRetryNumber() {
        return retryNumber;
    }

    /**
     * @description
     * <p>
     * Sets the number of retries made or that will be made when the job is next run.
     *
     * @param retryNumber The number of retries made.
     *
     * @return The current instance of the class, so the calls can be chained.
     */
    private AsynchronousJob withRetryNumber(final Integer retryNumber) {
        AssertionV1.isNotNull(retryNumber, 'argument: AsynchronousJob.withRetryNumber.retryNumber');
        AssertionV1.isTrue(retryNumber >= 0, 'Retry number must be 0 or greater');
        this.retryNumber = retryNumber;
        return this;
    }

    /**
     * @description
     * <p>
     * Determines the number of retries that remain to be made for the job.
     *
     * @return The number of retries that remain.
     */
    public Integer getRetriesRemaining() {
        return maximumRetries - retryNumber;
    }

    /**
     * @description
     * <p>
     * Gets the date and time at which the job is next scheduled to run.
     *
     * @return The date and time.
     */
    public Datetime getScheduledRunTime() {
        return scheduledRunTime;
    }

    /**
     * @description
     * <p>
     * Sets the date and time at which the job is next scheduled to run.
     *
     * @param scheduledRunTime The date and time.
     *
     * @return The current instance of the class, so the calls can be chained.
     */
    private AsynchronousJob withScheduledRunTime(final Datetime scheduledRunTime) {
        AssertionV1.isNotNull(scheduledRunTime, 'argument: AsynchronousJob.withScheduledRunTime.scheduledRunTime');
        this.scheduledRunTime = scheduledRunTime;
        return this;
    }

    /**
     * @description
     * <p>
     * Gets the date and time at which the job last ran.
     *
     * @return The date and time.
     */
    public Datetime getLastRunTime() {
        return lastRunTime;
    }

    /**
     * @description
     * <p>
     * Sets the date and time at which the job last ran.
     *
     * @param lastRunTime The date and time.
     *
     * @return The current instance of the class, so the calls can be chained.
     */
    private AsynchronousJob withLastRunTime(final Datetime lastRunTime) {
        this.lastRunTime = lastRunTime;
        return this;
    }

    /**
     * @description
     * <p>
     * Given an AsynchronousJob__c object fetched from the data store and its associated state data, this method
     * return the equivalent internal representation.
     *
     * @param asyncObject The AsynchronousJob__c object for the job.
     *
     * @return The internal representation.
     */
    public static AsynchronousV1.Job fromSObject(final AsynchronousJob__c asyncObject) {
        AssertionV1.isNotNull(asyncObject, 'argument: AsynchronousJob.fromSObject.asyncObject');

        final Map<String, String> state =
                asyncObject.AsynchronousJobState__r.isEmpty()
                        ? new Map<String, String>()
                        : AsynchronousHelper.API.decodeState(asyncObject.AsynchronousJobState__r);

        final AsynchronousV1.Job asyncJob = new AsynchronousJob()
                .withAsyncObjectId(asyncObject.Id)
                .withStatus(asyncObject.Status__c)
                .withOwnerId(String.valueOf(asyncObject.OwnerId))
                .withRunnable(asyncObject.Runnable__c)
                .withReference(asyncObject.Reference__c)
                .withMaximumRetries((Integer) asyncObject.MaximumRetries__c)
                .withRetryInterval((Integer) asyncObject.RetryInterval__c)
                .withRetryNumber((Integer) asyncObject.RetryNumber__c)
                .withScheduledRunTime(asyncObject.ScheduledRunTime__c)
                .withLastRunTime(asyncObject.LastRunTime__c);

        asyncJob.setState(state);
        return asyncJob;
    }

    /**
     * @description
     * <p>
     * Given an internal representation of a job, this method returns the equivalent AsynchronousJob__c object.
     *
     * @param asyncJob The internal representation of a job.
     *
     * @return The AsynchronousJob__c object.
     */
    public static AsynchronousJob__c toSObject(final AsynchronousV1.Job asyncJob) {
        AssertionV1.isNotNull(asyncJob, 'argument: AsynchronousJob.toSObject.asyncJob');
        return new AsynchronousJob__c(
                Id = ((AsynchronousJob) asyncJob).getAsyncObjectId(),
                OwnerId = asyncJob.getOwnerId(),
                Status__c = asyncJob.getStatus().name(),
                Reference__c = asyncJob.getReference(),
                Runnable__c = asyncJob.getRunnable().getType().getName(),
                MaximumRetries__c = asyncJob.getMaximumRetries(),
                RetryInterval__c = asyncJob.getRetryInterval(),
                RetryNumber__c = asyncJob.getRetryNumber(),
                ScheduledRunTime__c = asyncJob.getScheduledRunTime(),
                LastRunTime__c = asyncJob.getLastRunTime()
        );
    }
}