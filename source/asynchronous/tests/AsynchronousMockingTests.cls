/**
 * @description
 * Unit tests to check that Asynchronous.API can be mocked.
 *
 * @author Mark Brennand
 */
@IsTest
public with sharing class AsynchronousMockingTests {

    @IsTest
    private static void testMockedAPI() {
        Asynchronous.INSTANCE = createMock();

        Asynchronous.Job job = Asynchronous.createJob(
                AsynchronousMockingTests.class,
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

    private static Asynchronous createMock() {
        Mocker jobMock = Mocker.of(AsynchronousJob.class);
        jobMock
                .whenNoArguments()
                    .expectMethod('getReference').called(1).returns('MOCKED')
                    .expectMethod('getStatus').called(1).returns(Asynchronous.Status.CANCELLED);

        Asynchronous.Job job = (Asynchronous.Job) jobMock.getMockedObject();

        Mocker asyncMock = Mocker.of(Asynchronous.class);
        asyncMock
                .whenArguments(
                        AsynchronousMockingTests.class,
                        null,
                        1,
                        1000,
                        new Map<String, String>()
                )
                    .expectMethod('apiCreateJob').returns(job)
                .whenArgument(new List<Asynchronous.Job> { job })
                    .expectMethod('apiQueueJobs').called(1);


        return (Asynchronous) asyncMock.getMockedObject();
    }
}