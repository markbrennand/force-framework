/**
 * @description
 * Unit tests for Asynchronous class.
 *
 * @author Mark Brennand
 */
@IsTest
public with sharing class AsynchronousTests {
    @TestSetup
    private static void setup() {
        AsynchronousTestHelper.createUsers();
    }

    @IsTest
    private static void testExtendedClassIsInsert() {
        ExtendedClass extended = new ExtendedClass();

        try {
            extended.createJob(null, null, null, null, null);
            Assert.fail();
        } catch (Asynchronous.APIException ae) {
            Assert.areEqual('Access denied', ae.getMessage());
        }

        try {
            extended.queueJobs(null);
            Assert.fail();
        } catch (Asynchronous.APIException ae) {
            Assert.areEqual('Access denied', ae.getMessage());
        }
    }

    @IsTest
    private static void testCreateAndQueue() {
        System.runAs(AsynchronousTestHelper.getUser()) {
            Map<String, String> state = new Map<String, String>{
                    'Key1' => 'Value1', 'Key2' => 'Value2'
            };

            Asynchronous.Job job = AsynchronousV1.createJob(
                    AsynchronousScheduler.RunNextAvailable.class,
                    'TEST',
                    1,
                    1000,
                    state
            );

            Assert.isTrue(job.getRunnable() instanceof AsynchronousScheduler);
            Assert.areEqual('TEST', job.getReference());
            Assert.areEqual(1, job.getMaximumRetries());
            Assert.areEqual(1000, job.getRetryInterval());
            Assert.areEqual(0, job.getRetryNumber());
            Assert.areEqual(state, job.getState());
            Assert.areEqual(Asynchronous.Status.PENDING, job.getStatus());

            AsynchronousDAO.API = (AsynchronousDAO) MockerV1.of(AsynchronousDAO.class)
                    .whenArguments(
                            new List<AsynchronousJob__c>{
                                    new AsynchronousJob__c(Status__c = Asynchronous.Status.PENDING.name())
                            },
                            new List<Map<String, String>>{
                                    state
                            }
                    )
                        .forMethod('persistObjects')
                            .called(1)
                            .returns(new AddIdModifier())
                    .mock();

            for (Asynchronous.Job queuedJob : AsynchronousV1.queueJobs(new List<Asynchronous.Job> { job })) {
                Assert.isNotNull(((AsynchronousJob) queuedJob).asyncObjectId);
            }

            MockerV1.validate();
        }
    }

    @IsTest
    private static void testMocking() {
        System.runAs(AsynchronousTestHelper.getUser()) {
            AsynchronousAPI.API = createMock();

            Asynchronous.Job job = AsynchronousAPI.API.createJob(
                    AsynchronousTests.class,
                    null,
                    1,
                    1000,
                    new Map<String, String>()
            );

            Assert.areEqual(Asynchronous.Status.CANCELLED, job.getStatus());
            Assert.areEqual('MOCKED', job.getReference());

            AsynchronousAPI.API.queueJobs(new List<Asynchronous.Job>{ job });
            MockerV1.validate();
        }
    }

    @IsTest
    private static void testBindingCheck() {
        System.runAs(AsynchronousTestHelper.getUser()) {
            DependencyV1.bind(Asynchronous.API.class, AsynchronousAPI.Factory.class);
            try {
                DependencyV1.bind(Asynchronous.API.class, AsynchronousScheduler.RunNextAvailable.class);
                Assert.fail();
            } catch (Dependency.APIException ae) {
                Assert.isTrue(
                        TestHelper.exceptionContains('Class AsynchronousScheduler.RunNextAvailable does not implement Asynchronous.API', ae),
                        'Unexpected exception: ' + ae
                );
            }

            DependencyV1.bind(Asynchronous.LWC.class, AsynchronousLWC.Factory.class);
            try {
                DependencyV1.bind(Asynchronous.LWC.class, AsynchronousScheduler.RunNextAvailable.class);
                Assert.fail();
            } catch (Dependency.APIException ae) {
                Assert.isTrue(
                        TestHelper.exceptionContains('Class AsynchronousScheduler.RunNextAvailable does not implement Asynchronous.LWC', ae),
                        'Unexpected exception: ' + ae
                );
            }
        }
    }

    @IsTest
    private static void testGetJobs() {
        AsynchronousAPI.skipTriggers = true;

        System.runAs(AsynchronousTestHelper.getUser()) {
            AsynchronousJob__c job1 = new AsynchronousJob__c(
                    OwnerId = UserInfo.getUserId(),
                    Runnable__c = AsynchronousTestHelper.TestRunnable.class.getName(),
                    Status__c = Asynchronous.Status.QUEUED.name(),
                    MaximumRetries__c = 1,
                    RetryInterval__c = 2000,
                    RetryNumber__c = 1,
                    Reference__c = 'TEST1',
                    ScheduledRunTime__c = Datetime.now().addDays(-1),
                    LastRunTime__c = Datetime.now()
            );

            AsynchronousJob__c job2 = new AsynchronousJob__c(
                    OwnerId = UserInfo.getUserId(),
                    Runnable__c = AsynchronousTestHelper.TestRunnable.class.getName(),
                    Status__c = Asynchronous.Status.RUNNING.name(),
                    MaximumRetries__c = 1,
                    RetryInterval__c = 2000,
                    RetryNumber__c = 1,
                    Reference__c = 'TEST2',
                    ScheduledRunTime__c = Datetime.now().addDays(-2),
                    LastRunTime__c = Datetime.now()
            );

            AsynchronousJob__c job3 = new AsynchronousJob__c(
                    OwnerId = UserInfo.getUserId(),
                    Runnable__c = AsynchronousTestHelper.TestRunnable.class.getName(),
                    Status__c = Asynchronous.Status.SUCCEEDED.name(),
                    MaximumRetries__c = 1,
                    RetryInterval__c = 2000,
                    RetryNumber__c = 1,
                    Reference__c = 'TEST3',
                    ScheduledRunTime__c = Datetime.now().addDays(1),
                    LastRunTime__c = Datetime.now()
            );

            AsynchronousJob__c job4 = new AsynchronousJob__c(
                    OwnerId = UserInfo.getUserId(),
                    Runnable__c = AsynchronousTestHelper.TestRunnable.class.getName(),
                    Status__c = Asynchronous.Status.FAILED.name(),
                    MaximumRetries__c = 1,
                    RetryInterval__c = 2000,
                    RetryNumber__c = 1,
                    Reference__c = 'TEST4',
                    ScheduledRunTime__c = Datetime.now().addDays(2),
                    LastRunTime__c = Datetime.now()
            );

            AsynchronousJob__c job5 = new AsynchronousJob__c(
                    OwnerId = UserInfo.getUserId(),
                    Runnable__c = AsynchronousTestHelper.TestRunnable.class.getName(),
                    Status__c = Asynchronous.Status.CANCELLED.name(),
                    MaximumRetries__c = 1,
                    RetryInterval__c = 2000,
                    RetryNumber__c = 1,
                    Reference__c = 'TEST5',
                    ScheduledRunTime__c = Datetime.now().addDays(0),
                    LastRunTime__c = Datetime.now()
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
                    'Id', 'LastRunTime__c', 'MaximumRetries__c', 'Owner', 'OwnerId', 'Reference__c', 'RetryNumber__c', 'Retry__c', 'Runnable__c', 'ScheduledRunTime__c', 'Status__c'
            }, jobs[1].keySet());

            Assert.areEqual(new Set<String>{
                    'Id', 'LastRunTime__c', 'MaximumRetries__c', 'Owner', 'OwnerId', 'Reference__c', 'RetryNumber__c', 'Retry__c', 'RunTime__c', 'Runnable__c', 'ScheduledRunTime__c', 'Status__c'
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
                    'Id', 'LastRunTime__c', 'MaximumRetries__c', 'Owner', 'OwnerId', 'Reference__c', 'RetryNumber__c', 'Retry__c', 'Runnable__c', 'ScheduledRunTime__c', 'Status__c'
            }, jobs[1].keySet());

            Assert.areEqual(new Set<String>{
                    'Id', 'LastRunTime__c', 'MaximumRetries__c', 'Owner', 'OwnerId', 'Reference__c', 'RetryNumber__c', 'Retry__c', 'RunTime__c', 'Runnable__c', 'ScheduledRunTime__c', 'Status__c'
            }, jobs[0].keySet());
        }
    }

    @IsTest
    private static void testRunJobs() {
        AsynchronousAPI.skipTriggers = true;

        System.runAs(AsynchronousTestHelper.getUser()) {
            AsynchronousJob__c job1 = new AsynchronousJob__c(
                    OwnerId = UserInfo.getUserId(),
                    Runnable__c = AsynchronousTestHelper.TestRunnable.class.getName(),
                    Status__c = Asynchronous.Status.QUEUED.name(),
                    MaximumRetries__c = 1,
                    RetryInterval__c = 2000,
                    RetryNumber__c = 1,
                    Reference__c = 'TEST1',
                    ScheduledRunTime__c = Datetime.now().addDays(-1)
            );

            AsynchronousJob__c job2 = new AsynchronousJob__c(
                    OwnerId = UserInfo.getUserId(),
                    Runnable__c = AsynchronousTestHelper.TestRunnable.class.getName(),
                    Status__c = Asynchronous.Status.RUNNING.name(),
                    MaximumRetries__c = 1,
                    RetryInterval__c = 2000,
                    RetryNumber__c = 1,
                    Reference__c = 'TEST2',
                    ScheduledRunTime__c = Datetime.now().addDays(-2)
            );

            insert new List<AsynchronousJob__c> { job1, job2 };

            AsynchronousLWC.API.runJobs(new List<Id> { job1.Id, job2.Id });
            Assert.areEqual(
                    2,
                    [
                            SELECT COUNT()
                            FROM AsynchronousJob__c
                            WHERE Status__c = :Asynchronous.Status.PENDING.name()
                    ]
            );

            job1.Status__c = Asynchronous.Status.QUEUED.name();
            job2.Status__c = Asynchronous.Status.RUNNING.name();
            upsert new List<AsynchronousJob__c> { job1, job2 };

            AsynchronousV1.runJobs(new List<Id> { job1.Id, job2.Id });
            Assert.areEqual(
                    2,
                    [
                            SELECT COUNT()
                            FROM AsynchronousJob__c
                            WHERE Status__c = :Asynchronous.Status.PENDING.name()
                    ]
            );
        }
    }

    @IsTest
    private static void testDeleteJobs() {
        AsynchronousAPI.skipTriggers = true;

        System.runAs(AsynchronousTestHelper.getUser()) {
            AsynchronousJob__c job1 = new AsynchronousJob__c(
                    OwnerId = UserInfo.getUserId(),
                    Runnable__c = AsynchronousTestHelper.TestRunnable.class.getName(),
                    Status__c = Asynchronous.Status.QUEUED.name(),
                    MaximumRetries__c = 1,
                    RetryInterval__c = 2000,
                    RetryNumber__c = 1,
                    Reference__c = 'TEST1',
                    ScheduledRunTime__c = Datetime.now().addDays(-1)
            );

            AsynchronousJob__c job2 = new AsynchronousJob__c(
                    OwnerId = UserInfo.getUserId(),
                    Runnable__c = AsynchronousTestHelper.TestRunnable.class.getName(),
                    Status__c = Asynchronous.Status.RUNNING.name(),
                    MaximumRetries__c = 1,
                    RetryInterval__c = 2000,
                    RetryNumber__c = 1,
                    Reference__c = 'TEST2',
                    ScheduledRunTime__c = Datetime.now().addDays(-2)
            );

            AsynchronousJob__c job3 = new AsynchronousJob__c(
                    OwnerId = UserInfo.getUserId(),
                    Runnable__c = AsynchronousTestHelper.TestRunnable.class.getName(),
                    Status__c = Asynchronous.Status.SUCCEEDED.name(),
                    MaximumRetries__c = 1,
                    RetryInterval__c = 2000,
                    RetryNumber__c = 1,
                    Reference__c = 'TEST3',
                    ScheduledRunTime__c = Datetime.now().addDays(-2)
            );

            AsynchronousJob__c job4 = new AsynchronousJob__c(
                    OwnerId = UserInfo.getUserId(),
                    Runnable__c = AsynchronousTestHelper.TestRunnable.class.getName(),
                    Status__c = Asynchronous.Status.FAILED.name(),
                    MaximumRetries__c = 1,
                    RetryInterval__c = 2000,
                    RetryNumber__c = 1,
                    Reference__c = 'TEST4',
                    ScheduledRunTime__c = Datetime.now().addDays(-2)
            );

            AsynchronousJob__c job5 = new AsynchronousJob__c(
                    OwnerId = UserInfo.getUserId(),
                    Runnable__c = AsynchronousTestHelper.TestRunnable.class.getName(),
                    Status__c = Asynchronous.Status.CANCELLED.name(),
                    MaximumRetries__c = 1,
                    RetryInterval__c = 2000,
                    RetryNumber__c = 1,
                    Reference__c = 'TEST5',
                    ScheduledRunTime__c = Datetime.now().addDays(-2)
            );

            insert new List<AsynchronousJob__c> { job1, job2, job3, job4, job5 };

            AsynchronousLWC.API.deleteJobs(new List<Id> { job1.Id, job2.Id });
            Assert.areEqual(3, [SELECT COUNT() FROM AsynchronousJob__c]);
            Assert.areEqual(0, [SELECT COUNT() FROM AsynchronousJob__c WHERE Id = :job1.Id OR Id = :job2.Id ]);

            AsynchronousV1.deleteJobs(new List<Id> { job3.Id, job4.Id });
            Assert.areEqual(1, [SELECT COUNT() FROM AsynchronousJob__c]);
            Assert.areEqual(0, [SELECT COUNT() FROM AsynchronousJob__c WHERE Id = :job3.Id OR Id = :job4.Id ]);
        }
    }

    @IsTest
    private static void testGetJobTotals() {
        AsynchronousAPI.skipTriggers = true;

        System.runAs(AsynchronousTestHelper.getUser()) {
            AsynchronousJob__c job1 = new AsynchronousJob__c(
                    OwnerId = UserInfo.getUserId(),
                    Runnable__c = AsynchronousTestHelper.TestRunnable.class.getName(),
                    Status__c = Asynchronous.Status.QUEUED.name(),
                    MaximumRetries__c = 1,
                    RetryInterval__c = 2000,
                    RetryNumber__c = 1,
                    Reference__c = 'TEST1',
                    ScheduledRunTime__c = Datetime.now().addDays(-1)
            );

            AsynchronousJob__c job2 = new AsynchronousJob__c(
                    OwnerId = UserInfo.getUserId(),
                    Runnable__c = AsynchronousTestHelper.TestRunnable.class.getName(),
                    Status__c = Asynchronous.Status.RUNNING.name(),
                    MaximumRetries__c = 1,
                    RetryInterval__c = 2000,
                    RetryNumber__c = 1,
                    Reference__c = 'TEST2',
                    ScheduledRunTime__c = Datetime.now().addDays(-2)
            );

            AsynchronousJob__c job3 = new AsynchronousJob__c(
                    OwnerId = UserInfo.getUserId(),
                    Runnable__c = AsynchronousTestHelper.TestRunnable.class.getName(),
                    Status__c = Asynchronous.Status.SUCCEEDED.name(),
                    MaximumRetries__c = 1,
                    RetryInterval__c = 2000,
                    RetryNumber__c = 1,
                    Reference__c = 'TEST3',
                    ScheduledRunTime__c = Datetime.now().addDays(-1)
            );

            AsynchronousJob__c job4 = new AsynchronousJob__c(
                    OwnerId = UserInfo.getUserId(),
                    Runnable__c = AsynchronousTestHelper.TestRunnable.class.getName(),
                    Status__c = Asynchronous.Status.FAILED.name(),
                    MaximumRetries__c = 1,
                    RetryInterval__c = 2000,
                    RetryNumber__c = 1,
                    Reference__c = 'TEST4',
                    ScheduledRunTime__c = Datetime.now().addDays(-4)
            );

            AsynchronousJob__c job5 = new AsynchronousJob__c(
                    OwnerId = UserInfo.getUserId(),
                    Runnable__c = AsynchronousScheduler.RunNextAvailable.class.getName(),
                    Status__c = Asynchronous.Status.CANCELLED.name(),
                    MaximumRetries__c = 1,
                    RetryInterval__c = 2000,
                    RetryNumber__c = 1,
                    Reference__c = 'TEST5',
                    ScheduledRunTime__c = Datetime.now().addDays(-1)
            );

            AsynchronousJob__c job6 = new AsynchronousJob__c(
                    OwnerId = UserInfo.getUserId(),
                    Runnable__c = AsynchronousScheduler.RunNextAvailable.class.getName(),
                    Status__c = Asynchronous.Status.QUEUED.name(),
                    MaximumRetries__c = 1,
                    RetryInterval__c = 2000,
                    RetryNumber__c = 1,
                    Reference__c = 'TEST6',
                    ScheduledRunTime__c = Datetime.now().addDays(-1)
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

            job4.Status__c = Asynchronous.Status.CANCELLED.name();
            job5.Status__c = Asynchronous.Status.RUNNING.name();
            job6.Status__c = Asynchronous.Status.CANCELLED.name();
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
        }
    }

    @IsTest
    private static void testPersistException() {
        System.runAs(AsynchronousTestHelper.getUser()) {
            AsynchronousJob__c job = new AsynchronousJob__c(
                    OwnerId = UserInfo.getUserId(),
                    ApexJobId__c = 'APEXJOB-1',
                    Runnable__c = AsynchronousTestHelper.TestRunnable.class.getName(),
                    Status__c = Asynchronous.Status.FAILED.name(),
                    MaximumRetries__c = 1,
                    RetryInterval__c = 2000,
                    RetryNumber__c = 1,
                    Reference__c = 'TEST1',
                    ScheduledRunTime__c = Datetime.now().addDays(-1)
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
        System.runAs(AsynchronousTestHelper.getUser()) {
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

    private static AsynchronousAPI createMock() {
        Asynchronous.Job job = (Asynchronous.Job) MockerV1.of(AsynchronousJob.class)
                .whenNoArguments()
                    .forMethod('getReference')
                        .called(1)
                        .returns('MOCKED')
                    .forMethod('getStatus')
                        .called(1)
                        .returns(Asynchronous.Status.CANCELLED)
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
                .whenArgument(new List<Asynchronous.Job> { job })
                    .forMethod('queueJobs')
                        .called(1)
                .mock();
    }

    public with sharing class TestAsynchronousRunnable extends AsynchronousV1.Runnable {
        public TestAsynchronousRunnable() {
            super(TestAsynchronousRunnable.class);
        }

        public override Boolean onCancellation(Asynchronous.Job job) {
            return job.getMaximumRetries() == 0;
        }
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
}