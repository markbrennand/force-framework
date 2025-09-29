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
    private static void testDelayedWhenNoJobsToRun() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            AsynchronousV1.Job asyncJob = (AsynchronousV1.Job) MockerV1.of(AsynchronousJob.class)
                    .whenNoArguments()
                        .forMethod('getState')
                            .called(1)
                            .returns(new Map<String, String>{
                                    AsynchronousFinalizer.JOBS_TO_START => JSON.serialize(new Set<String>())
                            })
                    .mock();


            AsynchronousScheduler scheduler = new AsynchronousScheduler();
            AsynchronousScheduler.configuration = ImmutableV1.of(new Map<String, Integer>{
                    AsynchronousScheduler.NO_JOBS_TO_RUN_DELAY_PROPERTY => 5000
            });

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
                    AsynchronousFinalizer.JOBS_TO_START => JSON.serialize(new Set<String>{
                            asyncJobId1, asyncJobId2
                    })
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
                            AsynchronousFinalizer.JOBS_TO_START => JSON.serialize(new Set<String>{
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
            mockForRun(new List<AsynchronousJob__c>(), 1, new Set<Id>());
            AsynchronousScheduler.queue(new Set<String>());
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

            AsynchronousScheduler.queue(new Set<String>());
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

            AsynchronousScheduler.queue(new Set<String>());
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

            AsynchronousScheduler.queue(new Set<String>());
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

            AsynchronousScheduler.queue(new Set<String>());
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

            AsynchronousScheduler.queue(new Set<String>());
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
            AsynchronousScheduler.queue(new Set<String>());
            MockerV1.validate();

            mockForRun(asyncObjects, 2, new Set<Id>{
                    asyncObjects[0].Id, asyncObjects[1].Id
            });
            AsynchronousScheduler.queue(new Set<String>());
            MockerV1.validate();

            mockForRun(asyncObjects, 3, new Set<Id>{
                    asyncObjects[0].Id, asyncObjects[1].Id, asyncObjects[2].Id
            });
            AsynchronousScheduler.queue(new Set<String>());
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
                            null,
                            0,
                            0,
                            new Map<String, String>{
                                    AsynchronousFinalizer.JOBS_TO_START => JSON.serialize(jobsToStart)
                            }
                    )
                        .forMethod('createJob')
                            .called(1)
                    .mock();

            AsynchronousDAO.impl = (AsynchronousDAO) MockerV1.of(AsynchronousDAO.class)
                    .whenArgument(new AsynchronousJob__c(Runnable__c = AsynchronousScheduler.RunNextAvailable.class.getName()))
                        .forMethod('countActiveObjects')
                            .called(1)
                            .returns(1)
                    .mock();

            AsynchronousScheduler.queue(jobsToStart);
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
            Assert.isFalse(scheduler.onSuccess((AsynchronousV1.Job) MockerV1.of(AsynchronousJob.class).mock()));
            Assert.isTrue(scheduler.onFailure((AsynchronousV1.Job) MockerV1.of(AsynchronousJob.class).mock(), new DmlException('Test')));
            Assert.isFalse(scheduler.onCancellation((AsynchronousV1.Job) MockerV1.of(AsynchronousJob.class).mock()));
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
                .whenNoArguments()
                    .forMethod('countSchedulableObjects')
                        .called(jobsThatShouldBeStarted.isEmpty() ? 1 : 0)
                        .returns(1)
                .whenArgument(maxJobsToStart)
                    .forMethod('getScheduledObjects')
                        .called(1)
                        .returns(scheduledObjects)
                .whenArgument(new AsynchronousJob__c(Runnable__c = AsynchronousScheduler.RunNextAvailable.class.getName()))
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
                                        AsynchronousFinalizer.JOBS_TO_START => JSON.serialize(jobsThatShouldBeStarted)
                                }
                        }
                )
                    .forMethod('persistObjects')
                        .called(1);

        for (String runnable : maxCount.keySet()) {
            mocked
                    .whenArgument(new AsynchronousJob__c(Runnable__c = runnable))
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
