/**
 * @description
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../../LICENSE target="_blank">MIT License</a>.
 * <br><br>
 * Unit tests for Trigger API.
 *
 * @author Mark Brennand
 */
@IsTest
public with sharing class TriggerTests {
    private final static Map<String, Integer> INVOCATIONS = new Map<String, Integer>();
    private final static Map<String, List<Id>> INSERTED_IDS = new Map<String, List<Id>>();
    private final static Map<String, List<Id>> UPDATED_IDS = new Map<String, List<Id>>();
    private final static Map<String, List<Id>> DELETED_IDS = new Map<String, List<Id>>();
    private final static Map<String, Integer> MAX_RECURSIVE_DEPTH = new Map<String, Integer> {
            'Subscriber1' => 1,
            'Subscriber2' => 1
    };

    private static Integer INCREMENT = 0;

    @TestSetup
    private static void setup() {
        TriggerTestHelper.createUsers();
    }

    @IsTest
    private static void testOperations() {
        TestHelper.setNOW();
        System.runAs(TriggerTestHelper.getUser()) {
            TriggerV1.disable(AsynchronousJobSubscriber.Factory.class);

            AsynchronousJob__c job1 = new AsynchronousJob__c(
                    Runnable__c = AsynchronousScheduler.RunNextAvailable.class.getName(),
                    MaximumRetries__c = 0,
                    RetryNumber__c = 0,
                    RetryInterval__c = 0,
                    ScheduledRunTime__c = CommonHelper.now(),
                    Status__c = AsynchronousV1.Status.SUCCEEDED.name()
            );

            AsynchronousJob__c job2 = new AsynchronousJob__c(
                    Runnable__c = AsynchronousScheduler.RunNextAvailable.class.getName(),
                    MaximumRetries__c = 0,
                    RetryNumber__c = 0,
                    RetryInterval__c = 0,
                    ScheduledRunTime__c = CommonHelper.now(),
                    Status__c = AsynchronousV1.Status.SUCCEEDED.name()
            );

            insert new List<AsynchronousJob__c> { job1, job2 };

            INCREMENT = 1;
            job1.RetryInterval__c = job1.RetryInterval__c + INCREMENT;
            job2.RetryInterval__c = job2.RetryInterval__c + INCREMENT;

            upsert new List<AsynchronousJob__c> { job1, job2 };
            delete new List<AsynchronousJob__c> { job1, job2 };

            Assert.areEqual(8, INVOCATIONS.size());
            Assert.areEqual(1, INVOCATIONS.get('Subscriber1.before.INSERTING'));
            Assert.areEqual(1, INVOCATIONS.get('Subscriber1.after.INSERTING'));
            Assert.areEqual(1, INVOCATIONS.get('Subscriber1.before.UPDATING'));
            Assert.areEqual(1, INVOCATIONS.get('Subscriber1.after.UPDATING'));
            Assert.areEqual(1, INVOCATIONS.get('Subscriber2.before.INSERTING'));
            Assert.areEqual(1, INVOCATIONS.get('Subscriber2.after.INSERTING'));
            Assert.areEqual(1, INVOCATIONS.get('Subscriber2.before.DELETING'));
            Assert.areEqual(1, INVOCATIONS.get('Subscriber2.after.DELETING'));

            Assert.isTrue(INSERTED_IDS.get('Subscriber1').contains(job1.Id));
            Assert.isTrue(INSERTED_IDS.get('Subscriber1').contains(job2.Id));
            Assert.isTrue(INSERTED_IDS.get('Subscriber2').contains(job1.Id));
            Assert.isTrue(INSERTED_IDS.get('Subscriber2').contains(job2.Id));
            Assert.isTrue(UPDATED_IDS.get('Subscriber1').contains(job1.Id));
            Assert.isTrue(UPDATED_IDS.get('Subscriber1').contains(job2.Id));
            Assert.isFalse(UPDATED_IDS.containsKey('Subscriber2'));
            Assert.isTrue(DELETED_IDS.get('Subscriber2').contains(job1.Id));
            Assert.isTrue(DELETED_IDS.get('Subscriber2').contains(job2.Id));
            Assert.isFalse(DELETED_IDS.containsKey('Subscriber1'));
        }
    }

    @IsTest
    private static void testSubscriberNotCalledIfRecursiveDepthExceeded() {
        TestHelper.setNOW();
        System.runAs(TriggerTestHelper.getUser()) {
            TriggerV1.disable(AsynchronousJobSubscriber.Factory.class);
            TriggerV1.disable(Subscriber2.class);

            MAX_RECURSIVE_DEPTH.put('Subscriber1', 12);

            insert new AsynchronousJob__c(
                    Runnable__c = AsynchronousScheduler.RunNextAvailable.class.getName(),
                    MaximumRetries__c = 0,
                    RetryNumber__c = 0,
                    RetryInterval__c = 0,
                    ScheduledRunTime__c = CommonHelper.now(),
                    Status__c = AsynchronousV1.Status.SUCCEEDED.name()
            );

            Assert.areEqual(4, INSERTED_IDS.get('Subscriber1').size());
        }
    }

    @IsTest
    private static void testObjectEnablement() {
        TestHelper.setNOW();
        System.runAs(TriggerTestHelper.getUser()) {
            Assert.isTrue(TriggerV1.isEnabled(AsynchronousJob__c.SObjectType));
            TriggerV1.disable(AsynchronousJob__c.SObjectType);
            Assert.isFalse(TriggerV1.isEnabled(AsynchronousJob__c.SObjectType));

            insert new AsynchronousJob__c(
                    Runnable__c = AsynchronousScheduler.RunNextAvailable.class.getName(),
                    MaximumRetries__c = 0,
                    RetryNumber__c = 0,
                    RetryInterval__c = 0,
                    ScheduledRunTime__c = CommonHelper.now(),
                    Status__c = AsynchronousV1.Status.SUCCEEDED.name()
            );

            Assert.isFalse(INSERTED_IDS.containsKey('Subscriber1'));
            Assert.isFalse(INSERTED_IDS.containsKey('Subscriber2'));

            TriggerV1.enable(AsynchronousJob__c.SObjectType);
            Assert.isTrue(TriggerV1.isEnabled(AsynchronousJob__c.SObjectType));

            INSERTED_IDS.clear();
            insert new AsynchronousJob__c(
                    Runnable__c = AsynchronousScheduler.RunNextAvailable.class.getName(),
                    MaximumRetries__c = 0,
                    RetryNumber__c = 0,
                    RetryInterval__c = 0,
                    ScheduledRunTime__c = CommonHelper.now(),
                    Status__c = AsynchronousV1.Status.SUCCEEDED.name()
            );

            Assert.isTrue(INSERTED_IDS.containsKey('Subscriber1'));
            Assert.isTrue(INSERTED_IDS.containsKey('Subscriber2'));
        }
    }

    @IsTest
    private static void testSubscriberEnablement() {
        TestHelper.setNOW();
        System.runAs(TriggerTestHelper.getUser()) {
            Assert.isTrue(TriggerV1.isEnabled(Subscriber1.class));
            TriggerV1.disable(Subscriber1.class);
            Assert.isFalse(TriggerV1.isEnabled(Subscriber1.class));

            insert new AsynchronousJob__c(
                    Runnable__c = AsynchronousScheduler.RunNextAvailable.class.getName(),
                    MaximumRetries__c = 0,
                    RetryNumber__c = 0,
                    RetryInterval__c = 0,
                    ScheduledRunTime__c = CommonHelper.now(),
                    Status__c = AsynchronousV1.Status.SUCCEEDED.name()
            );

            Assert.isFalse(INSERTED_IDS.containsKey('Subscriber1'));
            Assert.isTrue(INSERTED_IDS.containsKey('Subscriber2'));

            TriggerV1.enable(Subscriber1.class);
            Assert.isTrue(TriggerV1.isEnabled(Subscriber1.class));

            INSERTED_IDS.clear();
            insert new AsynchronousJob__c(
                    Runnable__c = AsynchronousScheduler.RunNextAvailable.class.getName(),
                    MaximumRetries__c = 0,
                    RetryNumber__c = 0,
                    RetryInterval__c = 0,
                    ScheduledRunTime__c = CommonHelper.now(),
                    Status__c = AsynchronousV1.Status.SUCCEEDED.name()
            );

            Assert.isTrue(INSERTED_IDS.containsKey('Subscriber1'));
            Assert.isTrue(INSERTED_IDS.containsKey('Subscriber2'));
        }
    }

    @IsTest
    private static void testExceptionThrownIfRecursiveDepthExceeded() {
        TestHelper.setNOW();
        System.runAs(TriggerTestHelper.getUser()) {
            TriggerV1.disable(AsynchronousJobSubscriber.Factory.class);
            TriggerV1.disable(Subscriber1.class);

            MAX_RECURSIVE_DEPTH.put('Subscriber2', 12);

            try {
                insert new AsynchronousJob__c(
                        Runnable__c = AsynchronousScheduler.RunNextAvailable.class.getName(),
                        MaximumRetries__c = 0,
                        RetryNumber__c = 0,
                        RetryInterval__c = 0,
                        ScheduledRunTime__c = CommonHelper.now(),
                        Status__c = AsynchronousV1.Status.SUCCEEDED.name()
                );
            } catch(DmlException de) {
                Assert.isTrue(TestHelper.exceptionContains('Maximum recursive calls exceeded for AsynchronousJob event', de));
            }
        }
    }

    @IsTest
    private static void testMocking() {
        TestHelper.setNOW();
        System.runAs(TriggerTestHelper.getUser()) {
            TriggerAPI.API = (TriggerAPI.API) MockerV1.of(TriggerAPI.class)
                    .whenNoArguments()
                    .forMethod('publish')
                    .called(2)
                    .whenArgument(AsynchronousJobSubscriber.Factory.class)
                    .forMethod('enable')
                    .called(1)
                    .forMethod('disable')
                    .called(1)
                    .forMethod('isEnabled')
                    .called(1)
                    .returns(true)
                    .whenArgument(AsynchronousJob__c.SObjectType)
                    .forMethod('enable')
                    .called(1)
                    .forMethod('disable')
                    .called(1)
                    .forMethod('isEnabled')
                    .called(1)
                    .returns(false)
                    .mock();

            insert new AsynchronousJob__c(
                    Runnable__c = AsynchronousScheduler.RunNextAvailable.class.getName(),
                    MaximumRetries__c = 0,
                    RetryNumber__c = 0,
                    RetryInterval__c = 0,
                    ScheduledRunTime__c = CommonHelper.now(),
                    Status__c = AsynchronousV1.Status.SUCCEEDED.name()
            );

            TriggerV1.enable(AsynchronousJobSubscriber.Factory.class);
            TriggerV1.disable(AsynchronousJobSubscriber.Factory.class);
            Assert.isTrue(TriggerV1.isEnabled(AsynchronousJobSubscriber.Factory.class));

            TriggerV1.enable(AsynchronousJob__c.SObjectType);
            TriggerV1.disable(AsynchronousJob__c.SObjectType);
            Assert.isFalse(TriggerV1.isEnabled(AsynchronousJob__c.SObjectType));

            MockerV1.validate();
        }
    }

    @IsTest
    private static void testIsSubscriberBoundToAction() {
        TestHelper.setNOW();
        Trigger__mdt triggerDefinition = new Trigger__mdt();
        triggerDefinition.BeforeInsert__c = true;
        triggerDefinition.AfterInsert__c  = false;
        Assert.isTrue(TriggerAPI.isSubscriberBoundToAction(triggerDefinition, TriggerV1.Operation.INSERTING, true));
        Assert.isFalse(TriggerAPI.isSubscriberBoundToAction(triggerDefinition, TriggerV1.Operation.INSERTING, false));
        triggerDefinition.BeforeInsert__c = false;
        triggerDefinition.AfterInsert__c = true;
        Assert.isFalse(TriggerAPI.isSubscriberBoundToAction(triggerDefinition, TriggerV1.Operation.INSERTING, true));
        Assert.isTrue(TriggerAPI.isSubscriberBoundToAction(triggerDefinition, TriggerV1.Operation.INSERTING, false));

        triggerDefinition = new Trigger__mdt();
        triggerDefinition.BeforeUpdate__c = true;
        triggerDefinition.AfterUpdate__c  = false;
        Assert.isTrue(TriggerAPI.isSubscriberBoundToAction(triggerDefinition, TriggerV1.Operation.UPDATING, true));
        Assert.isFalse(TriggerAPI.isSubscriberBoundToAction(triggerDefinition, TriggerV1.Operation.UPDATING, false));
        triggerDefinition.BeforeUpdate__c = false;
        triggerDefinition.AfterUpdate__c = true;
        Assert.isFalse(TriggerAPI.isSubscriberBoundToAction(triggerDefinition, TriggerV1.Operation.UPDATING, true));
        Assert.isTrue(TriggerAPI.isSubscriberBoundToAction(triggerDefinition, TriggerV1.Operation.UPDATING, false));

        triggerDefinition = new Trigger__mdt();
        triggerDefinition.BeforeDelete__c = true;
        triggerDefinition.AfterDelete__c  = false;
        Assert.isTrue(TriggerAPI.isSubscriberBoundToAction(triggerDefinition, TriggerV1.Operation.DELETING, true));
        Assert.isFalse(TriggerAPI.isSubscriberBoundToAction(triggerDefinition, TriggerV1.Operation.DELETING, false));
        triggerDefinition.BeforeDelete__c = false;
        triggerDefinition.AfterDelete__c = true;
        Assert.isFalse(TriggerAPI.isSubscriberBoundToAction(triggerDefinition, TriggerV1.Operation.DELETING, true));
        Assert.isTrue(TriggerAPI.isSubscriberBoundToAction(triggerDefinition, TriggerV1.Operation.DELETING, false));
    }

    @IsTest
    private static void testBindingCheck() {
        TestHelper.setNOW();
        System.runAs(TriggerTestHelper.getUser()) {
            DependencyV1.bind(TriggerAPI.API.class, TriggerAPI.Factory.class);
            try {
                DependencyV1.bind(TriggerAPI.API.class, AsynchronousScheduler.RunNextAvailable.class);
                Assert.fail();
            } catch (DependencyV1.APIException ae) {
                Assert.isTrue(
                        TestHelper.exceptionContains('Class AsynchronousScheduler.RunNextAvailable does not implement TriggerAPI.API', ae),
                        'Unexpected exception: ' + ae
                );
            }
        }
    }

    @IsTest
    private static void testExtendedClassIsInert() {
        TestHelper.setNOW();
        ExtendedClass extended = new ExtendedClass();

        try {
            extended.publish();
            Assert.fail();
        } catch (TriggerV1.APIException ae) {
            Assert.areEqual('Access denied', ae.getMessage());
        }

        try {
            extended.disable(AsynchronousJob__c.SObjectType);
            Assert.fail();
        } catch (TriggerV1.APIException ae) {
            Assert.areEqual('Access denied', ae.getMessage());
        }

        try {
            extended.enable(AsynchronousJob__c.SObjectType);
            Assert.fail();
        } catch (TriggerV1.APIException ae) {
            Assert.areEqual('Access denied', ae.getMessage());
        }

        try {
            extended.isEnabled(AsynchronousJob__c.SObjectType);
            Assert.fail();
        } catch (TriggerV1.APIException ae) {
            Assert.areEqual('Access denied', ae.getMessage());
        }

        try {
            extended.disable(Subscriber1.class);
            Assert.fail();
        } catch (TriggerV1.APIException ae) {
            Assert.areEqual('Access denied', ae.getMessage());
        }

        try {
            extended.enable(Subscriber1.class);
            Assert.fail();
        } catch (TriggerV1.APIException ae) {
            Assert.areEqual('Access denied', ae.getMessage());
        }

        try {
            extended.isEnabled(Subscriber1.class);
            Assert.fail();
        } catch (TriggerV1.APIException ae) {
            Assert.areEqual('Access denied', ae.getMessage());
        }
    }

    public with sharing class Subscriber1 implements TriggerV1.Subscriber {

        public void onEvent(TriggerV1.Event event) {
            invoke('Subscriber1', event);

            if (event.isAfter()) {
                List<AsynchronousJob__c> records = (List<AsynchronousJob__c>) event.getRecords();
                Map<Id, AsynchronousJob__c> recordsMap = new Map<Id, AsynchronousJob__c>(records);

                for (AsynchronousJob__c record : records) {
                    if (event.hasOldValue(record)) {
                        if (((AsynchronousJob__c) event.getOldValue(record)).RetryInterval__c != record.RetryInterval__c - INCREMENT) {
                            throw new DMLException('Retry interval was not incremented');
                        }
                    }
                }

                List<AsynchronousJob__c> oldRecords = (List<AsynchronousJob__c>) event.getOldValues();
                if (!oldRecords.isEmpty()) {
                    for (AsynchronousJob__c record : oldRecords) {
                        if (!recordsMap.containsKey(record.Id)) {
                            throw new DMLException('Old records contains an additional record');
                        }
                    }
                }

                if (event.getRecursiveDepth() < MAX_RECURSIVE_DEPTH.get('Subscriber1')) {
                    insert new AsynchronousJob__c(
                            Runnable__c = AsynchronousScheduler.RunNextAvailable.class.getName(),
                            MaximumRetries__c = 0,
                            RetryNumber__c = 0,
                            RetryInterval__c = 0,
                            ScheduledRunTime__c = CommonHelper.now(),
                            Status__c = AsynchronousV1.Status.FAILED.name()
                    );
                }
            }

            DependencyV1.reload();
        }
    }

    public with sharing class Subscriber2 implements TriggerV1.Subscriber {

        public void onEvent(TriggerV1.Event event) {
            invoke('Subscriber2', event);

            if (event.isAfter() && event.getRecursiveDepth() < MAX_RECURSIVE_DEPTH.get('Subscriber2')) {
                insert new AsynchronousJob__c(
                        Runnable__c = AsynchronousScheduler.RunNextAvailable.class.getName(),
                        MaximumRetries__c = 0,
                        RetryNumber__c = 0,
                        RetryInterval__c = 0,
                        ScheduledRunTime__c = CommonHelper.now(),
                        Status__c = AsynchronousV1.Status.FAILED.name()
                );
            }

            DependencyV1.reload();
        }
    }

    private static void invoke(String subscriber, TriggerV1.Event event) {
        final List<Id> listToUpdate;
        switch on event.getOperation() {
            when INSERTING {
                if (INSERTED_IDS.containsKey(subscriber)) {
                    listToUpdate = INSERTED_IDS.get(subscriber);
                } else {
                    listToUpdate = new List<Id>();
                    INSERTED_IDS.put(subscriber, listToUpdate);
                }
            }
            when UPDATING {
                if (UPDATED_IDS.containsKey(subscriber)) {
                    listToUpdate = UPDATED_IDS.get(subscriber);
                } else {
                    listToUpdate = new List<Id>();
                    UPDATED_IDS.put(subscriber, listToUpdate);
                }
            }
            when else {
                if (DELETED_IDS.containsKey(subscriber)) {
                    listToUpdate = DELETED_IDS.get(subscriber);
                } else {
                    listToUpdate = new List<Id>();
                    DELETED_IDS.put(subscriber, listToUpdate);
                }
            }
        }

        for (SObject record : event.getRecords()) {
            listToUpdate.add(record.Id);
        }

        final String key = subscriber
                + '.'
                + (event.isBefore() ? 'before' : 'after')
                + '.'
                + event.getOperation().name();

        if (INVOCATIONS.containsKey(key)) {
            INVOCATIONS.put(key, INVOCATIONS.get(key) + 1);
        } else {
            INVOCATIONS.put(key, 1);
        }
    }

    private with sharing class ExtendedClass extends TriggerAPI {}
}