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
    private static void testCreateAndQueue() {
        System.runAs(AsynchronousTestHelper.getUser()) {
            Map<String, String> state = new Map<String, String>{
                    'Key1' => 'Value1', 'Key2' => 'Value2'
            };

            AsynchronousV1.Job job = AsynchronousImpl.INJECT.createJob(
                    AsynchronousScheduler.QueueNext.class,
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
            Assert.areEqual(AsynchronousV1.Status.PENDING, job.getStatus());

            AsynchronousDAO.INJECT = (AsynchronousDAO) MockerV1.of(AsynchronousDAO.class)
                    .whenArguments(
                            new List<AsynchronousJob__c>{
                                    new AsynchronousJob__c(Status__c = AsynchronousV1.Status.PENDING.name())
                            },
                            new List<Map<String, String>>{
                                    state
                            }
                    )
                        .forMethod('persistObjects').called(1).returns(new AddIdModifier())
                    .mock();

            for (AsynchronousV1.Job queuedJob : AsynchronousImpl.INJECT.queueJobs(new List<AsynchronousV1.Job>{
                    job
            })) {
                Assert.isNotNull(((AsynchronousJob) queuedJob).asyncObjectId);
            }

            MockerV1.validate();
        }
    }

    @IsTest
    private static void testMocking() {
        System.runAs(AsynchronousTestHelper.getUser()) {
            AsynchronousImpl.INJECT = createMock();

            AsynchronousV1.Job job = AsynchronousImpl.INJECT.createJob(
                    AsynchronousTests.class,
                    null,
                    1,
                    1000,
                    new Map<String, String>()
            );

            Assert.areEqual(AsynchronousV1.Status.CANCELLED, job.getStatus());
            Assert.areEqual('MOCKED', job.getReference());

            AsynchronousImpl.INJECT.queueJobs(new List<AsynchronousV1.Job>{ job });
            MockerV1.validate();
        }
    }

    @IsTest
    private static void testBindingCheck() {
        System.runAs(AsynchronousTestHelper.getUser()) {
            DependencyV1.bind(AsynchronousV1.API.class, AsynchronousImpl.Factory.class);
            try {
                DependencyV1.bind(AsynchronousV1.API.class, AsynchronousScheduler.QueueNext.class);
                Assert.fail();
            } catch (DependencyV1.APIException ae) {
                Assert.isTrue(
                        TestHelper.exceptionContains('Class AsynchronousScheduler.QueueNext does not implement AsynchronousV1.API', ae),
                        'Unexpected exception: ' + ae
                );
            }
        }
    }

    @IsTest
    private static void testTriggers() {
        System.runAs(AsynchronousTestHelper.getUser()) {
            AsynchronousJob__c asyncObject = new AsynchronousJob__c(
                    Status__c = AsynchronousV1.Status.PENDING.name(),
                    Runnable__c = AsynchronousScheduler.QueueNext.class.getName(),
                    MaximumRetries__c = 0,
                    RetryNumber__c = 1,
                    RetryInterval__c = 0,
                    ScheduledRunTime__c = Datetime.now()
            );

            insert asyncObject;
            asyncObject = [SELECT Status__c, RetryNumber__c FROM AsynchronousJob__c WHERE Id = :asyncObject.Id];
            Assert.areEqual(AsynchronousV1.Status.QUEUED.name(), asyncObject.Status__c);
            Assert.areEqual(0, asyncObject.RetryNumber__c);

            asyncObject = new AsynchronousJob__c(
                    Status__c = AsynchronousV1.Status.CANCELLED.name(),
                    Runnable__c = TestAsynchronousRunnable.class.getName(),
                    MaximumRetries__c = 0,
                    RetryNumber__c = 1,
                    RetryInterval__c = 0,
                    ScheduledRunTime__c = Datetime.now()
            );

            insert asyncObject;
            Assert.areEqual(1, [SELECT COUNT() FROM AsynchronousJob__c WHERE Id = :asyncObject.Id]);

            asyncObject = new AsynchronousJob__c(
                    Status__c = AsynchronousV1.Status.CANCELLED.name(),
                    Runnable__c = TestAsynchronousRunnable.class.getName(),
                    MaximumRetries__c = 1, // Causes runnable to request job deletion.
                    RetryNumber__c = 1,
                    RetryInterval__c = 0,
                    ScheduledRunTime__c = Datetime.now()
            );

            insert asyncObject;
            Assert.areEqual(0, [SELECT COUNT() FROM AsynchronousJob__c WHERE Id = :asyncObject.Id]);

            AsynchronousHelper.INJECT = (AsynchronousHelper) MockerV1.of(AsynchronousHelper.class)
                    .whenArgument(
                            new AsynchronousJob__c(Runnable__c = AsynchronousScheduler.QueueNext.class.getName())
                    )
                        .forMethod('queueJob').called(1)
                    .whenArguments(
                            new AsynchronousJob__c(Runnable__c = AsynchronousScheduler.QueueNext.class.getName()),
                            new Map<String, String>()
                    )
                        .withComparators(new List<Comparator<Object>> { new MapComparator() })
                        .forMethod('encodeState')
                            .called(1)
                            .returns(new List<AsynchronousJobState__c>())
                    .mock();

            asyncObject = new AsynchronousJob__c(
                    Status__c = AsynchronousV1.Status.PENDING.name(),
                    Runnable__c = TestAsynchronousRunnable.class.getName(),
                    MaximumRetries__c = 0,
                    RetryNumber__c = 0,
                    RetryInterval__c = 0,
                    ScheduledRunTime__c = Datetime.now()
            );

            insert asyncObject;
            MockerV1.validate();

            try {
                insert new AsynchronousJob__c(
                        Status__c = AsynchronousV1.Status.PENDING.name(),
                        Runnable__c = AsynchronousTests.class.getName(),
                        MaximumRetries__c = 0,
                        RetryNumber__c = 0,
                        RetryInterval__c = 0,
                        ScheduledRunTime__c = Datetime.now()
                );
                Assert.fail();

            } catch(DmlException de) {
                Assert.isTrue(
                    TestHelper.exceptionContains('Class AsynchronousTests does not implement Asynchronous.Runnable', de),
                    'Unexpected exception: ' + de
                );
            }
        }
    }

    private static AsynchronousImpl createMock() {
        AsynchronousV1.Job job = (AsynchronousV1.Job) MockerV1.of(AsynchronousJob.class)
                .whenNoArguments()
                    .forMethod('getReference').called(1).returns('MOCKED')
                    .forMethod('getStatus').called(1).returns(AsynchronousV1.Status.CANCELLED)
                .mock();

        return (AsynchronousImpl) MockerV1.of(AsynchronousImpl.class)
                .whenArguments(
                        AsynchronousTests.class,
                        null,
                        1,
                        1000,
                        new Map<String, String>()
                )
                    .forMethod('createJob').returns(job)
                .whenArgument(new List<AsynchronousV1.Job> { job })
                    .forMethod('queueJobs').called(1)
                .mock();
    }

    public with sharing class TestAsynchronousRunnable extends AsynchronousRunnableV1 {
        public TestAsynchronousRunnable() {
            super(TestAsynchronousRunnable.class);
        }

        public override Boolean onCancellation(AsynchronousV1.Job job) {
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

    private with sharing class MapComparator implements Comparator<Object> {
        public Integer compare(Object param1, Object param2) {
            if (param1 instanceof Map<String, String> && param2 instanceof Map<String, String>) {
                return 0;
            } else {
                return -1;
            }
        }
    }
}