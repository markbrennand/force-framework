/**
 * @description
 * Unit tests for Asynchronous class.
 *
 * @author Mark Brennand
 */
@IsTest
public with sharing class AsynchronousTests {

    @IsTest
    private static void testCreateAndQueue() {
        Map<String, String> state = new Map<String, String> { 'Key1' => 'Value1', 'Key2' => 'Value2' };

        Asynchronous.Job job = Asynchronous.createJob(
                AsynchronousScheduler.QueueNext.class,
                'TEST',
                1,
                1000,
                state
        );

        Assert.isTrue(job.getRunnable() instanceof AsynchronousScheduler);
        Assert.areEqual('TEST', job.getReference());
        Assert.areEqual(1, job.getMaximumRetries());
        Assert.areEqual(1000, job.getRetryInterval());
        Assert.areEqual(0, job.getRetryNumber());
        Assert.areEqual(state, job.getState());
        Assert.areEqual(Asynchronous.Status.PENDING, job.getStatus());

        AsynchronousDAO.INSTANCE = (AsynchronousDAO) Mocker.of(AsynchronousDAO.class)
                .whenArguments(
                        new List<AsynchronousJob__c> { new AsynchronousJob__c(Status__c = Asynchronous.Status.PENDING.name())},
                        new List<Map<String, String>> { state }
                )
                    .expectMethod('apiPersistObjects').called(1)
                .mock();

        Asynchronous.queueJobs(new List<Asynchronous.Job> { job });
        Mocker.validate();
    }

    @IsTest
    private static void testMocking() {
        Asynchronous.INSTANCE = createMock();

        Asynchronous.Job job = Asynchronous.createJob(
                AsynchronousTests.class,
                null,
                1,
                1000,
                new Map<String, String>()
        );

        Assert.areEqual(Asynchronous.Status.CANCELLED, job.getStatus());
        Assert.areEqual('MOCKED', job.getReference());

        Asynchronous.queueJobs(new List<Asynchronous.Job> { job });

        Mocker.validate();
    }

    @IsTest
    private static void testBindingCheck() {
        Dependency.bind(Asynchronous.API.class, Asynchronous.Factory.class);
        try {
            Dependency.bind(Asynchronous.API.class, AsynchronousScheduler.QueueNext.class);
        } catch(Dependency.APIException ae) {
            Assert.areEqual('Class AsynchronousScheduler.QueueNext does not implement Asynchronous.API', ae.getMessage());
        }
    }

    private static Asynchronous createMock() {
        Asynchronous.Job job = (Asynchronous.Job) Mocker.of(AsynchronousJob.class)
                .whenNoArguments()
                    .expectMethod('getReference').called(1).returns('MOCKED')
                    .expectMethod('getStatus').called(1).returns(Asynchronous.Status.CANCELLED)
                .mock();

        return (Asynchronous) Mocker.of(Asynchronous.class)
                .whenArguments(
                        AsynchronousTests.class,
                        null,
                        1,
                        1000,
                        new Map<String, String>()
                )
                    .expectMethod('apiCreateJob').returns(job)
                .whenArgument(new List<Asynchronous.Job> { job })
                    .expectMethod('apiQueueJobs').called(1)
                .mock();
    }
}