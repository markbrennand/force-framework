/**
 * @description
 * <p>
 * Example of
 * <p>
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../LICENSE target="_blank">MIT License</a>.
 * 
 * @author Mark Brennand
 */
@IsTest
global with sharing class ForceFwTestHelperTests {

    @IsTest
    private static void testDisableAsynchronousScheduler() {
        ForceFwTestHelper.disableAsynchronousScheduler();

        forcefw.AsynchronousV1.queueJobs(
                new List<forcefw.AsynchronousV1.Job>{
                        forcefw.AsynchronousV1.createJob(
                                TestRunnable.class,
                                'Test',
                                10,
                                60000,
                                new Map<String, String>()
                        )
                }
        );
    }

    global with sharing class TestRunnable extends forcefw.AsynchronousV1.Runnable {
        global TestRunnable() {
            super(TestRunnable.class);
        }

        public void run(forcefw.AsynchronousV1.Job asyncJob, String apexJobId) {
            throw new DMLException('Forced failure');
        }
    }
}