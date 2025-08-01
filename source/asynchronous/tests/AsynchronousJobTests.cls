/**
 * @description
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../../LICENSE target="_blank">MIT License</a>.
 * <br><br>
 * Unit test for the AsynchronousJob class.
 * <br><br>
 * As Assert throws an Exception which cannot be caught, valid values must be supplied for the fields.
 *
 * @author Mark Brennand
 */
@IsTest
public with sharing class AsynchronousJobTests {
    private final static String TESTING = 'asynchronous';

    @TestSetup
    private static void createUsers() {
        TestHelper.createUsers(TESTING, new Set<String> { 'ForceFwDependencyInjectionPermissions', 'ForceFwAsynchronousPermissions' });
    }

    @IsTest
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    static void testAllStatuses() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            for (AsynchronousV1.Status status : AsynchronousV1.Status.values()) {
                AsynchronousJob__c asynchronous = new AsynchronousJob__c(
                        OwnerId = UserInfo.getUserId(),
                        Status__c = status.name(),
                        Runnable__c = AsynchronousJobTests.Runnable.class.getName(),
                        Reference__c = 'Test',
                        MaximumRetries__c = 1,
                        RetryInterval__c = 1000,
                        RetryNumber__c = 0,
                        ScheduledRunTime__c = CommonHelper.now()
                );
                AsynchronousJob.fromSObject(asynchronous);
            }
        }
    }

    @IsTest
    @SuppressWarnings('PMD.EmptyCatchBlock')
    private static void testMandatoryFields() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            AsynchronousJob__c asyncObject = new AsynchronousJob__c(
                    OwnerId = UserInfo.getUserId(),
                    Status__c = AsynchronousV1.Status.PENDING.name(),
                    Runnable__c = AsynchronousJobTests.Runnable.class.getName(),
                    MaximumRetries__c = 0,
                    RetryNumber__c = 0,
                    RetryInterval__c = 0,
                    ScheduledRunTime__c = CommonHelper.now()
            );

            try {
                AsynchronousJob__c copyObject = asyncObject.clone();
                copyObject.OwnerId = null;
                AsynchronousJob.fromSObject(copyObject);
                Assert.fail();

            } catch (AssertionV1.AssertionException ae) {
            }

            try {
                AsynchronousJob__c copyObject = asyncObject.clone();
                copyObject.Status__c = null;
                AsynchronousJob.fromSObject(copyObject);
                Assert.fail();
            } catch (AssertionV1.AssertionException ae) {
            }

            try {
                AsynchronousJob__c copyObject = asyncObject.clone();
                copyObject.Runnable__c = null;
                AsynchronousJob.fromSObject(copyObject);
                Assert.fail();
            } catch (AssertionV1.AssertionException ae) {
            }

            try {
                AsynchronousJob__c copyObject = asyncObject.clone();
                copyObject.MaximumRetries__c = null;
                AsynchronousJob.fromSObject(copyObject);
                Assert.fail();
            } catch (AssertionV1.AssertionException ae) {
            }

            try {
                AsynchronousJob__c copyObject = asyncObject.clone();
                copyObject.RetryNumber__c = null;
                AsynchronousJob.fromSObject(copyObject);
                Assert.fail();
            } catch (AssertionV1.AssertionException ae) {
            }

            try {
                AsynchronousJob__c copyObject = asyncObject.clone();
                copyObject.RetryInterval__c = null;
                AsynchronousJob.fromSObject(copyObject);
                Assert.fail();
            } catch (AssertionV1.AssertionException ae) {
            }

            try {
                AsynchronousJob__c copyObject = asyncObject.clone();
                copyObject.ScheduledRunTime__c = null;
                AsynchronousJob.fromSObject(copyObject);
                Assert.fail();
            } catch (AssertionV1.AssertionException ae) {
            }
        }
    }

    @IsTest
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    static void testOptionalFields() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            AsynchronousJob__c asynchronous = new AsynchronousJob__c(
                    OwnerId = UserInfo.getUserId(),
                    Status__c = AsynchronousV1.Status.PENDING.name(),
                    Runnable__c = 'AsynchronousJobTests.Runnable',
                    Reference__c = 'Test',
                    MaximumRetries__c = 1,
                    RetryInterval__c = 1000,
                    RetryNumber__c = 0,
                    ScheduledRunTime__c = CommonHelper.now()
            );
            AsynchronousJob.fromSObject(asynchronous);

            asynchronous.Reference__c = 'Test';
            AsynchronousJob.fromSObject(asynchronous);

            asynchronous.LastRunTime__c = CommonHelper.now();
            AsynchronousJob.fromSObject(asynchronous);
        }
    }

    @IsTest
    @SuppressWarnings('PMD.EmptyCatchBlock')
    private static void testFromSObject() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            try {
                AsynchronousJob.fromSObject(null);
                Assert.fail();
            } catch (AssertionV1.AssertionException ae) {
            }

            Datetime now = CommonHelper.now();
            AsynchronousJob__c asyncObject = new AsynchronousJob__c(
                    Id = MockerV1.fakeId(AsynchronousJob__c.SObjectType),
                    OwnerId = UserInfo.getUserId(),
                    Status__c = AsynchronousV1.Status.PENDING.name(),
                    Runnable__c = AsynchronousJobTests.Runnable.class.getName(),
                    Reference__c = 'Test',
                    MaximumRetries__c = 1,
                    RetryInterval__c = 1000,
                    RetryNumber__c = 0,
                    ScheduledRunTime__c = now.addMinutes(1),
                    LastRunTime__c = now
            );

            AsynchronousV1.Job job = AsynchronousJob.fromSObject(asyncObject);
            Assert.areEqual(UserInfo.getUserId(), job.getOwnerId());
            Assert.areEqual(AsynchronousV1.Status.PENDING, job.getStatus());
            Assert.isTrue(job.getRunnable() instanceof AsynchronousJobTests.Runnable);
            Assert.areEqual('Test', job.getReference());
            Assert.areEqual(1, job.getMaximumRetries());
            Assert.areEqual(1000, job.getRetryInterval());
            Assert.areEqual(0, job.getRetryNumber());
            Assert.areEqual(1, job.getRetriesRemaining());
            Assert.areEqual(now.addMinutes(1), job.getScheduledRunTime());
            Assert.areEqual(now, job.getLastRunTime());
        }
    }

    public with sharing class Runnable extends AsynchronousV1.Runnable {
        public Runnable() {
            super(Runnable.class);
        }

        @SuppressWarnings('PMD.EmptyStatementBlock')
        public override void run(AsynchronousV1.Job job, String apexJobId) {}
    }
}