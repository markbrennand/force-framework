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
            AsynchronousRunnable runnable = new AsynchronousRunnable(Integer.class);
            Assert.areEqual(1, runnable.getMaximumActive());
            Assert.isTrue(runnable.onSuccess((Asynchronous.Job) Mocker.of(AsynchronousJob.class).mock()));
            Assert.isTrue(runnable.onCancellation((Asynchronous.Job) Mocker.of(AsynchronousJob.class).mock()));
            Assert.isTrue(runnable.onFailure((Asynchronous.Job) Mocker.of(AsynchronousJob.class).mock(), new DMLException('Test')));
            Assert.areEqual(Asynchronous.Status.QUEUED, runnable.onError((Asynchronous.Job) Mocker.of(AsynchronousJob.class).mock(), new DMLException('Test')));
        }
    }

    @IsTest
    private static void testForJob() {
        System.runAs(AsynchronousTestHelper.getUser()) {
            AsynchronousRunnable runnable = new AsynchronousRunnable(Integer.class);
            Asynchronous.Job job = (Asynchronous.Job) Mocker.of(AsynchronousJob.class).mock();
            runnable.forJob(job);
            Assert.areEqual(job, runnable.asyncJob);
        }
    }
}