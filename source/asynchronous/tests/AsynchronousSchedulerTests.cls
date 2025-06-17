/**
 * @description
 * Unit tests for Asynchronous Scheduler.
 *
 * @author Mark Brennand
 */
@IsTest
public with sharing class AsynchronousSchedulerTests {

    @TestSetup
    private static void setup() {
        AsynchronousTestHelper.createUsers();
    }

    @IsTest
    private static void testNullJobArgument() {
        System.runAs(AsynchronousTestHelper.getUser()) {
            try {
                new AsynchronousScheduler().run(null, 'ApexJobId');
                Assert.fail();
            } catch (Assertion.AssertionException ae) {
            }
        }
    }

    @IsTest
    private static void testDelayedWhenNoJobsToRun() {
        System.runAs(AsynchronousTestHelper.getUser()) {
            AsynchronousV1.Job asyncJob = (AsynchronousV1.Job) MockerV1.of(AsynchronousJob.class)
                    .whenNoArguments()
                        .forMethod('getState')
                            .called(1)
                            .returns(new Map<String, String>{
                                    AsynchronousFinalizer.JOBS_TO_START => JSON.serialize(new Set<String>())
                            })
                    .mock();


            AsynchronousScheduler scheduler = new AsynchronousScheduler();
            AsynchronousScheduler.CONFIGURATION = new Map<String, Integer>{
                    AsynchronousScheduler.NO_JOBS_TO_RUN_DELAY_PROPERTY => 5000
            };

            Long started = System.currentTimeMillis();
            scheduler.run(asyncJob, 'ApexJobId');

            Assert.isTrue((System.currentTimeMillis() - started) >= 5000);
            MockerV1.validate();
        }
    }

    @IsTest
    private static void testJobToRun() {
        System.runAs(AsynchronousTestHelper.getUser()) {
            Id asyncJobId1 = MockerV1.fakeId(AsynchronousJob__c.SObjectType);
            Id asyncJobId2 = MockerV1.fakeId(AsynchronousJob__c.SObjectType);

            AsynchronousJob__c asyncObject = new AsynchronousJob__c(Id = asyncJobId1);

            Map<String, String> state = new Map<String, String>{
                    AsynchronousFinalizer.JOBS_TO_START => JSON.serialize(new Set<String>{
                            asyncJobId1, asyncJobId2
                    })
            };

            AsynchronousDAO.INJECT = (AsynchronousDAO) MockerV1.of(AsynchronousDAO.class)
                    .whenArgument(asyncJobId1)
                        .forMethod('getObject')
                            .called(1)
                            .returns(asyncObject)
                    .mock();

            AsynchronousHelper.INJECT = (AsynchronousHelper.API) MockerV1.of(AsynchronousHelper.class)
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
        System.runAs(AsynchronousTestHelper.getUser()) {
            mockForRun(new List<AsynchronousJob__c>(), 1, new Set<Id>());
            AsynchronousScheduler.queue(new Set<String>());
            MockerV1.validate();
        }
    }

    @IsTest
    private static void testSingleConcurrency() {
        System.runAs(AsynchronousTestHelper.getUser()) {
            List<AsynchronousJob__c> asyncObjects = new List<AsynchronousJob__c>{
                    new AsynchronousJob__c(
                            Id = MockerV1.fakeId(AsynchronousJob__c.SObjectType),
                            Runnable__c = SingleConcurrencyTestRunnable.class.getName(),
                            ScheduledRunTime__c = DateTime.now().addSeconds(-10))
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
                            ScheduledRunTime__c = DateTime.now().addSeconds(-10)),
                    new AsynchronousJob__c(
                            Id = MockerV1.fakeId(AsynchronousJob__c.SObjectType),
                            Runnable__c = SingleConcurrencyTestRunnable.class.getName(),
                            ScheduledRunTime__c = DateTime.now().addSeconds(-5))
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
        System.runAs(AsynchronousTestHelper.getUser()) {
            List<AsynchronousJob__c> asyncObjects = new List<AsynchronousJob__c>{
                    new AsynchronousJob__c(
                            Id = MockerV1.fakeId(AsynchronousJob__c.SObjectType),
                            Runnable__c = DoubleConcurrencyTestRunnable.class.getName(),
                            ScheduledRunTime__c = DateTime.now().addSeconds(-10))
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
                            ScheduledRunTime__c = DateTime.now().addSeconds(-10)),
                    new AsynchronousJob__c(
                            Id = MockerV1.fakeId(AsynchronousJob__c.SObjectType),
                            Runnable__c = DoubleConcurrencyTestRunnable.class.getName(),
                            ScheduledRunTime__c = DateTime.now().addSeconds(-5))
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
                            ScheduledRunTime__c = DateTime.now().addSeconds(-10)),
                    new AsynchronousJob__c(
                            Id = MockerV1.fakeId(AsynchronousJob__c.SObjectType),
                            Runnable__c = DoubleConcurrencyTestRunnable.class.getName(),
                            ScheduledRunTime__c = DateTime.now().addSeconds(-5)),
                    new AsynchronousJob__c(
                            Id = MockerV1.fakeId(AsynchronousJob__c.SObjectType),
                            Runnable__c = DoubleConcurrencyTestRunnable.class.getName(),
                            ScheduledRunTime__c = DateTime.now().addSeconds(-1))
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
        System.runAs(AsynchronousTestHelper.getUser()) {
            List<AsynchronousJob__c> asyncObjects = new List<AsynchronousJob__c>{
                    new AsynchronousJob__c(
                            Id = MockerV1.fakeId(AsynchronousJob__c.SObjectType),
                            Runnable__c = SingleConcurrencyTestRunnable.class.getName(),
                            ScheduledRunTime__c = DateTime.now().addSeconds(-10)),
                    new AsynchronousJob__c(
                            Id = MockerV1.fakeId(AsynchronousJob__c.SObjectType),
                            Runnable__c = DoubleConcurrencyTestRunnable.class.getName(),
                            ScheduledRunTime__c = DateTime.now().addSeconds(-5)),
                    new AsynchronousJob__c(
                            Id = MockerV1.fakeId(AsynchronousJob__c.SObjectType),
                            Runnable__c = DoubleConcurrencyTestRunnable.class.getName(),
                            ScheduledRunTime__c = DateTime.now().addSeconds(-4))
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
        System.runAs(AsynchronousTestHelper.getUser()) {
            Set<String> jobsToStart = new Set<String>{
                    MockerV1.fakeId(AsynchronousJob__c.SObjectType)
            };

            AsynchronousImpl.INJECT = (AsynchronousImpl) MockerV1.of(AsynchronousImpl.class)
                    .whenArguments(
                            AsynchronousScheduler.QueueNext.class,
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

            AsynchronousDAO.INJECT = (AsynchronousDAO) MockerV1.of(AsynchronousDAO.class)
                    .whenArgument(new AsynchronousJob__c(Runnable__c = AsynchronousScheduler.QueueNext.class.getName()))
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
        System.runAs(AsynchronousTestHelper.getUser()) {
            AsynchronousScheduler scheduler = new AsynchronousScheduler();
            Assert.areEqual(1, scheduler.getMaximumActive());
        }
    }

    @IsTest
    private static void testRunnableReturnValues() {
        System.runAs(AsynchronousTestHelper.getUser()) {
            AsynchronousScheduler scheduler = new AsynchronousScheduler();
            Assert.isFalse(scheduler.onSuccess((AsynchronousV1.Job) MockerV1.of(AsynchronousJob.class).mock()));
            Assert.isTrue(scheduler.onFailure((AsynchronousV1.Job) MockerV1.of(AsynchronousJob.class).mock(), new DMLException('Test')));
            Assert.isFalse(scheduler.onCancellation((AsynchronousV1.Job) MockerV1.of(AsynchronousJob.class).mock()));
        }
    }

    private static void mockForRun(List<AsynchronousJob__c> asyncObjects, Integer maxJobsToStart, Set<Id> jobsThatShouldBeStarted) {
        AsynchronousHelper.INJECT = (AsynchronousHelper) MockerV1.of(AsynchronousHelper.class)
                .whenArgument(new AsynchronousJob__c(
                        Runnable__c = AsynchronousScheduler.QueueNext.class.getName(),
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

        Set<AsynchronousJob__c> scheduledObjects = new Set<AsynchronousJob__c>();
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
                .whenArgument(new AsynchronousJob__c(Runnable__c = AsynchronousScheduler.QueueNext.class.getName()))
                    .forMethod('countActiveObjects')
                        .called(1)
                        .returns(0)
                .whenArguments(
                        new List<AsynchronousJob__c> {
                                new AsynchronousJob__c(
                                        Status__c = AsynchronousV1.Status.PENDING.name(),
                                        Runnable__c = AsynchronousScheduler.QueueNext.class.getName()
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

        AsynchronousDAO.INJECT = (AsynchronousDAO) mocked.mock();

        AsynchronousScheduler.CONFIGURATION = new Map<String, Integer> {
                AsynchronousScheduler.MAXIMUM_JOBS_TO_START_PROPERTY => maxJobsToStart,
                AsynchronousScheduler.NO_JOBS_TO_RUN_DELAY_PROPERTY => 1000
        };
    }

    public with sharing class SingleConcurrencyTestRunnable extends AsynchronousRunnableV1 {
        public SingleConcurrencyTestRunnable() {
            super(SingleConcurrencyTestRunnable.class);
        }

        public override Integer getMaximumActive() {
            return 1;
        }
    }

    public with sharing class DoubleConcurrencyTestRunnable extends AsynchronousRunnableV1 {
        public DoubleConcurrencyTestRunnable() {
            super(DoubleConcurrencyTestRunnable.class);
        }

        public override Integer getMaximumActive() {
            return 2;
        }
    }
}