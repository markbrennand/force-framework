/**
 * @description
 * <p>
 * Unit tests for AsynchronousScheduler class.
 * <p>
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../LICENSE target="_blank">MIT License</a>.
 *
 * @author Mark Brennand
 */
@IsTest
@SuppressWarnings('PMD')
public with sharing class AsynchronousSchedulerTests {
    private final static String TESTING = 'asynchronous';

    @TestSetup
    private static void createUsers() {
        TestHelper.createUsers(TESTING, new Set<String> { 'ForceFwDependencyInjectionPermissions', 'ForceFwAsynchronousPermissions' });
    }

    @IsTest
    private static void testNullJobArgument() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            try {
                new AsynchronousScheduler().run(null, 'ApexJobId');
                Assert.fail();
            } catch (AssertionV1.AssertionException ae) {
            }
        }
    }

    @IsTest
    private static void itShouldSetStaleJobCorrectlyFromJob() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            AsynchronousScheduler.StaleJob staleJob = new AsynchronousScheduler.StaleJob(new AsynchronousJob__c(
                    Runnable__c = AsynchronousScheduler.RunNextAvailable.class.getName(),
                    Status__c = AsynchronousV1.Status.RUNNING.name()
            ));

            Assert.areEqual(AsynchronousV1.Status.FAILED.name(), staleJob.job.Status__c);
            Assert.isTrue(staleJob.getError().get() instanceof AsynchronousV1.APIException);

            staleJob = new AsynchronousScheduler.StaleJob(new AsynchronousJob__c(
                    Runnable__c = AsynchronousScheduler.RunNextAvailable.class.getName(),
                    Status__c = AsynchronousV1.Status.FINALIZING.name()
            ));

            Assert.areEqual(AsynchronousV1.Status.FAILED.name(), staleJob.job.Status__c);
            Assert.isTrue(staleJob.getError().get() instanceof AsynchronousV1.APIException);

            staleJob = new AsynchronousScheduler.StaleJob(new AsynchronousJob__c(
                    Runnable__c = AsynchronousScheduler.RunSweeper.class.getName(),
                    Status__c = AsynchronousV1.Status.RUNNING.name()
            ));

            Assert.areEqual(AsynchronousV1.Status.PENDING.name(), staleJob.job.Status__c);
            Assert.isFalse(staleJob.getError().isPresent());

            staleJob = new AsynchronousScheduler.StaleJob(new AsynchronousJob__c(
                    Runnable__c = AsynchronousScheduler.RunSweeper.class.getName(),
                    Status__c = AsynchronousV1.Status.FINALIZING.name()
            ));

            Assert.areEqual(AsynchronousV1.Status.SUCCEEDED.name(), staleJob.job.Status__c);
            Assert.isFalse(staleJob.getError().isPresent());
        }
    }

    @IsTest
    private static void itShouldReturnEmptyOptionalWhenNoJobsToSweep() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            AsynchronousDAO.impl = (AsynchronousDAO.API) MockerV1.of(AsynchronousDAOMockable.class)
                    .whenArguments(1, MockerV1.any(Integer.class))
                        .forMethod('getSweepableObjects')
                            .called(1)
                            .returns(new List<AsynchronousJob__c>())
                    .mock();

            AsynchronousAPI.impl = (AsynchronousAPI.API) MockerV1.of(AsynchronousAPIMockable.class)
                    .whenArguments(
                            AsynchronousScheduler.RunSweeper.class,
                            'Sweeper',
                            0,
                            0,
                            new Map<String, String>()
                    )
                        .forMethod('createJob')
                            .called(0)
                            .returns(
                                    AsynchronousJob.fromSObject(
                                            new AsynchronousJob__c(
                                                    OwnerId = UserInfo.getUserId(),
                                                    Runnable__c = AsynchronousScheduler.RunSweeper.class.getName(),
                                                    RetryNumber__c = 0,
                                                    MaximumRetries__c = 0,
                                                    RetryInterval__c = 0,
                                                    Status__c = AsynchronousV1.Status.PENDING.name(),
                                                    ScheduledRunTime__c = CommonHelper.now()
                                            )
                                    )
                            )
                    .mock();

            Assert.isFalse(AsynchronousScheduler.getSweeper().isPresent());
            MockerV1.validate();
        }
    }

    @IsTest
    private static void itShouldReturnOptionalWithJobsWhenJobsToSweep() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            AsynchronousDAO.impl = (AsynchronousDAO.API) MockerV1.of(AsynchronousDAOMockable.class)
                    .whenArguments(1, MockerV1.any(Integer.class))
                       .forMethod('getSweepableObjects')
                            .called(1)
                            .returns(new List<AsynchronousJob__c>{
                                    new AsynchronousJob__c()
                            })
                    .mock();

            AsynchronousAPI.impl = (AsynchronousAPI.API) MockerV1.of(AsynchronousAPIMockable.class)
                    .whenArguments(
                            AsynchronousScheduler.RunSweeper.class,
                            'Sweeper',
                            0,
                            0,
                            new Map<String, String>()
                    )
                        .forMethod('createJob')
                            .called(1)
                            .returns(
                                    AsynchronousJob.fromSObject(
                                            new AsynchronousJob__c(
                                                    OwnerId = UserInfo.getUserId(),
                                                    Runnable__c = AsynchronousScheduler.RunSweeper.class.getName(),
                                                    RetryNumber__c = 0,
                                                    MaximumRetries__c = 0,
                                                    RetryInterval__c = 0,
                                                    Status__c = AsynchronousV1.Status.PENDING.name(),
                                                    ScheduledRunTime__c = CommonHelper.now()
                                            )
                                    )
                            )
                    .mock();

            Assert.isTrue(AsynchronousScheduler.getSweeper().isPresent());
            MockerV1.validate();
        }
    }

    @IsTest
    private static void testDelayedWhenNoJobsToRun() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            AsynchronousV1.Job asyncJob = (AsynchronousV1.Job) MockerV1.of(AsynchronousJob.class)
                    .whenNoArguments()
                        .forMethod('getState')
                            .called(1)
                            .returns(new Map<String, String>{
                                    AsynchronousScheduler.JOBS_TO_START => JSON.serialize(new Set<String>()),
                                    AsynchronousScheduler.SCHEDULER_DELAY => '5000'
                            })
                    .mock();

            AsynchronousScheduler scheduler = new AsynchronousScheduler();

            Long started = System.currentTimeMillis();
            scheduler.run(asyncJob, 'ApexJobId');

            Assert.isTrue((System.currentTimeMillis() - started) >= 5000);
            MockerV1.validate();
        }
    }

    @IsTest
    private static void testJobToRun() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            Id asyncJobId1 = MockerV1.fakeId(AsynchronousJob__c.SObjectType);
            Id asyncJobId2 = MockerV1.fakeId(AsynchronousJob__c.SObjectType);

            AsynchronousJob__c asyncObject = new AsynchronousJob__c(Id = asyncJobId1);

            Map<String, String> state = new Map<String, String>{
                    AsynchronousScheduler.JOBS_TO_START => JSON.serialize(new Set<String>{
                            asyncJobId1, asyncJobId2
                    }),
                    AsynchronousScheduler.SCHEDULER_DELAY => '0'
            };

            AsynchronousDAO.impl = (AsynchronousDAO) MockerV1.of(AsynchronousDAO.class)
                    .whenArgument(asyncJobId1)
                        .forMethod('getObject')
                            .called(1)
                            .returns(asyncObject)
                    .mock();

            AsynchronousHelper.impl = (AsynchronousHelper.API) MockerV1.of(AsynchronousHelper.class)
                    .whenArgument(asyncObject)
                        .forMethod('queueJob')
                            .called(1)
                    .mock();

            AsynchronousV1.Job asyncJob = (AsynchronousV1.Job) MockerV1.of(AsynchronousJob.class)
                    .whenNoArguments()
                        .forMethod('getState')
                            .called(1)
                            .returns(state)

                    // Confirms that the job to be run has been removed from the state.
                    .whenArgument(new Map<String, String>{
                            AsynchronousScheduler.JOBS_TO_START => JSON.serialize(new Set<String>{
                                    asyncJobId2
                            })
                    })
                        .forMethod('setState')
                            .called(1)
                    .mock();

            AsynchronousScheduler scheduler = new AsynchronousScheduler();
            scheduler.run(asyncJob, 'ApexJobId');
            Assert.areEqual('ApexJobId', asyncObject.ApexJobId__c);
            MockerV1.validate();
        }
    }

    @IsTest
    private static void testSchedulerQueuedWhenJobsToStart() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            AsynchronousJob__c job = new AsynchronousJob__c(
                    Id = MockerV1.fakeId(AsynchronousJob__c.SObjectType),
                    Runnable__c = SingleConcurrencyTestRunnable.class.getName()
            );

            Set<Id> jobsThatShouldBeStarted = new Set<Id>{ job.Id };

            mockForRun(new List<AsynchronousJob__c> { job }, 1, jobsThatShouldBeStarted);
            AsynchronousScheduler.queue(new Set<String>(), 1);
            MockerV1.validate();
        }
    }

    @IsTest
    private static void testSingleConcurrency() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            List<AsynchronousJob__c> asyncObjects = new List<AsynchronousJob__c>{
                    new AsynchronousJob__c(
                            Id = MockerV1.fakeId(AsynchronousJob__c.SObjectType),
                            Runnable__c = SingleConcurrencyTestRunnable.class.getName(),
                            ScheduledRunTime__c = CommonHelper.now().addSeconds(-10))
            };

            mockForRun(asyncObjects, 2, new Set<Id>{
                    asyncObjects[0].Id
            });

            AsynchronousScheduler.queue(new Set<String>(), 1);
            MockerV1.validate();

            asyncObjects = new List<AsynchronousJob__c>{
                    new AsynchronousJob__c(
                            Id = MockerV1.fakeId(AsynchronousJob__c.SObjectType),
                            Runnable__c = SingleConcurrencyTestRunnable.class.getName(),
                            ScheduledRunTime__c = CommonHelper.now().addSeconds(-10)),
                    new AsynchronousJob__c(
                            Id = MockerV1.fakeId(AsynchronousJob__c.SObjectType),
                            Runnable__c = SingleConcurrencyTestRunnable.class.getName(),
                            ScheduledRunTime__c = CommonHelper.now().addSeconds(-5))
            };

            mockForRun(asyncObjects, 2, new Set<Id>{
                    asyncObjects[0].Id
            });

            AsynchronousScheduler.queue(new Set<String>(), 1);
            MockerV1.validate();
        }
    }

    @IsTest
    private static void testDoubleConcurrency() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            List<AsynchronousJob__c> asyncObjects = new List<AsynchronousJob__c>{
                    new AsynchronousJob__c(
                            Id = MockerV1.fakeId(AsynchronousJob__c.SObjectType),
                            Runnable__c = DoubleConcurrencyTestRunnable.class.getName(),
                            ScheduledRunTime__c = CommonHelper.now().addSeconds(-10))
            };

            mockForRun(asyncObjects, 2, new Set<Id>{
                    asyncObjects[0].Id
            });

            AsynchronousScheduler.queue(new Set<String>(), 1);
            MockerV1.validate();

            asyncObjects = new List<AsynchronousJob__c>{
                    new AsynchronousJob__c(
                            Id = MockerV1.fakeId(AsynchronousJob__c.SObjectType),
                            Runnable__c = DoubleConcurrencyTestRunnable.class.getName(),
                            ScheduledRunTime__c = CommonHelper.now().addSeconds(-10)),
                    new AsynchronousJob__c(
                            Id = MockerV1.fakeId(AsynchronousJob__c.SObjectType),
                            Runnable__c = DoubleConcurrencyTestRunnable.class.getName(),
                            ScheduledRunTime__c = CommonHelper.now().addSeconds(-5))
            };

            mockForRun(asyncObjects, 2, new Set<Id>{
                    asyncObjects[0].Id, asyncObjects[1].Id
            });

            AsynchronousScheduler.queue(new Set<String>(), 1);
            MockerV1.validate();

            asyncObjects = new List<AsynchronousJob__c>{
                    new AsynchronousJob__c(
                            Id = MockerV1.fakeId(AsynchronousJob__c.SObjectType),
                            Runnable__c = DoubleConcurrencyTestRunnable.class.getName(),
                            ScheduledRunTime__c = CommonHelper.now().addSeconds(-10)),
                    new AsynchronousJob__c(
                            Id = MockerV1.fakeId(AsynchronousJob__c.SObjectType),
                            Runnable__c = DoubleConcurrencyTestRunnable.class.getName(),
                            ScheduledRunTime__c = CommonHelper.now().addSeconds(-5)),
                    new AsynchronousJob__c(
                            Id = MockerV1.fakeId(AsynchronousJob__c.SObjectType),
                            Runnable__c = DoubleConcurrencyTestRunnable.class.getName(),
                            ScheduledRunTime__c = CommonHelper.now().addSeconds(-1))
            };

            mockForRun(asyncObjects, 2, new Set<Id>{
                    asyncObjects[0].Id, asyncObjects[1].Id
            });

            AsynchronousScheduler.queue(new Set<String>(), 1);
            MockerV1.validate();
        }
    }

    @IsTest
    private static void testMixedConcurrency() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            List<AsynchronousJob__c> asyncObjects = new List<AsynchronousJob__c>{
                    new AsynchronousJob__c(
                            Id = MockerV1.fakeId(AsynchronousJob__c.SObjectType),
                            Runnable__c = SingleConcurrencyTestRunnable.class.getName(),
                            ScheduledRunTime__c = CommonHelper.now().addSeconds(-10)),
                    new AsynchronousJob__c(
                            Id = MockerV1.fakeId(AsynchronousJob__c.SObjectType),
                            Runnable__c = DoubleConcurrencyTestRunnable.class.getName(),
                            ScheduledRunTime__c = CommonHelper.now().addSeconds(-5)),
                    new AsynchronousJob__c(
                            Id = MockerV1.fakeId(AsynchronousJob__c.SObjectType),
                            Runnable__c = DoubleConcurrencyTestRunnable.class.getName(),
                            ScheduledRunTime__c = CommonHelper.now().addSeconds(-4))
            };

            mockForRun(asyncObjects, 1, new Set<Id>{
                    asyncObjects[0].Id
            });
            AsynchronousScheduler.queue(new Set<String>(), 1);
            MockerV1.validate();

            mockForRun(asyncObjects, 2, new Set<Id>{
                    asyncObjects[0].Id, asyncObjects[1].Id
            });
            AsynchronousScheduler.queue(new Set<String>(), 1);
            MockerV1.validate();

            mockForRun(asyncObjects, 3, new Set<Id>{
                    asyncObjects[0].Id, asyncObjects[1].Id, asyncObjects[2].Id
            });
            AsynchronousScheduler.queue(new Set<String>(), 1);
            MockerV1.validate();
        }
    }

    @IsTest
    private static void testMoreThanOneSchedulerCannotBeRun() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            Set<String> jobsToStart = new Set<String>{
                    MockerV1.fakeId(AsynchronousJob__c.SObjectType)
            };

            AsynchronousAPI.impl = (AsynchronousAPI) MockerV1.of(AsynchronousAPI.class)
                    .whenArguments(
                            AsynchronousScheduler.RunNextAvailable.class,
                            'Scheduler(1)',
                            0,
                            0,
                            new Map<String, String>{
                                    AsynchronousScheduler.JOBS_TO_START => JSON.serialize(jobsToStart),
                                    AsynchronousScheduler.SCHEDULER_DELAY => '0'
                            }
                    )
                        .forMethod('createJob')
                            .called(1)
                    .mock();

            AsynchronousDAO.impl = (AsynchronousDAO) MockerV1.of(AsynchronousDAO.class)
                    .whenArguments(
                            new AsynchronousJob__c(Runnable__c = AsynchronousScheduler.RunNextAvailable.class.getName()),
                            MockerV1.any(Integer.class)
                    )
                        .forMethod('countActiveObjects')
                            .called(1)
                            .returns(1)
                    .mock();

            AsynchronousScheduler.queue(jobsToStart, 1);
            MockerV1.validate();
        }
    }

    @IsTest
    private static void testGetMaximumActive() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            AsynchronousScheduler scheduler = new AsynchronousScheduler();
            Assert.areEqual(1, scheduler.getMaximumActive());
        }
    }

    @IsTest
    private static void testRunnableReturnValues() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            AsynchronousScheduler scheduler = new AsynchronousScheduler();

            AsynchronousV1.Job asyncJob = (AsynchronousV1.Job) MockerV1.of(AsynchronousJob.class)
                    .whenCalling('getState').called(2).returns(
                        new Map<String, String> { AsynchronousScheduler.JOBS_TO_START => '[]' }
                    )
                    .mock();

            AsynchronousDAO.impl = (AsynchronousDAO.API) MockerV1.of(AsynchronousDAOMockable.class)
                    .whenCalling('getScheduledObjects', MockerV1.any(Integer.class)).called(2).returns(new List<AsynchronousJob__c>())
                    .whenCalling('countSchedulableObjects', MockerV1.any(Integer.class), MockerV1.any(Integer.class)).called(2).returns(0)
                    .mock();

            Assert.isFalse(scheduler.onSuccess(asyncJob));
            Assert.isTrue(scheduler.onFailure(asyncJob, new DmlException('Test')));
            Assert.isFalse(scheduler.onCancellation((AsynchronousV1.Job) MockerV1.of(AsynchronousJob.class).mock()));

            MockerV1.validate();
        }
    }

    private static void mockForRun(List<AsynchronousJob__c> asyncObjects, Integer maxJobsToStart, Set<Id> jobsThatShouldBeStarted) {
        AsynchronousHelper.impl = (AsynchronousHelper) MockerV1.of(AsynchronousHelper.class)
                .whenArgument(new AsynchronousJob__c(
                        Runnable__c = AsynchronousScheduler.RunNextAvailable.class.getName(),
                        Status__c = AsynchronousV1.Status.PENDING.name()
                ))
                    .forMethod('queueJob')
                        .called(1)
                .mock();

        Map<String, Integer> maxCount = new Map<String, Integer>();
        Integer count = 0;
        for (AsynchronousJob__c asyncObject : asyncObjects) {
            String runnable = asyncObject.Runnable__c;
            if (!maxCount.containsKey(runnable)) {
                maxCount.put(
                        runnable,
                        ((AsynchronousV1.Runnable) TypesV1.newInstance(TypesV1.load(runnable))).getMaximumActive()
                );
            }

            if (++count == maxJobsToStart) {
                break;
            }
        }

        List<AsynchronousJob__c> scheduledObjects = new List<AsynchronousJob__c>();
        for (Integer i = 0; i < Math.min(asyncObjects.size(), maxJobsToStart); i++) {
            scheduledObjects.add(asyncObjects[i]);
        }

        MockerV1.Method mocked = MockerV1.of(AsynchronousDAO.class)
                .whenCalling('countSchedulableObjects', MockerV1.any(Integer.class), MockerV1.any(Integer.class))
                    .called(jobsThatShouldBeStarted.isEmpty() ? 0 : 1)
                    .returns(jobsThatShouldBeStarted.isEmpty() ? 0 : 1)
                .whenArgument(maxJobsToStart)
                    .forMethod('getScheduledObjects')
                        .called(1)
                        .returns(scheduledObjects)
                .whenArguments(
                        new AsynchronousJob__c(Runnable__c = AsynchronousScheduler.RunNextAvailable.class.getName()),
                        MockerV1.any(Integer.class)
                )
                    .forMethod('countActiveObjects')
                        .called(1)
                        .returns(0)
                .whenArguments(
                        new List<AsynchronousJob__c> {
                                new AsynchronousJob__c(
                                        Status__c = AsynchronousV1.Status.PENDING.name(),
                                        Runnable__c = AsynchronousScheduler.RunNextAvailable.class.getName()
                                )
                        },
                        new List<Map<String, String>>{
                                new Map<String, String>{
                                        AsynchronousScheduler.JOBS_TO_START => JSON.serialize(jobsThatShouldBeStarted),
                                        AsynchronousScheduler.SCHEDULER_DELAY => '0'
                                }
                        }
                )
                    .forMethod('persistObjects')
                        .called(1)
                .whenCalling('getWhenNextRequired', MockerV1.any(Integer.class)).called(1).returns(CommonHelper.now());

        for (String runnable : maxCount.keySet()) {
            mocked
                    .whenArguments(
                            new AsynchronousJob__c(Runnable__c = runnable),
                            MockerV1.any(Integer.class)
                    )
                        .forMethod('countActiveObjects')
                            .called(1)
                            .returns(0);
        }

        AsynchronousDAO.impl = (AsynchronousDAO) mocked.mock();

        AsynchronousScheduler.configuration = ImmutableV1.of(new Map<String, Integer> {
                AsynchronousScheduler.MAXIMUM_JOBS_TO_START_PROPERTY => maxJobsToStart,
                AsynchronousScheduler.NO_JOBS_TO_RUN_DELAY_PROPERTY => 1000
        });
    }

    public with sharing class SingleConcurrencyTestRunnable extends AsynchronousV1.Runnable {
        public SingleConcurrencyTestRunnable() {
            super(SingleConcurrencyTestRunnable.class);
        }

        public override Integer getMaximumActive() {
            return 1;
        }

        public override void run(AsynchronousV1.Job asyncJob, String apexJobId) {}
    }

    public with sharing class DoubleConcurrencyTestRunnable extends AsynchronousV1.Runnable {
        public DoubleConcurrencyTestRunnable() {
            super(DoubleConcurrencyTestRunnable.class);
        }

        public override Integer getMaximumActive() {
            return 2;
        }

        public override void run(AsynchronousV1.Job asyncJob, String apexJobId) {}
    }
}
