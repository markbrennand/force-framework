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
            Asynchronous.Job asyncJob = (Asynchronous.Job) Mocker.of(AsynchronousJob.class)
                    .whenNoArguments()
                        .expectMethod('getState')
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
            Mocker.validate();
        }
    }

    @IsTest
    private static void testJobToRun() {
        System.runAs(AsynchronousTestHelper.getUser()) {
            Id asyncJobId1 = TestHelper.nextId(AsynchronousJob__c.SObjectType);
            Id asyncJobId2 = TestHelper.nextId(AsynchronousJob__c.SObjectType);

            AsynchronousJob__c asyncObject = new AsynchronousJob__c(Id = asyncJobId1);

            Map<String, String> state = new Map<String, String>{
                    AsynchronousFinalizer.JOBS_TO_START => JSON.serialize(new Set<String>{
                            asyncJobId1, asyncJobId2
                    })
            };

            AsynchronousDAO.INSTANCE = (AsynchronousDAO) Mocker.of(AsynchronousDAO.class)
                    .whenArgument(asyncJobId1)
                        .expectMethod('apiGetObject').called(1).returns(asyncObject)
                    .mock();

            AsynchronousHelper.INSTANCE = (AsynchronousHelper) Mocker.of(AsynchronousHelper.class)
                    .whenArgument(asyncObject)
                        .expectMethod('apiQueueJob').called(1)
                    .mock();

            Asynchronous.Job asyncJob = (Asynchronous.Job) Mocker.of(AsynchronousJob.class)
                    .whenNoArguments()
                        .expectMethod('getState').called(1).returns(state)

                    // Confirms that the job to be run has been removed from the state.
                    .whenArgument(new Map<String, String>{
                            AsynchronousFinalizer.JOBS_TO_START => JSON.serialize(new Set<String>{
                                    asyncJobId2
                            })
                    })
                        .expectMethod('setState').called(1)
                    .mock();

            AsynchronousScheduler scheduler = new AsynchronousScheduler();
            scheduler.run(asyncJob, 'ApexJobId');
            Assert.areEqual('ApexJobId', asyncObject.ApexJobId__c);
            Mocker.validate();
        }
    }

    @IsTest
    private static void testSchedulerQueuedWhenJobsToStart() {
        System.runAs(AsynchronousTestHelper.getUser()) {
            mockForRun(new List<AsynchronousJob__c>(), 1, new Set<Id>());
            AsynchronousScheduler.queue(new Set<String>());
            Mocker.validate();
        }
    }

    @IsTest
    private static void testSingleConcurrency() {
        System.runAs(AsynchronousTestHelper.getUser()) {
            List<AsynchronousJob__c> asyncObjects = new List<AsynchronousJob__c>{
                    new AsynchronousJob__c(
                            Id = TestHelper.nextId(AsynchronousJob__c.SObjectType),
                            Runnable__c = SingleConcurrencyTestRunnable.class.getName(),
                            ScheduledRunTime__c = DateTime.now().addSeconds(-10))
            };

            mockForRun(asyncObjects, 2, new Set<Id>{
                    asyncObjects[0].Id
            });

            AsynchronousScheduler.queue(new Set<String>());
            Mocker.validate();

            asyncObjects = new List<AsynchronousJob__c>{
                    new AsynchronousJob__c(
                            Id = TestHelper.nextId(AsynchronousJob__c.SObjectType),
                            Runnable__c = SingleConcurrencyTestRunnable.class.getName(),
                            ScheduledRunTime__c = DateTime.now().addSeconds(-10)),
                    new AsynchronousJob__c(
                            Id = TestHelper.nextId(AsynchronousJob__c.SObjectType),
                            Runnable__c = SingleConcurrencyTestRunnable.class.getName(),
                            ScheduledRunTime__c = DateTime.now().addSeconds(-5))
            };

            mockForRun(asyncObjects, 2, new Set<Id>{
                    asyncObjects[0].Id
            });

            AsynchronousScheduler.queue(new Set<String>());
            Mocker.validate();
        }
    }

    @IsTest
    private static void testDoubleConcurrency() {
        System.runAs(AsynchronousTestHelper.getUser()) {
            List<AsynchronousJob__c> asyncObjects = new List<AsynchronousJob__c>{
                    new AsynchronousJob__c(
                            Id = TestHelper.nextId(AsynchronousJob__c.SObjectType),
                            Runnable__c = DoubleConcurrencyTestRunnable.class.getName(),
                            ScheduledRunTime__c = DateTime.now().addSeconds(-10))
            };

            mockForRun(asyncObjects, 2, new Set<Id>{
                    asyncObjects[0].Id
            });

            AsynchronousScheduler.queue(new Set<String>());
            Mocker.validate();

            asyncObjects = new List<AsynchronousJob__c>{
                    new AsynchronousJob__c(
                            Id = TestHelper.nextId(AsynchronousJob__c.SObjectType),
                            Runnable__c = DoubleConcurrencyTestRunnable.class.getName(),
                            ScheduledRunTime__c = DateTime.now().addSeconds(-10)),
                    new AsynchronousJob__c(
                            Id = TestHelper.nextId(AsynchronousJob__c.SObjectType),
                            Runnable__c = DoubleConcurrencyTestRunnable.class.getName(),
                            ScheduledRunTime__c = DateTime.now().addSeconds(-5))
            };

            mockForRun(asyncObjects, 2, new Set<Id>{
                    asyncObjects[0].Id, asyncObjects[1].Id
            });

            AsynchronousScheduler.queue(new Set<String>());
            Mocker.validate();

            asyncObjects = new List<AsynchronousJob__c>{
                    new AsynchronousJob__c(
                            Id = TestHelper.nextId(AsynchronousJob__c.SObjectType),
                            Runnable__c = DoubleConcurrencyTestRunnable.class.getName(),
                            ScheduledRunTime__c = DateTime.now().addSeconds(-10)),
                    new AsynchronousJob__c(
                            Id = TestHelper.nextId(AsynchronousJob__c.SObjectType),
                            Runnable__c = DoubleConcurrencyTestRunnable.class.getName(),
                            ScheduledRunTime__c = DateTime.now().addSeconds(-5)),
                    new AsynchronousJob__c(
                            Id = TestHelper.nextId(AsynchronousJob__c.SObjectType),
                            Runnable__c = DoubleConcurrencyTestRunnable.class.getName(),
                            ScheduledRunTime__c = DateTime.now().addSeconds(-1))
            };

            mockForRun(asyncObjects, 2, new Set<Id>{
                    asyncObjects[0].Id, asyncObjects[1].Id
            });

            AsynchronousScheduler.queue(new Set<String>());
            Mocker.validate();
        }
    }

    @IsTest
    private static void testMixedConcurrency() {
        System.runAs(AsynchronousTestHelper.getUser()) {
            List<AsynchronousJob__c> asyncObjects = new List<AsynchronousJob__c>{
                    new AsynchronousJob__c(
                            Id = TestHelper.nextId(AsynchronousJob__c.SObjectType),
                            Runnable__c = SingleConcurrencyTestRunnable.class.getName(),
                            ScheduledRunTime__c = DateTime.now().addSeconds(-10)),
                    new AsynchronousJob__c(
                            Id = TestHelper.nextId(AsynchronousJob__c.SObjectType),
                            Runnable__c = DoubleConcurrencyTestRunnable.class.getName(),
                            ScheduledRunTime__c = DateTime.now().addSeconds(-5)),
                    new AsynchronousJob__c(
                            Id = TestHelper.nextId(AsynchronousJob__c.SObjectType),
                            Runnable__c = DoubleConcurrencyTestRunnable.class.getName(),
                            ScheduledRunTime__c = DateTime.now().addSeconds(-4))
            };

            mockForRun(asyncObjects, 1, new Set<Id>{
                    asyncObjects[0].Id
            });
            AsynchronousScheduler.queue(new Set<String>());
            Mocker.validate();

            mockForRun(asyncObjects, 2, new Set<Id>{
                    asyncObjects[0].Id, asyncObjects[1].Id
            });
            AsynchronousScheduler.queue(new Set<String>());
            Mocker.validate();

            mockForRun(asyncObjects, 3, new Set<Id>{
                    asyncObjects[0].Id, asyncObjects[1].Id, asyncObjects[2].Id
            });
            AsynchronousScheduler.queue(new Set<String>());
            Mocker.validate();
        }
    }

    @IsTest
    private static void testMoreThanOneSchedulerCannotBeRun() {
        System.runAs(AsynchronousTestHelper.getUser()) {
            Set<String> jobsToStart = new Set<String>{
                    TestHelper.nextId(AsynchronousJob__c.SObjectType)
            };

            Asynchronous.INSTANCE = (Asynchronous) Mocker.of(Asynchronous.class)
                    .whenArguments(
                            AsynchronousScheduler.QueueNext.class,
                            null,
                            0,
                            0,
                            new Map<String, String>{
                                    AsynchronousFinalizer.JOBS_TO_START => JSON.serialize(jobsToStart)
                            }
                    )
                        .expectMethod('apiCreateJob').called(1)
                    .mock();

            AsynchronousDAO.INSTANCE = (AsynchronousDAO) Mocker.of(AsynchronousDAO.class)
                    .whenArgument(new AsynchronousJob__c(Runnable__c = AsynchronousScheduler.QueueNext.class.getName()))
                        .expectMethod('apiCountActiveObjects').called(1).returns(1)
                    .mock();

            AsynchronousScheduler.queue(jobsToStart);
            Mocker.validate();
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
            Assert.isFalse(scheduler.onSuccess((Asynchronous.Job) Mocker.of(AsynchronousJob.class).mock()));
            Assert.isTrue(scheduler.onFailure((Asynchronous.Job) Mocker.of(AsynchronousJob.class).mock(), new DMLException('Test')));
            Assert.isFalse(scheduler.onCancellation((Asynchronous.Job) Mocker.of(AsynchronousJob.class).mock()));
        }
    }

    private static void mockForRun(List<AsynchronousJob__c> asyncObjects, Integer maxJobsToStart, Set<Id> jobsThatShouldBeStarted) {
        AsynchronousHelper.INSTANCE = (AsynchronousHelper) Mocker.of(AsynchronousHelper.class)
                .whenArgument(new AsynchronousJob__c(
                        Runnable__c = AsynchronousScheduler.QueueNext.class.getName(),
                        Status__c = Asynchronous.Status.PENDING.name()
                ))
                    .expectMethod('apiQueueJob').called(1)
                .mock();

        Map<String, Integer> maxCount = new Map<String, Integer>();
        Integer count = 0;
        for (AsynchronousJob__c asyncObject : asyncObjects) {
            String runnable = asyncObject.Runnable__c;
            if (!maxCount.containsKey(runnable)) {
                maxCount.put(
                        runnable,
                        ((Asynchronous.Runnable) Types.newInstance(Types.load(runnable))).getMaximumActive()
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

        Mocker.Method mocked = Mocker.of(AsynchronousDAO.class)
                .whenNoArguments()
                    .expectMethod('apiCountSchedulableObjects').called(jobsThatShouldBeStarted.isEmpty() ? 1 : 0).returns(1)
                .whenArgument(maxJobsToStart)
                    .expectMethod('apiGetScheduledObjects').called(1)
                        .returns(scheduledObjects)
                .whenArgument(new AsynchronousJob__c(Runnable__c = AsynchronousScheduler.QueueNext.class.getName()))
                    .expectMethod('apiCountActiveObjects').called(1).returns(0)
                .whenArguments(
                        new List<AsynchronousJob__c> {
                                new AsynchronousJob__c(
                                        Status__c = Asynchronous.Status.PENDING.name(),
                                        Runnable__c = AsynchronousScheduler.QueueNext.class.getName()
                                )
                        },
                        new List<Map<String, String>>{
                                new Map<String, String>{
                                        AsynchronousFinalizer.JOBS_TO_START => JSON.serialize(jobsThatShouldBeStarted)
                                }
                        }
                )
                    .expectMethod('apiPersistObjects').called(1);

        for (String runnable : maxCount.keySet()) {
            mocked
                    .whenArgument(new AsynchronousJob__c(Runnable__c = runnable))
                        .expectMethod('apiCountActiveObjects').called(1).returns(0);
        }

        AsynchronousDAO.INSTANCE = (AsynchronousDAO) mocked.mock();

        AsynchronousScheduler.CONFIGURATION = new Map<String, Integer> {
                AsynchronousScheduler.MAXIMUM_JOBS_TO_START_PROPERTY => maxJobsToStart,
                AsynchronousScheduler.NO_JOBS_TO_RUN_DELAY_PROPERTY => 1000
        };
    }

    public with sharing class SingleConcurrencyTestRunnable extends AsynchronousRunnable {
        public SingleConcurrencyTestRunnable() {
            super(SingleConcurrencyTestRunnable.class);
        }

        public override Integer getMaximumActive() {
            return 1;
        }
    }

    public with sharing class DoubleConcurrencyTestRunnable extends AsynchronousRunnable {
        public DoubleConcurrencyTestRunnable() {
            super(DoubleConcurrencyTestRunnable.class);
        }

        public override Integer getMaximumActive() {
            return 2;
        }
    }
}