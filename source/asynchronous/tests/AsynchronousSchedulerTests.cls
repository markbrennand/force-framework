/**
 * @description
 * Unit tests for Asynchronous Scheduler.
 *
 * @author Mark Brennand
 */
@IsTest
public with sharing class AsynchronousSchedulerTests {

    @IsTest
    private static void testNullJobArgument() {
        try {
            new AsynchronousScheduler().run(null, 'ApexJobId');
            Assert.fail();
        } catch(Assertion.AssertionException ae) {}
    }

    @IsTest
    private static void testDelayedWhenNoJobsToRun() {
        AsynchronousDAO.INSTANCE = (AsynchronousDAO) Mocker.of(AsynchronousDAO.class)
                .whenArgument(true)
                    .expectMethod('apiCountScheduledObjects').called(1).returns(0)
                .whenNoArguments()
                    .expectMethod('apiGetNextScheduled').called(1).returns(null)
                .mock();

        AsynchronousScheduler scheduler = new AsynchronousScheduler();
        scheduler.configuration = new Map<String, Integer> {
                AsynchronousScheduler.NO_JOBS_TO_RUN_DELAY_PROPERTY => 5000
        };

        Long started = System.currentTimeMillis();
        scheduler.run((Asynchronous.Job) Mocker.of(AsynchronousJob.class).mock(), 'ApexJobId');

        Assert.isTrue((System.currentTimeMillis() - started) >= 5000);
        Mocker.validate();
    }

    @IsTest
    private static void testNoJobToRun() {
        AsynchronousDAO.INSTANCE = (AsynchronousDAO) Mocker.of(AsynchronousDAO.class)
                .whenArgument(true)
                    .expectMethod('apiCountScheduledObjects').called(1).returns(1)
                .whenNoArguments()
                    .expectMethod('apiGetNextScheduled').called(1).returns(null)
                .mock();

        AsynchronousScheduler scheduler = new AsynchronousScheduler();
        scheduler.run((Asynchronous.Job) Mocker.of(AsynchronousJob.class).mock(), 'ApexJobId');
        Mocker.validate();
    }

    @IsTest
    private static void testJobToRun() {
        AsynchronousJob__c job = new AsynchronousJob__c(
                Id = TestHelper.nextId(AsynchronousJob__c.SObjectType),
                Status__c = Asynchronous.Status.QUEUED.name(),
                Runnable__c = AsynchronousScheduler.QueueNext.class.getName(),
                RetryNumber__c = 0,
                MaximumRetries__c = 10,
                RetryInterval__c = 1000,
                ScheduledRunTime__c = Datetime.now()
        );

        AsynchronousHelper.INSTANCE = (AsynchronousHelper) Mocker.of(AsynchronousHelper.class)
                .whenArgument(job)
                    .expectMethod('apiQueueJob').called(1).returns(true)
                .mock();

        AsynchronousDAO.INSTANCE = (AsynchronousDAO) Mocker.of(AsynchronousDAO.class)
                .whenArgument(true)
                    .expectMethod('apiCountScheduledObjects').called(1).returns(1)
                .whenNoArguments()
                    .expectMethod('apiGetNextScheduled').called(1).returns(job)
                .mock();

        AsynchronousScheduler scheduler = new AsynchronousScheduler();
        scheduler.run((Asynchronous.Job) Mocker.of(AsynchronousJob.class).mock(), 'ApexJobId');
        Mocker.validate();
    }

    @IsTest
    private static void testGetMaximumActive() {

        // SCENARIO: There are more queued jobs than the configured max and a job is running.
        // OUTCOME: The maximum number of Schedulers configured should be returned.
        AsynchronousDAO.INSTANCE = (AsynchronousDAO) Mocker.of(AsynchronousDAO.class)
                .whenArgument(false)
                    .expectMethod('apiCountScheduledObjects').called(1).returns(9)
                .whenArgument(true)
                    .expectMethod('apiCountScheduledObjects').called(1).returns(1)
                .whenArgument(new AsynchronousJob__c(Runnable__c = AsynchronousScheduler.QueueNext.class.getName()))
                    .expectMethod('apiCountActiveObjects').called(1).returns(0)
                .mock();

        AsynchronousScheduler scheduler = new AsynchronousScheduler();
        scheduler.configuration = new Map<String, Integer> {
                AsynchronousScheduler.MAX_SCHEDULERS_PROPERTY => 8
        };

        Assert.areEqual(8, scheduler.getMaximumActive(), 'Unexpected maximum schedulers');
        Mocker.validate();

        // SCENARIO: There are less queued jobs than the configured max and a job is running.
        // OUTCOME: The number of queued jobs should be returned.
        AsynchronousDAO.INSTANCE = (AsynchronousDAO) Mocker.of(AsynchronousDAO.class)
                .whenArgument(false)
                .expectMethod('apiCountScheduledObjects').called(1).returns(7)
                .whenArgument(true)
                .expectMethod('apiCountScheduledObjects').called(1).returns(1)
                .whenArgument(new AsynchronousJob__c(Runnable__c = AsynchronousScheduler.QueueNext.class.getName()))
                .expectMethod('apiCountActiveObjects').called(1).returns(0)
                .mock();

        Assert.areEqual(7, scheduler.getMaximumActive(), 'Unexpected maximum schedulers');
        Mocker.validate();

        // SCENARIO: There are queued jobs but no running jobs.
        // OUTCOME: 1 should be returned to keep the Scheduler running.
        AsynchronousDAO.INSTANCE = (AsynchronousDAO) Mocker.of(AsynchronousDAO.class)
                .whenArgument(false)
                    .expectMethod('apiCountScheduledObjects').called(1).returns(1)
                .whenArgument(true)
                    .expectMethod('apiCountScheduledObjects').called(1).returns(0)
                .mock();

        Assert.areEqual(1, scheduler.getMaximumActive(), 'Unexpected maximum schedulers');
        Mocker.validate();

        // SCENARIO: There are no queued or running jobs.
        // OUTCOME: 1 should be returned. This will keep the Scheduler running and the Finalizer decides whether to start  it again.
        AsynchronousDAO.INSTANCE = (AsynchronousDAO) Mocker.of(AsynchronousDAO.class)
                .whenArgument(false)
                    .expectMethod('apiCountScheduledObjects').called(1).returns(0)
                .mock();

        Assert.areEqual(1, scheduler.getMaximumActive(), 'Unexpected maximum schedulers');
        Mocker.validate();
    }

    @IsTest
    private static void testRunnableReturnValues() {
        AsynchronousScheduler scheduler = new AsynchronousScheduler();

        Assert.isFalse(scheduler.onSuccess((Asynchronous.Job) Mocker.of(AsynchronousJob.class).mock()));
        Assert.isTrue(scheduler.onFailure((Asynchronous.Job) Mocker.of(AsynchronousJob.class).mock(), new DMLException('Test')));
        Assert.isFalse(scheduler.onCancellation((Asynchronous.Job) Mocker.of(AsynchronousJob.class).mock()));
    }
}