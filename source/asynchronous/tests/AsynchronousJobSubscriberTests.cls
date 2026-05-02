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

            AsynchronousAPI.impl = (AsynchronousAPI.API) MockerV1.of(AsynchronousAPIMockable.class)
                    .whenArguments(
                            AsynchronousScheduler.RunNextAvailable.class,
                            MockerV1.any(String.class),
                            0,
                            0,
                            MockerV1.any(Map<String, String>.class)
                    )
                        .forMethod('createJob')
                            .called(1)
                            .returns(AsynchronousJob.fromSObject(asyncJob))
                    .whenArgument(
                            new List<AsynchronousV1.Job>{
                                    AsynchronousJob.fromSObject(asyncJob)
                            }
                    )
                        .forMethod('queue')
                            .called(0)
                            .returns(new List<AsynchronousV1.Job>{
                                    AsynchronousJob.fromSObject(asyncJob)
                         })
                    .mock();

            AsynchronousDAO.impl = (AsynchronousDAO.API) MockerV1.of(AsynchronousDAOMockable.class)
                    .whenArgument(new List<AsynchronousJob__c>{
                            asyncJob
                    })
                        .forMethod('persist')
                            .called(0)
                    .whenArgument(1)
                        .forMethod('getScheduledObjects')
                            .called(1)
                            .returns(new List<AsynchronousJob__c>())
                    .whenArguments(1, MockerV1.any(Integer.class))
                        .forMethod('countSchedulableObjects')
                            .called(1)
                            .returns(1)
                    .whenArguments(
                            new AsynchronousJob__c(Runnable__c = AsynchronousScheduler.RunNextAvailable.class.getName()),
                            MockerV1.any(Integer.class)
                    )
                        .forMethod('countActiveObjects')
                            .called(1)
                            .returns(0)
                    .whenArguments(
                            new List<AsynchronousJob__c> {
                                    new AsynchronousJob__c(Runnable__c = AsynchronousScheduler.RunSweeper.class.getName())
                            },
                            MockerV1.any(List<Map<String, String>>.class)
                    )
                        .forMethod('persistObjects')
                            .called(1)
                    .mock();

            AsynchronousHelper.impl = (AsynchronousHelper.API) MockerV1.of(AsynchronousHelperMockable.class)
                    .whenArgument(new AsynchronousJob__c(Runnable__c = AsynchronousScheduler.RunSweeper.class.getName()))
                            .forMethod('queueJob')
                                .called(1)
                    .mock();

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

            AsynchronousAPI.impl = (AsynchronousAPI.API) MockerV1.of(AsynchronousAPIMockable.class)
                    .whenArguments(
                            AsynchronousScheduler.RunNextAvailable.class,
                            MockerV1.any(String.class),
                            0,
                            0,
                            MockerV1.any(Map<String, String>.class)
                    )
                        .forMethod('createJob')
                            .called(0)
                            .returns(AsynchronousJob.fromSObject(asyncJob))
                    .whenArgument(
                            new List<AsynchronousV1.Job> {
                                    AsynchronousJob.fromSObject(asyncJob)
                            }
                    )
                        .forMethod('queue')
                            .called(0)
                            .returns(new List<AsynchronousV1.Job> { AsynchronousJob.fromSObject(asyncJob) })
                    .mock();

            AsynchronousDAO.impl = (AsynchronousDAO.API) MockerV1.of(AsynchronousDAOMockable.class)
                    .whenArgument(new List<AsynchronousJob__c> { asyncJob })
                        .forMethod('persist')
                            .called(0)
                    .whenArgument(1)
                        .forMethod('getScheduledObjects')
                            .called(1)
                            .returns(new List<AsynchronousJob__c>())
                    .whenArguments(1, MockerV1.any(Integer.class))
                        .forMethod('countSchedulableObjects')
                            .called(1)
                            .returns(0)
                    .mock();

            Test.startTest();
            insert asyncJob;
            Test.stopTest();

            Assert.areEqual(
                    Datetime.newInstance(1900, 1, 1),
                    [SELECT ScheduledRunTime__c FROM AsynchronousJob__c LIMIT 1].ScheduledRunTime__c
            );

            MockerV1.validate();
        }
    }
}