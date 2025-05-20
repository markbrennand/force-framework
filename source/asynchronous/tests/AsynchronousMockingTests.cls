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
        Asynchronous mockAsynchronous = createMock();
        Asynchronous.INSTANCE = mockAsynchronous;

        Asynchronous.Job job = Asynchronous.createJob(
                AsynchronousMockingTests.class,
                null,
                1,
                1000,
                new Map<String, String>()
        );

        Assert.areEqual(Asynchronous.Status.CANCELLED, job.getStatus());
        Assert.areEqual('MOCKED', job.getReference());

        Mock.stubMethod(mockAsynchronous, 'queueJobs')
                .withArguments(new List<Object>{ new List<Asynchronous.Job> { job } })
                .expected(1);

        Asynchronous.queueJobs(new List<Asynchronous.Job> { job });

        Mock.validate(mockAsynchronous);
    }

    private static Asynchronous createMock() {
        AsynchronousJob jobMock = (AsynchronousJob) Mock.stub(AsynchronousJob.class);
        Mock.stubMethod(jobMock, 'getReference').returns('MOCKED');
        Mock.stubMethod(jobMock, 'getStatus').returns(Asynchronous.Status.CANCELLED);

        Asynchronous mocked = (Asynchronous) Mock.stub(Asynchronous.class);

        Mock.stubMethod(mocked, 'createJob')
                .withArguments(new List<Object>{
                        AsynchronousMockingTests.class,
                        null,
                        1,
                        1000,
                        new Map<String, String>()
                })
                .expected(1)
                .returns(jobMock);

        return mocked;
    }
}