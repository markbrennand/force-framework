/**
 * @description
 * <p/>
 * Helper methods for Asynchronous unit tests.
 * <p/>
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../LICENSE target="_blank">MIT License</a>.
 *
 * @author Mark Brennand
 */
@IsTest
public with sharing class AsynchronousTestHelper {

    @SuppressWarnings('PMD.ApexDoc')
    public with sharing class TestRunnable extends AsynchronousV1.Runnable {
        public TestRunnable() {
            super(TestRunnable.class);
        }

        @SuppressWarnings('PMD.EmptyStatementBlock')
        public override void run(final AsynchronousV1.Job asyncJob, final String apexJobId) {}
    }
}
