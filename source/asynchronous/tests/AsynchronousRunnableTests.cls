/**
 * @description
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../../LICENSE target="_blank">MIT License</a>.
 * <br><br>
 * Unit tests for AsynchronousRunnable class.
 *
 * @author Mark Brennand
 */
@IsTest
public with sharing class AsynchronousRunnableTests {
    private final static String TESTING = 'asynchronous';

    @TestSetup
    private static void createUsers() {
        TestHelper.createUsers(TESTING, new Set<String> { 'ForceFwDependencyInjectionPermissions', 'ForceFwAsynchronousPermissions' });
    }

    @IsTest
    private static void testGetters() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            AsynchronousV1.Runnable runnable = new AsynchronousTestHelper.TestRunnable();
            Assert.areEqual(1, runnable.getMaximumActive());
            Assert.isTrue(runnable.onSuccess((AsynchronousV1.Job) MockerV1.of(AsynchronousJob.class).mock()));
            Assert.isTrue(runnable.onCancellation((AsynchronousV1.Job) MockerV1.of(AsynchronousJob.class).mock()));
            Assert.isTrue(runnable.onFailure((AsynchronousV1.Job) MockerV1.of(AsynchronousJob.class).mock(), new DMLException('Test')));
            Assert.areEqual(AsynchronousV1.Status.QUEUED, runnable.onError((AsynchronousV1.Job) MockerV1.of(AsynchronousJob.class).mock(), new DMLException('Test')));
        }
    }

    @IsTest
    private static void testForJob() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            AsynchronousV1.Runnable runnable = new AsynchronousTestHelper.TestRunnable();
            AsynchronousV1.Job job = (AsynchronousV1.Job) MockerV1.of(AsynchronousJob.class).mock();
            runnable.forJob(job);
            Assert.areEqual(job, runnable.asyncJob);
        }
    }
}