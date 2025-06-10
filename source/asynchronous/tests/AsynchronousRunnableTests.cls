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
            AsynchronousRunnableV1 runnable = new AsynchronousRunnableV1(Integer.class);
            Assert.areEqual(1, runnable.getMaximumActive());
            Assert.isTrue(runnable.onSuccess((AsynchronousV1.Job) MockerV1.of(AsynchronousJob.class).mock()));
            Assert.isTrue(runnable.onCancellation((AsynchronousV1.Job) MockerV1.of(AsynchronousJob.class).mock()));
            Assert.isTrue(runnable.onFailure((AsynchronousV1.Job) MockerV1.of(AsynchronousJob.class).mock(), new DMLException('Test')));
            Assert.areEqual(AsynchronousV1.Status.QUEUED, runnable.onError((AsynchronousV1.Job) MockerV1.of(AsynchronousJob.class).mock(), new DMLException('Test')));
        }
    }

    @IsTest
    private static void testForJob() {
        System.runAs(AsynchronousTestHelper.getUser()) {
            AsynchronousRunnableV1 runnable = new AsynchronousRunnableV1(Integer.class);
            AsynchronousV1.Job job = (AsynchronousV1.Job) MockerV1.of(AsynchronousJob.class).mock();
            runnable.forJob(job);
            Assert.areEqual(job, runnable.asyncJob);
        }
    }
}