/**
 * @description
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../../LICENSE target="_blank">MIT License</a>.
 * <br><br>
 * Unit tests for Asynchronous class.
 *
 * @author Mark Brennand
 */
@IsTest
public with sharing class AsynchronousTests {
    private final static String TESTING = 'asynchronous';

    @TestSetup
    private static void createUsers() {
        TestHelper.createUsers(TESTING, new Set<String> { 'ForceFwDependencyInjectionPermissions', 'ForceFwAsynchronousPermissions' });
    }

    @IsTest
    private static void testExtendedClassesAreInert() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            ExtendedClass extended = new ExtendedClass();

            try {
                extended.createJob(null, null, null, null, null);
                Assert.fail();
            } catch (AsynchronousV1.APIException ae) {
                Assert.areEqual('Access denied', ae.getMessage());
            }

            try {
                extended.queueJobs(null);
                Assert.fail();
            } catch (AsynchronousV1.APIException ae) {
                Assert.areEqual('Access denied', ae.getMessage());
            }

            LWCExtendedClass lwcExtended = new LWCExtendedClass();

            try {
                lwcExtended.getTotals();
                Assert.fail();
            } catch (AsynchronousV1.APIException ae) {
                Assert.areEqual('Access denied', ae.getMessage());
            }

            try {
                lwcExtended.runJobs(null);
                Assert.fail();
            } catch (AsynchronousV1.APIException ae) {
                Assert.areEqual('Access denied', ae.getMessage());
            }

            try {
                lwcExtended.deleteJobs(null);
                Assert.fail();
            } catch (AsynchronousV1.APIException ae) {
                Assert.areEqual('Access denied', ae.getMessage());
            }

            try {
                lwcExtended.getJobs(null, null, 0, 0);
                Assert.fail();
            } catch (AsynchronousV1.APIException ae) {
                Assert.areEqual('Access denied', ae.getMessage());
            }
        }
    }

    @IsTest
    private static void testCreateAndQueue() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            Map<String, String> state = new Map<String, String>{
                    'Key1' => 'Value1', 'Key2' => 'Value2'
            };

            try {
                AsynchronousV1.createJob(
                        UserInfo.class,
                        'TEST',
                        14,
                        1000,
                        state
                );
                Assert.fail();
            } catch(AsynchronousV1.APIException ae) {
                Assert.isTrue(TestHelper.exceptionContains('Class System.UserInfo does not extend AsynchronousV1.Runnable', ae));
            }

            AsynchronousV1.Job job = AsynchronousV1.createJob(
                    AsynchronousScheduler.RunNextAvailable.class,
                    'TEST',
                    14,
                    1000,
                    state
            );

            Assert.isTrue(job.getRunnable() instanceof AsynchronousScheduler);
            Assert.areEqual('TEST', job.getReference());
            Assert.areEqual(14, job.getMaximumRetries());
            Assert.areEqual(1000, job.getRetryInterval());
            Assert.areEqual(0, job.getRetryNumber());
            Assert.areEqual(14, job.getRetriesRemaining());
            Assert.areEqual(state, job.getState());
            Assert.areEqual(AsynchronousV1.Status.PENDING, job.getStatus());

            AsynchronousDAO.API = (AsynchronousDAO) MockerV1.of(AsynchronousDAO.class)
                    .whenArguments(
                            new List<AsynchronousJob__c>{
                                    new AsynchronousJob__c(Status__c = AsynchronousV1.Status.PENDING.name())
                            },
                            new List<Map<String, String>>{
                                    state
                            }
                    )
                        .forMethod('persistObjects')
                            .called(1)
                            .returns(new AddIdModifier())
                    .mock();

            for (AsynchronousV1.Job queuedJob : AsynchronousV1.queueJobs(new List<AsynchronousV1.Job> { job })) {
                Assert.isNotNull(((AsynchronousJob) queuedJob).asyncObjectId);
            }

            MockerV1.validate();
        }
    }

    @IsTest
    private static void testMocking() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            AsynchronousAPI.API = createMock();

            AsynchronousV1.Job job = AsynchronousAPI.API.createJob(
                    AsynchronousTests.class,
                    null,
                    1,
                    1000,
                    new Map<String, String>()
            );

            Assert.areEqual(AsynchronousV1.Status.CANCELLED, job.getStatus());
            Assert.areEqual('MOCKED', job.getReference());

            AsynchronousAPI.API.queueJobs(new List<AsynchronousV1.Job>{ job });
            MockerV1.validate();
        }
    }

    @IsTest
    private static void testBindingCheck() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            DependencyV1.bind(AsynchronousAPI.API.class, AsynchronousAPI.Factory.class);
            try {
                DependencyV1.bind(AsynchronousAPI.API.class, AsynchronousScheduler.RunNextAvailable.class);
                Assert.fail();
            } catch (DependencyV1.APIException ae) {
                Assert.isTrue(
                        TestHelper.exceptionContains('Class AsynchronousScheduler.RunNextAvailable does not implement AsynchronousAPI.API', ae),
                        'Unexpected exception: ' + ae
                );
            }

            DependencyV1.bind(AsynchronousLWC.API.class, AsynchronousLWC.Factory.class);
            try {
                DependencyV1.bind(AsynchronousLWC.API.class, AsynchronousScheduler.RunNextAvailable.class);
                Assert.fail();
            } catch (DependencyV1.APIException ae) {
                Assert.isTrue(
                        TestHelper.exceptionContains('Class AsynchronousScheduler.RunNextAvailable does not implement AsynchronousLWC.API', ae),
                        'Unexpected exception: ' + ae
                );
            }
        }
    }

    @IsTest
    private static void testCancellation() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            TriggerV1.disable(AsynchronousJobSubscriber.Factory.class);
            TriggerV1.disable(TriggerTests.Subscriber1.class);
            TriggerV1.disable(TriggerTests.Subscriber2.class);

            AsynchronousJob__c job1 = new AsynchronousJob__c(
                    OwnerId = UserInfo.getUserId(),
                    Runnable__c = TestAsynchronousRunnable.class.getName(),
                    Status__c = AsynchronousV1.Status.QUEUED.name(),
                    MaximumRetries__c = 0,
                    RetryInterval__c = 2000,
                    RetryNumber__c = 1,
                    Reference__c = 'TEST1',
                    ScheduledRunTime__c = CommonHelper.now().addDays(-1),
                    LastRunTime__c = CommonHelper.now()
            );

            AsynchronousJob__c job2 = new AsynchronousJob__c(
                    OwnerId = UserInfo.getUserId(),
                    Runnable__c = TestAsynchronousRunnable.class.getName(),
                    Status__c = AsynchronousV1.Status.RUNNING.name(),
                    MaximumRetries__c = 1,
                    RetryInterval__c = 2000,
                    RetryNumber__c = 1,
                    Reference__c = 'TEST2',
                    ScheduledRunTime__c = CommonHelper.now().addDays(-2),
                    LastRunTime__c = CommonHelper.now()
            );

            AsynchronousJob__c job3 = new AsynchronousJob__c(
                    OwnerId = UserInfo.getUserId(),
                    Runnable__c = TestAsynchronousRunnable.class.getName(),
                    Status__c = AsynchronousV1.Status.CANCELLED.name(),
                    MaximumRetries__c = 1,
                    RetryInterval__c = 2000,
                    RetryNumber__c = 1,
                    Reference__c = 'TEST2',
                    ScheduledRunTime__c = CommonHelper.now().addDays(-2),
                    LastRunTime__c = CommonHelper.now()
            );

            insert new List<AsynchronousJob__c> { job1, job2, job3 };

            TriggerV1.enable(AsynchronousJobSubscriber.Factory.class);
            job1.Status__c = AsynchronousV1.Status.CANCELLED.name();
            job2.Status__c = AsynchronousV1.Status.CANCELLED.name();
            job3.RetryNumber__c = 1;

            upsert new List<AsynchronousJob__c> { job1, job2, job3 };

            Assert.areEqual(2, [SELECT COUNT() FROM AsynchronousJob__c]);
            Assert.areEqual(1, [SELECT COUNT() FROM AsynchronousJob__c WHERE Id = :job1.Id ]);
            Assert.areEqual(1, [SELECT COUNT() FROM AsynchronousJob__c WHERE Id = :job3.Id ]);

            job1.Status__c = AsynchronousV1.Status.QUEUED.name();
            job1.MaximumRetries__c = 1;
            upsert job1;

            job1.Status__c = AsynchronousV1.Status.CANCELLED.name();
            job1.MaximumRetries__c = 2;
            upsert job1;

            Assert.areEqual(1, [SELECT COUNT() FROM AsynchronousJob__c WHERE Runnable__c != :AsynchronousScheduler.RunNextAvailable.class.getName()]);
            Assert.areEqual(1, [SELECT COUNT() FROM AsynchronousJob__c WHERE Id = :job3.Id ]);
        }
    }

    @IsTest
    @SuppressWarnings('PMD.NcssMethodCount')
    private static void testGetJobs() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            TriggerV1.disable(AsynchronousJobSubscriber.Factory.class);

            AsynchronousJob__c job1 = new AsynchronousJob__c(
                    OwnerId = UserInfo.getUserId(),
                    Runnable__c = AsynchronousTestHelper.TestRunnable.class.getName(),
                    Status__c = AsynchronousV1.Status.QUEUED.name(),
                    MaximumRetries__c = 1,
                    RetryInterval__c = 2000,
                    RetryNumber__c = 1,
                    Reference__c = 'TEST1',
                    ScheduledRunTime__c = CommonHelper.now().addDays(-1),
                    LastRunTime__c = CommonHelper.now()
            );

            AsynchronousJob__c job2 = new AsynchronousJob__c(
                    OwnerId = UserInfo.getUserId(),
                    Runnable__c = AsynchronousTestHelper.TestRunnable.class.getName(),
                    Status__c = AsynchronousV1.Status.RUNNING.name(),
                    MaximumRetries__c = 1,
                    RetryInterval__c = 2000,
                    RetryNumber__c = 1,
                    Reference__c = 'TEST2',
                    ScheduledRunTime__c = CommonHelper.now().addDays(-2),
                    LastRunTime__c = CommonHelper.now()
            );

            AsynchronousJob__c job3 = new AsynchronousJob__c(
                    OwnerId = UserInfo.getUserId(),
                    Runnable__c = AsynchronousTestHelper.TestRunnable.class.getName(),
                    Status__c = AsynchronousV1.Status.SUCCEEDED.name(),
                    MaximumRetries__c = 1,
                    RetryInterval__c = 2000,
                    RetryNumber__c = 1,
                    Reference__c = 'TEST3',
                    ScheduledRunTime__c = CommonHelper.now().addDays(1),
                    LastRunTime__c = CommonHelper.now()
            );

            AsynchronousJob__c job4 = new AsynchronousJob__c(
                    OwnerId = UserInfo.getUserId(),
                    Runnable__c = AsynchronousTestHelper.TestRunnable.class.getName(),
                    Status__c = AsynchronousV1.Status.FAILED.name(),
                    MaximumRetries__c = 1,
                    RetryInterval__c = 2000,
                    RetryNumber__c = 1,
                    Reference__c = 'TEST4',
                    ScheduledRunTime__c = CommonHelper.now().addDays(2),
                    LastRunTime__c = CommonHelper.now()
            );

            AsynchronousJob__c job5 = new AsynchronousJob__c(
                    OwnerId = UserInfo.getUserId(),
                    Runnable__c = AsynchronousTestHelper.TestRunnable.class.getName(),
                    Status__c = AsynchronousV1.Status.CANCELLED.name(),
                    MaximumRetries__c = 1,
                    RetryInterval__c = 2000,
                    RetryNumber__c = 1,
                    Reference__c = 'TEST5',
                    ScheduledRunTime__c = CommonHelper.now().addDays(0),
                    LastRunTime__c = CommonHelper.now()
            );

            insert new List<AsynchronousJob__c>{
                    job1, job2, job3, job4, job5
            };

            List<Map<String, Object>> jobs = AsynchronousLWC.API.getJobs(
                    null,
                    'ScheduledRunTime__c ASC',
                    0,
                    1
            );

            Assert.areEqual(1, jobs.size());
            Assert.areEqual(job2.Id, jobs[0].get('Id'));

            jobs = AsynchronousV1.getJobs(
                    null,
                    'ScheduledRunTime__c ASC',
                    0,
                    1
            );

            Assert.areEqual(1, jobs.size());
            Assert.areEqual(job2.Id, jobs[0].get('Id'));

            jobs = AsynchronousLWC.API.getJobs(
                    new Map<String, Object>{
                            'Status__c' => new List<String>{
                                    'QUEUED', 'SUCCEEDED'
                            }
                    },
                    'ScheduledRunTime__c DESC',
                    0,
                    3
            );

            Assert.areEqual(2, jobs.size());
            Assert.areEqual(job3.Id, jobs[0].get('Id'));
            Assert.areEqual(job1.Id, jobs[1].get('Id'));

            jobs = AsynchronousV1.getJobs(
                    new Map<String, Object>{
                            'Status__c' => new List<String>{
                                    'QUEUED', 'SUCCEEDED'
                            },
                            'Reference__c' => '%T3'
                    },
                    'ScheduledRunTime__c DESC',
                    0,
                    2
            );

            Assert.areEqual(1, jobs.size());
            Assert.areEqual(job3.Id, jobs[0].get('Id'));

            jobs = AsynchronousLWC.API.getJobs(
                    new Map<String, Object>{
                            'Status__c' => new List<String>{
                                    'QUEUED', 'RUNNING'
                            }
                    },
                    'ScheduledRunTime__c ASC',
                    0,
                    3
            );

            Assert.areEqual(2, jobs.size());
            Assert.areEqual(new Set<String>{
                    'Id', 'LastRunTime__c', 'MaximumRetries__c', 'Name', 'Owner', 'OwnerId', 'Reference__c', 'RetriesRemaining__c', 'RetryNumber__c', 'Runnable__c', 'ScheduledRunTime__c', 'Status__c'
            }, jobs[1].keySet());

            Assert.areEqual(new Set<String>{
                    'Id', 'LastRunTime__c', 'MaximumRetries__c', 'Name', 'Owner', 'OwnerId', 'Reference__c', 'RetriesRemaining__c', 'RetryNumber__c', 'RunTime__c', 'Runnable__c', 'ScheduledRunTime__c', 'Status__c'
            }, jobs[0].keySet());

            jobs = AsynchronousV1.getJobs(
                    new Map<String, Object>{
                            'Status__c' => new List<String>{
                                    'QUEUED', 'RUNNING'
                            }
                    },
                    'ScheduledRunTime__c ASC',
                    0,
                    3
            );

            Assert.areEqual(2, jobs.size());
            Assert.areEqual(new Set<String>{
                    'Id', 'LastRunTime__c', 'MaximumRetries__c', 'Name', 'Owner', 'OwnerId', 'Reference__c', 'RetryNumber__c', 'RetriesRemaining__c', 'Runnable__c', 'ScheduledRunTime__c', 'Status__c'
            }, jobs[1].keySet());

            Assert.areEqual(new Set<String>{
                    'Id', 'LastRunTime__c', 'MaximumRetries__c', 'Name', 'Owner', 'OwnerId', 'Reference__c', 'RetryNumber__c', 'RetriesRemaining__c', 'RunTime__c', 'Runnable__c', 'ScheduledRunTime__c', 'Status__c'
            }, jobs[0].keySet());

            TriggerV1.enable(AsynchronousJobSubscriber.Factory.class);
        }
    }

    @IsTest
    private static void testRunJobs() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            TriggerV1.disable(AsynchronousJobSubscriber.Factory.class);

            AsynchronousJob__c job1 = new AsynchronousJob__c(
                    OwnerId = UserInfo.getUserId(),
                    Runnable__c = AsynchronousTestHelper.TestRunnable.class.getName(),
                    Status__c = AsynchronousV1.Status.QUEUED.name(),
                    MaximumRetries__c = 1,
                    RetryInterval__c = 2000,
                    RetryNumber__c = 1,
                    Reference__c = 'TEST1',
                    ScheduledRunTime__c = CommonHelper.now().addDays(-1)
            );

            AsynchronousJob__c job2 = new AsynchronousJob__c(
                    OwnerId = UserInfo.getUserId(),
                    Runnable__c = AsynchronousTestHelper.TestRunnable.class.getName(),
                    Status__c = AsynchronousV1.Status.RUNNING.name(),
                    MaximumRetries__c = 1,
                    RetryInterval__c = 2000,
                    RetryNumber__c = 1,
                    Reference__c = 'TEST2',
                    ScheduledRunTime__c = CommonHelper.now().addDays(-2)
            );

            insert new List<AsynchronousJob__c> { job1, job2 };

            AsynchronousLWC.API.runJobs(new List<Id> { job1.Id, job2.Id });
            Assert.areEqual(
                    2,
                    [
                            SELECT COUNT()
                            FROM AsynchronousJob__c
                            WHERE Status__c = :AsynchronousV1.Status.PENDING.name()
                    ]
            );

            job1.Status__c = AsynchronousV1.Status.QUEUED.name();
            job2.Status__c = AsynchronousV1.Status.RUNNING.name();
            upsert new List<AsynchronousJob__c> { job1, job2 };

            AsynchronousV1.runJobs(new List<Id> { job1.Id, job2.Id });
            Assert.areEqual(
                    2,
                    [
                            SELECT COUNT()
                            FROM AsynchronousJob__c
                            WHERE Status__c = :AsynchronousV1.Status.PENDING.name()
                    ]
            );

            TriggerV1.enable(AsynchronousJobSubscriber.Factory.class);
        }
    }

    @IsTest
    private static void testDeleteJobs() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            TriggerV1.disable(AsynchronousJobSubscriber.Factory.class);

            AsynchronousJob__c job1 = new AsynchronousJob__c(
                    OwnerId = UserInfo.getUserId(),
                    Runnable__c = AsynchronousTestHelper.TestRunnable.class.getName(),
                    Status__c = AsynchronousV1.Status.QUEUED.name(),
                    MaximumRetries__c = 1,
                    RetryInterval__c = 2000,
                    RetryNumber__c = 1,
                    Reference__c = 'TEST1',
                    ScheduledRunTime__c = CommonHelper.now().addDays(-1)
            );

            AsynchronousJob__c job2 = new AsynchronousJob__c(
                    OwnerId = UserInfo.getUserId(),
                    Runnable__c = AsynchronousTestHelper.TestRunnable.class.getName(),
                    Status__c = AsynchronousV1.Status.RUNNING.name(),
                    MaximumRetries__c = 1,
                    RetryInterval__c = 2000,
                    RetryNumber__c = 1,
                    Reference__c = 'TEST2',
                    ScheduledRunTime__c = CommonHelper.now().addDays(-2)
            );

            AsynchronousJob__c job3 = new AsynchronousJob__c(
                    OwnerId = UserInfo.getUserId(),
                    Runnable__c = AsynchronousTestHelper.TestRunnable.class.getName(),
                    Status__c = AsynchronousV1.Status.SUCCEEDED.name(),
                    MaximumRetries__c = 1,
                    RetryInterval__c = 2000,
                    RetryNumber__c = 1,
                    Reference__c = 'TEST3',
                    ScheduledRunTime__c = CommonHelper.now().addDays(-2)
            );

            AsynchronousJob__c job4 = new AsynchronousJob__c(
                    OwnerId = UserInfo.getUserId(),
                    Runnable__c = AsynchronousTestHelper.TestRunnable.class.getName(),
                    Status__c = AsynchronousV1.Status.FAILED.name(),
                    MaximumRetries__c = 1,
                    RetryInterval__c = 2000,
                    RetryNumber__c = 1,
                    Reference__c = 'TEST4',
                    ScheduledRunTime__c = CommonHelper.now().addDays(-2)
            );

            AsynchronousJob__c job5 = new AsynchronousJob__c(
                    OwnerId = UserInfo.getUserId(),
                    Runnable__c = AsynchronousTestHelper.TestRunnable.class.getName(),
                    Status__c = AsynchronousV1.Status.CANCELLED.name(),
                    MaximumRetries__c = 1,
                    RetryInterval__c = 2000,
                    RetryNumber__c = 1,
                    Reference__c = 'TEST5',
                    ScheduledRunTime__c = CommonHelper.now().addDays(-2)
            );

            insert new List<AsynchronousJob__c> { job1, job2, job3, job4, job5 };

            AsynchronousLWC.API.deleteJobs(new List<Id> { job1.Id, job2.Id });
            Assert.areEqual(3, [SELECT COUNT() FROM AsynchronousJob__c]);
            Assert.areEqual(0, [SELECT COUNT() FROM AsynchronousJob__c WHERE Id = :job1.Id OR Id = :job2.Id ]);

            AsynchronousV1.deleteJobs(new List<Id> { job3.Id, job4.Id });
            Assert.areEqual(1, [SELECT COUNT() FROM AsynchronousJob__c]);
            Assert.areEqual(0, [SELECT COUNT() FROM AsynchronousJob__c WHERE Id = :job3.Id OR Id = :job4.Id ]);

            TriggerV1.enable(AsynchronousJobSubscriber.Factory.class);
        }
    }

    @IsTest
    @SuppressWarnings('PMD.NcssMethodCount')
    private static void testGetJobTotals() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            TriggerV1.disable(AsynchronousJobSubscriber.Factory.class);

            AsynchronousJob__c job1 = new AsynchronousJob__c(
                    OwnerId = UserInfo.getUserId(),
                    Runnable__c = AsynchronousTestHelper.TestRunnable.class.getName(),
                    Status__c = AsynchronousV1.Status.QUEUED.name(),
                    MaximumRetries__c = 1,
                    RetryInterval__c = 2000,
                    RetryNumber__c = 1,
                    Reference__c = 'TEST1',
                    ScheduledRunTime__c = CommonHelper.now().addDays(-1)
            );

            AsynchronousJob__c job2 = new AsynchronousJob__c(
                    OwnerId = UserInfo.getUserId(),
                    Runnable__c = AsynchronousTestHelper.TestRunnable.class.getName(),
                    Status__c = AsynchronousV1.Status.RUNNING.name(),
                    MaximumRetries__c = 1,
                    RetryInterval__c = 2000,
                    RetryNumber__c = 1,
                    Reference__c = 'TEST2',
                    ScheduledRunTime__c = CommonHelper.now().addDays(-2)
            );

            AsynchronousJob__c job3 = new AsynchronousJob__c(
                    OwnerId = UserInfo.getUserId(),
                    Runnable__c = AsynchronousTestHelper.TestRunnable.class.getName(),
                    Status__c = AsynchronousV1.Status.SUCCEEDED.name(),
                    MaximumRetries__c = 1,
                    RetryInterval__c = 2000,
                    RetryNumber__c = 1,
                    Reference__c = 'TEST3',
                    ScheduledRunTime__c = CommonHelper.now().addDays(-1)
            );

            AsynchronousJob__c job4 = new AsynchronousJob__c(
                    OwnerId = UserInfo.getUserId(),
                    Runnable__c = AsynchronousTestHelper.TestRunnable.class.getName(),
                    Status__c = AsynchronousV1.Status.FAILED.name(),
                    MaximumRetries__c = 1,
                    RetryInterval__c = 2000,
                    RetryNumber__c = 1,
                    Reference__c = 'TEST4',
                    ScheduledRunTime__c = CommonHelper.now().addDays(-4)
            );

            AsynchronousJob__c job5 = new AsynchronousJob__c(
                    OwnerId = UserInfo.getUserId(),
                    Runnable__c = AsynchronousScheduler.RunNextAvailable.class.getName(),
                    Status__c = AsynchronousV1.Status.CANCELLED.name(),
                    MaximumRetries__c = 1,
                    RetryInterval__c = 2000,
                    RetryNumber__c = 1,
                    Reference__c = 'TEST5',
                    ScheduledRunTime__c = CommonHelper.now().addDays(-1)
            );

            AsynchronousJob__c job6 = new AsynchronousJob__c(
                    OwnerId = UserInfo.getUserId(),
                    Runnable__c = AsynchronousScheduler.RunNextAvailable.class.getName(),
                    Status__c = AsynchronousV1.Status.QUEUED.name(),
                    MaximumRetries__c = 1,
                    RetryInterval__c = 2000,
                    RetryNumber__c = 1,
                    Reference__c = 'TEST6',
                    ScheduledRunTime__c = CommonHelper.now().addDays(-1)
            );

            insert new List<AsynchronousJob__c> { job1, job2, job3, job4, job5, job6 };

            Map<String, Integer> counts = AsynchronousLWC.API.getTotals();
            Assert.areEqual(6, counts.size());
            Assert.areEqual(0, counts.get('PENDING'));
            Assert.areEqual(2, counts.get('QUEUED'));
            Assert.areEqual(1, counts.get('RUNNING'));
            Assert.areEqual(1, counts.get('SUCCEEDED'));
            Assert.areEqual(1, counts.get('FAILED'));
            Assert.areEqual(1, counts.get('CANCELLED'));

            counts = AsynchronousV1.getTotals();
            Assert.areEqual(6, counts.size());
            Assert.areEqual(0, counts.get('PENDING'));
            Assert.areEqual(2, counts.get('QUEUED'));
            Assert.areEqual(1, counts.get('RUNNING'));
            Assert.areEqual(1, counts.get('SUCCEEDED'));
            Assert.areEqual(1, counts.get('FAILED'));
            Assert.areEqual(1, counts.get('CANCELLED'));

            job4.Status__c = AsynchronousV1.Status.CANCELLED.name();
            job5.Status__c = AsynchronousV1.Status.RUNNING.name();
            job6.Status__c = AsynchronousV1.Status.CANCELLED.name();
            upsert new List<AsynchronousJob__c> { job4, job5, job6 };

            counts = AsynchronousLWC.API.getTotals();
            Assert.areEqual(6, counts.size());
            Assert.areEqual(0, counts.get('PENDING'));
            Assert.areEqual(1, counts.get('QUEUED'));
            Assert.areEqual(2, counts.get('RUNNING'));
            Assert.areEqual(1, counts.get('SUCCEEDED'));
            Assert.areEqual(2, counts.get('CANCELLED'));
            Assert.areEqual(0, counts.get('FAILED'));

            counts = AsynchronousV1.getTotals();
            Assert.areEqual(6, counts.size());
            Assert.areEqual(0, counts.get('PENDING'));
            Assert.areEqual(1, counts.get('QUEUED'));
            Assert.areEqual(2, counts.get('RUNNING'));
            Assert.areEqual(1, counts.get('SUCCEEDED'));
            Assert.areEqual(2, counts.get('CANCELLED'));
            Assert.areEqual(0, counts.get('FAILED'));

            TriggerV1.enable(AsynchronousJobSubscriber.Factory.class);
        }
    }

    @IsTest
    private static void testPersistException() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            AsynchronousJob__c job = new AsynchronousJob__c(
                    OwnerId = UserInfo.getUserId(),
                    ApexJobId__c = 'APEXJOB-1',
                    Runnable__c = AsynchronousTestHelper.TestRunnable.class.getName(),
                    Status__c = AsynchronousV1.Status.FAILED.name(),
                    MaximumRetries__c = 1,
                    RetryInterval__c = 2000,
                    RetryNumber__c = 1,
                    Reference__c = 'TEST1',
                    ScheduledRunTime__c = CommonHelper.now().addDays(-1)
            );

            insert job;

            Exception exc = new DMLException('Test');

            AsynchronousJobException__c error = new AsynchronousJobException__c(
                    AsynchronousJob__c = job.Id,
                    RetryNumber__c = job.RetryNumber__c,
                    StatusOnError__c = job.Status__c,
                    ApexJobId__c = job.ApexJobId__c,
                    ExceptionType__c = exc.getTypeName(),
                    ExceptionMessage__c = exc.getMessage(),
                    ExceptionStackTrace__c = exc.getStackTraceString()
            );

            AsynchronousDAO.API.persistException(error);

            AsynchronousJobException__c persisted = [
                    SELECT Id, AsynchronousJob__c, RetryNumber__c, StatusOnError__c, ApexJobId__c, ExceptionType__c,
                            ExceptionMessage__c, ExceptionStackTrace__c
                    FROM AsynchronousJobException__c
                    WHERE AsynchronousJob__c = :job.Id
                    LIMIT 1
            ];

            Assert.areEqual(persisted, error);
        }
    }

    @IsTest
    private static void testOnlyAPICanBeUsed() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            try {
                AsynchronousHelper helper = (AsynchronousHelper) AsynchronousHelper.API;
                Assert.fail();

            } catch (TypeException te) {
                Assert.isTrue(
                        TestHelper.exceptionContains('Invalid conversion from runtime type AsynchronousHelper.Implementation to AsynchronousHelper', te),
                        'Unexpected exception: ' + te
                );
            }

            try {
                AsynchronousAPI async = (AsynchronousAPI) AsynchronousAPI.API;
                Assert.fail();

            } catch (TypeException te) {
                Assert.isTrue(
                        TestHelper.exceptionContains('Invalid conversion from runtime type AsynchronousAPI.Implementation to AsynchronousAPI', te),
                        'Unexpected exception: ' + te
                );
            }

            try {
                AsynchronousDAO dao = (AsynchronousDAO) AsynchronousDAO.API;
                Assert.fail();

            } catch (TypeException te) {
                Assert.isTrue(
                        TestHelper.exceptionContains('Invalid conversion from runtime type AsynchronousDAO.Implementation to AsynchronousDAO', te),
                        'Unexpected exception: ' + te
                );
            }
        }
    }

    @IsTest
    private static void testJobValidation() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            try {
                insert new AsynchronousJob__c(
                        OwnerId = UserInfo.getUserId(),
                        Runnable__c = UserInfo.class.getName(),
                        Status__c = AsynchronousV1.Status.RUNNING.name(),
                        MaximumRetries__c = 1,
                        RetryInterval__c = 2000,
                        RetryNumber__c = 1,
                        Reference__c = 'TEST2',
                        ScheduledRunTime__c = CommonHelper.now().addDays(-2)
                );
                Assert.fail();
            } catch (DMLException de) {
                Assert.isTrue(
                        TestHelper.exceptionContains('Class System.UserInfo does not implement AsynchronousV1.RunnableJob', de),
                        de.getMessage()
                );
            }
        }
    }

    private static AsynchronousAPI createMock() {
        AsynchronousV1.Job job = (AsynchronousV1.Job) MockerV1.of(AsynchronousJob.class)
                .whenNoArguments()
                    .forMethod('getReference')
                        .called(1)
                        .returns('MOCKED')
                    .forMethod('getStatus')
                        .called(1)
                        .returns(AsynchronousV1.Status.CANCELLED)
                .mock();

        return (AsynchronousAPI) MockerV1.of(AsynchronousAPI.class)
                .whenArguments(
                        AsynchronousTests.class,
                        null,
                        1,
                        1000,
                        new Map<String, String>()
                )
                    .forMethod('createJob')
                        .called(1)
                        .returns(job)
                .whenArgument(new List<AsynchronousV1.Job> { job })
                    .forMethod('queueJobs')
                        .called(1)
                .mock();
    }

    public with sharing class TestAsynchronousRunnable extends AsynchronousV1.Runnable {
        public TestAsynchronousRunnable() {
            super(TestAsynchronousRunnable.class);
        }

        public override Boolean onCancellation(AsynchronousV1.Job job) {
            return job.getMaximumRetries() == 0;
        }

        @SuppressWarnings('PMD.EmptyStatementBlock')
        public override void run(AsynchronousV1.Job asyncJob, String apexJobId) {}
    }

    private with sharing class AddIdModifier implements MockerV1.Modifier {
        public Object process(List<Object> arguments) {
            for (AsynchronousJob__c asyncObject : (List<AsynchronousJob__c>) arguments[0]) {
                asyncObject.Id = MockerV1.fakeId(AsynchronousJob__c.SObjectType);
            }
            return arguments[0];
        }
    }

    private with sharing class ExtendedClass extends AsynchronousAPI {}

    private with sharing class LWCExtendedClass extends AsynchronousLWC {}
}