/**
 * @description
 * Unit tests for AsynchronousRunnable class.
 *
 * @author Mark Brennand
 */
@IsTest
public with sharing class AsynchronousRunnableTests {
    @TestSetup
    private static void setup() {
        AsynchronousTestHelper.createUsers();
    }

    @IsTest
    private static void testGetters() {
        System.runAs(AsynchronousTestHelper.getUser()) {
            AsynchronousV1.Runnable runnable = new AsynchronousV1.Runnable(Integer.class);
            Assert.areEqual(1, runnable.getMaximumActive());
            Assert.isTrue(runnable.onSuccess((Asynchronous.Job) MockerV1.of(AsynchronousJob.class).mock()));
            Assert.isTrue(runnable.onCancellation((Asynchronous.Job) MockerV1.of(AsynchronousJob.class).mock()));
            Assert.isTrue(runnable.onFailure((Asynchronous.Job) MockerV1.of(AsynchronousJob.class).mock(), new DMLException('Test')));
            Assert.areEqual(Asynchronous.Status.QUEUED, runnable.onError((Asynchronous.Job) MockerV1.of(AsynchronousJob.class).mock(), new DMLException('Test')));
        }
    }

    @IsTest
    private static void testForJob() {
        System.runAs(AsynchronousTestHelper.getUser()) {
            AsynchronousV1.Runnable runnable = new AsynchronousV1.Runnable(Integer.class);
            Asynchronous.Job job = (Asynchronous.Job) MockerV1.of(AsynchronousJob.class).mock();
            runnable.forJob(job);
            Assert.areEqual(job, runnable.asyncJob);
        }
    }
}