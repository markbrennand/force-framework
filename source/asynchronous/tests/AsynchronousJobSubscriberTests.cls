/**
 * @description
 * <p>
 * Class providing unit tests for AsynchronousJobSubscriber class.
 * <p>
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../LICENSE target="_blank">MIT License</a>.
 *
 * @author Mark Brennand
 */
@IsTest
public with sharing class AsynchronousJobSubscriberTests {
    private final static String TESTING = 'asynchronous';

    @TestSetup
    private static void createUsers() {
        TestHelper.createUsers(TESTING, new Set<String> { 'ForceFwDependencyInjectionPermissions', 'ForceFwAsynchronousPermissions' });
    }

    @IsTest
    private static void itShouldStartScheduler() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            AsynchronousJob__c asyncJob = new AsynchronousJob__c(
                    Runnable__c = AsynchronousScheduler.RunSweeper.class.getName(),
                    OwnerId = TestHelper.getUser(TESTING).Id,
                    Status__c = AsynchronousV1.Status.PENDING.name(),
                    MaximumRetries__c = 0,
                    RetryInterval__c = 0,
                    RetryNumber__c = 0,
                    ScheduledRunTime__c = CommonHelper.now()
            );

            mock(asyncJob, 1, 1, 1, 1, 1, 1, 1);

            Test.startTest();
            insert asyncJob;
            Test.stopTest();

            MockerV1.validate();
        }
    }

    @IsTest
    private static void itShouldAddSweeperToHeadOfQueue() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            AsynchronousJob__c asyncJob = new AsynchronousJob__c(
                    Runnable__c = AsynchronousScheduler.RunSweeper.class.getName(),
                    OwnerId = TestHelper.getUser(TESTING).Id,
                    Status__c = AsynchronousV1.Status.PENDING.name(),
                    MaximumRetries__c = 0,
                    RetryInterval__c = 0,
                    RetryNumber__c = 0,
                    ScheduledRunTime__c = CommonHelper.now()
            );

            mock(asyncJob, 1, 1, 1, 1, 1, 1, 1);

            Test.startTest();
            insert asyncJob;
            Test.stopTest();

            String sweeperClass = AsynchronousScheduler.RunSweeper.class.getName();

            Assert.areEqual(
                    Datetime.newInstance(1900, 1, 1),
                    [SELECT ScheduledRunTime__c FROM AsynchronousJob__c WHERE Runnable__c = :sweeperClass LIMIT 1].ScheduledRunTime__c
            );

            MockerV1.validate();
        }
    }

    @IsTest
    private static void itShouldChangeStatusToQueued() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            AsynchronousJob__c asyncJob = new AsynchronousJob__c(
                    Runnable__c = AsynchronousScheduler.RunNextAvailable.class.getName(),
                    OwnerId = TestHelper.getUser(TESTING).Id,
                    Status__c = AsynchronousV1.Status.PENDING.name(),
                    MaximumRetries__c = 0,
                    RetryInterval__c = 0,
                    RetryNumber__c = 100, // Must be reset
                    ScheduledRunTime__c = CommonHelper.now().addHours(-1),
                    LastRunTime__c = CommonHelper.now() // Must be reset,
            );

            mock(asyncJob, 0, 0, 0, 0, 0, 0, 0);

            Test.startTest();
            insert asyncJob;
            Test.stopTest();

            Datetime now = CommonHelper.now();
            String queued = AsynchronousV1.Status.QUEUED.name();

            Assert.areEqual(
                    1,
                    [
                            SELECT COUNT()
                            FROM AsynchronousJob__c
                            WHERE ScheduledRunTime__c = :now AND LastRunTime__c = NULL AND Status__c = :queued AND RetryNumber__c = 0
                    ]
            );

            MockerV1.validate();
        }
    }

    @SuppressWarnings('PMD.ExcessiveParameterList')
    private static void mock(
            final AsynchronousJob__c asyncJob,
            final Integer createJobCalls,
            final Integer getScheduledObjectsCalls,
            final Integer countSchedulableObjectsCalls,
            final Integer countActiveObjectsCalls,
            final Integer persistObjectsCalls,
            final Integer queueJobCalls,
            final Integer whenNextRequiredCalls
    ) {
        AsynchronousAPI.impl = (AsynchronousAPI.API) MockerV1.of(AsynchronousAPIMockable.class)
                .whenCalling(
                        'createJob',
                        AsynchronousScheduler.RunNextAvailable.class,
                        MockerV1.any(String.class),
                        0,
                        0,
                        MockerV1.any(Map<String, String>.class)
                )
                    .called(createJobCalls).returns(AsynchronousJob.fromSObject(asyncJob))
                .whenCalling('queue', new List<AsynchronousV1.Job>{ AsynchronousJob.fromSObject(asyncJob) })
                    .called(0) .returns(new List<AsynchronousV1.Job>{ AsynchronousJob.fromSObject(asyncJob) })
                .mock();

        AsynchronousDAO.impl = (AsynchronousDAO.API) MockerV1.of(AsynchronousDAOMockable.class)
                .whenCalling('persist', new List<AsynchronousJob__c>{ asyncJob }).called(0)
                .whenCalling('getScheduledObjects', 1).called(getScheduledObjectsCalls).returns(new List<AsynchronousJob__c>())
                .whenCalling('countSchedulableObjects', 1, MockerV1.any(Integer.class))
                    .called(countSchedulableObjectsCalls).returns(countSchedulableObjectsCalls)
                .whenCalling(
                        'countActiveObjects',
                        new AsynchronousJob__c(Runnable__c = AsynchronousScheduler.RunNextAvailable.class.getName()),
                        MockerV1.any(Integer.class)
                )
                    .called(countActiveObjectsCalls).returns(0)
                .whenCalling(
                        'persistObjects',
                        new List<AsynchronousJob__c> {
                                new AsynchronousJob__c(Runnable__c = AsynchronousScheduler.RunSweeper.class.getName())
                        },
                        MockerV1.any(List<Map<String, String>>.class)
                )
                    .called(persistObjectsCalls)
                .whenCalling('getWhenNextRequired', MockerV1.any(Integer.class)).called(whenNextRequiredCalls).returns(CommonHelper.now())
                .mock();

        AsynchronousHelper.impl = (AsynchronousHelper.API) MockerV1.of(AsynchronousHelperMockable.class)
                .whenCalling(
                        'queueJob',
                        new AsynchronousJob__c(Runnable__c = AsynchronousScheduler.RunSweeper.class.getName())
                )
                    .called(queueJobCalls)
                .mock();
    }
}