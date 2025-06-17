/**
 * @description
 * Unit tests for AsynchronousDAO class.
 *
 * @author Mark Brennand
 */
@IsTest
public with sharing class AsynchronousDAOTests {

    @TestSetup
    private static void setup() {
        AsynchronousTestHelper.createUsers();
    }

    @IsTest
    private static void testExtendedClassIsInsert() {
        ExtendedClass extended = new ExtendedClass();

        try {
            extended.getObject(null);
            Assert.fail();
        } catch(AsynchronousV1.APIException ae) {
            Assert.areEqual('Access denied', ae.getMessage());
        }

        try {
            extended.getScheduledObjects(null);
            Assert.fail();
        } catch(AsynchronousV1.APIException ae) {
            Assert.areEqual('Access denied', ae.getMessage());
        }

        try {
            extended.countSchedulableObjects();
            Assert.fail();
        } catch(AsynchronousV1.APIException ae) {
            Assert.areEqual('Access denied', ae.getMessage());
        }

        try {
            extended.countActiveObjects(null);
            Assert.fail();
        } catch(AsynchronousV1.APIException ae) {
            Assert.areEqual('Access denied', ae.getMessage());
        }

        try {
            extended.persistObjects(null);
            Assert.fail();
        } catch(AsynchronousV1.APIException ae) {
            Assert.areEqual('Access denied', ae.getMessage());
        }

        try {
            extended.persistObjects(null, null);
            Assert.fail();
        } catch(AsynchronousV1.APIException ae) {
            Assert.areEqual('Access denied', ae.getMessage());
        }

        try {
            extended.removeObjects(null);
            Assert.fail();
        } catch(AsynchronousV1.APIException ae) {
            Assert.areEqual('Access denied', ae.getMessage());
        }

        try {
            extended.persistException(null);
            Assert.fail();
        } catch(AsynchronousV1.APIException ae) {
            Assert.areEqual('Access denied', ae.getMessage());
        }
    }

    @IsTest
    private static void testJobCRUD() {
        System.runAs(AsynchronousTestHelper.getUser()) {
            AsynchronousHelper.INJECT = (AsynchronousHelper) MockerV1.of(AsynchronousHelper.class)
                    .whenArgument(new AsynchronousJob__c(Status__c = AsynchronousV1.Status.PENDING.name()))
                        .forMethod('queueJob').called(0)
                    .mock();

            AsynchronousJob__c job1 = new AsynchronousJob__c(
                    OwnerId = UserInfo.getUserId(),
                    Runnable__c = TestRunnable.class.getName(),
                    Status__c = AsynchronousV1.Status.PENDING.name(),
                    MaximumRetries__c = 0,
                    RetryInterval__c = 1000,
                    RetryNumber__c = 1,
                    Reference__c = 'TEST1',
                    ScheduledRunTime__c = Datetime.now()
            );

            AsynchronousJob__c job2 = new AsynchronousJob__c(
                    OwnerId = UserInfo.getUserId(),
                    Runnable__c = TestRunnable.class.getName(),
                    Status__c = AsynchronousV1.Status.PENDING.name(),
                    MaximumRetries__c = 1,
                    RetryInterval__c = 2000,
                    RetryNumber__c = 1,
                    Reference__c = 'TEST2',
                    ScheduledRunTime__c = Datetime.now()
            );

            AsynchronousDAO.INJECT.persistObjects(new List<AsynchronousJob__c>{
                    job1, job2
            });

            AsynchronousJob__c fetched1 = AsynchronousDAO.INJECT.getObject(job1.Id);
            AsynchronousJob__c fetched2 = AsynchronousDAO.INJECT.getObject(job2.Id);

            Assert.isTrue(ComparisonHelper.compare(job1, fetched1), 'Mis-match of data retrieved and data stored');
            Assert.isTrue(ComparisonHelper.compare(job2, fetched2), 'Mis-match of data retrieved and data stored');

            AsynchronousDAO.INJECT.removeObjects(new List<AsynchronousJob__c> { fetched1 });
            try {
                AsynchronousDAO.INJECT.getObject(fetched1.Id);
            } catch(Assertion.AssertionException ae) {
                Assert.isTrue(ae.getMessage().contains('not found'));
            }

            fetched2.LastRunTime__c = Datetime.now();
            fetched2.Status__c = AsynchronousV1.Status.FAILED.name();

            AsynchronousDAO.INJECT.persistObjects(new List<AsynchronousJob__c> { fetched2 });
            AsynchronousJob__c updatedFetched2 = AsynchronousDAO.INJECT.getObject(job2.Id);
            Assert.isTrue(ComparisonHelper.compare(fetched2, updatedFetched2), 'Mis-match of data retrieved and data stored');

            MockerV1.validate();
        }
    }

    @IsTest
    private static void testJobAndStateCRUD() {
        System.runAs(AsynchronousTestHelper.getUser()) {
            AsynchronousHelper.INJECT = (AsynchronousHelper) MockerV1.of(AsynchronousHelper.class)
                    .whenArgument(new AsynchronousJob__c(Status__c = AsynchronousV1.Status.PENDING.name()))
                        .forMethod('queueJob').called(1)
                    .whenArguments(
                            new AsynchronousJob__c(Status__c = AsynchronousV1.Status.PENDING.name()),
                            MockerV1.anyNonNull(Map<String, String>.class)
                    )
                        .forMethod('encodeState')
                        .called(3)
                        .returns(new AsynchronousStateModifier())
            .mock();

            AsynchronousJob__c job1 = new AsynchronousJob__c(
                    OwnerId = UserInfo.getUserId(),
                    Runnable__c = TestRunnable.class.getName(),
                    Status__c = AsynchronousV1.Status.PENDING.name(),
                    MaximumRetries__c = 0,
                    RetryInterval__c = 1000,
                    RetryNumber__c = 1,
                    Reference__c = 'TEST1',
                    ScheduledRunTime__c = Datetime.now()
            );

            Map<String, String> state1 = new Map<String, String> { 'job1.property1' => 'job1.value1', 'job1.property2' => 'job1.value2' };

            AsynchronousJob__c job2 = new AsynchronousJob__c(
                    OwnerId = UserInfo.getUserId(),
                    Runnable__c = TestRunnable.class.getName(),
                    Status__c = AsynchronousV1.Status.PENDING.name(),
                    MaximumRetries__c = 1,
                    RetryInterval__c = 2000,
                    RetryNumber__c = 1,
                    Reference__c = 'TEST2',
                    ScheduledRunTime__c = Datetime.now()
            );

            Map<String, String> state2 = new Map<String, String> { 'job2.property1' => 'job2.value1', 'job2.property2' => 'job2.value2' };

            AsynchronousDAO.INJECT.persistObjects(
                    new List<AsynchronousJob__c> { job1, job2 },
                    new List<Map<String, String>> { state1, state2 }
            );

            AsynchronousJob__c fetched1 = AsynchronousDAO.INJECT.getObject(job1.Id);
            AsynchronousJob__c fetched2 = AsynchronousDAO.INJECT.getObject(job2.Id);

            job1.Status__c = AsynchronousV1.Status.QUEUED.name();
            job1.RetryNumber__c = 0;
            job2.Status__c = AsynchronousV1.Status.QUEUED.name();
            job2.RetryNumber__c = 0;

            Assert.isTrue(ComparisonHelper.compare(job1, fetched1), 'Mis-match of data retrieved and data stored');
            Assert.isTrue(ComparisonHelper.compare(job2, fetched2), 'Mis-match of data retrieved and data stored');
            Assert.areEqual('{"job1.property2":"job1.value2","job1.property1":"job1.value1"}', fetched1.AsynchronousJobState__r[0].Content__c, 'Unexpected JSON content for state');
            Assert.areEqual('{"job2.property2":"job2.value2","job2.property1":"job2.value1"}', fetched2.AsynchronousJobState__r[0].Content__c, 'Unexpected JSON content for state');

            AsynchronousDAO.INJECT.removeObjects(new List<AsynchronousJob__c> { fetched1 });
            try {
                AsynchronousDAO.INJECT.getObject(fetched1.Id);
            } catch(Assertion.AssertionException ae) {
                Assert.isTrue(ae.getMessage().contains('not found'));
            }

            fetched2.LastRunTime__c = Datetime.now();
            fetched2.Status__c = AsynchronousV1.Status.FAILED.name();

            AsynchronousDAO.INJECT.persistObjects(new List<AsynchronousJob__c> { fetched2 });
            AsynchronousJob__c updatedFetched2 = AsynchronousDAO.INJECT.getObject(job2.Id);
            Assert.isTrue(ComparisonHelper.compare(fetched2, updatedFetched2), 'Mis-match of data retrieved and data stored');
            Assert.areEqual('{"job2.property2":"job2.value2","job2.property1":"job2.value1"}', updatedFetched2.AsynchronousJobState__r[0].Content__c, 'Unexpected JSON content for state');


            MockerV1.validate();
        }
    }

    @IsTest
    private static void testBindingCheck() {
        System.runAs(AsynchronousTestHelper.getUser()) {
            DependencyV1.bind(AsynchronousV1.DAO.class, AsynchronousDAO.Factory.class);
            try {
                DependencyV1.bind(AsynchronousV1.DAO.class, AsynchronousScheduler.QueueNext.class);
                Assert.fail('Binding check should fail');
            } catch (DependencyV1.APIException ae) {
                Assert.isTrue(
                        TestHelper.exceptionContains('Class AsynchronousScheduler.QueueNext does not implement AsynchronousV1.DAO', ae),
                        'Unexpected exception: ' + ae
                );
            }
        }
    }

    public with sharing class TestRunnable extends AsynchronousRunnableV1 {

        public TestRunnable() {
            super(TestRunnable.class);
        }
    }

    private with sharing class AsynchronousStateModifier implements MockerV1.Modifier {
        private AsynchronousHelper.API api = (AsynchronousHelper.API) new AsynchronousHelper.Factory().newInstance();

        public Object process(List<Object> arguments) {
            return api.encodeState((AsynchronousJob__c) arguments[0], (Map<String, String>) arguments[1]);
        }
    }

    private with sharing class ExtendedClass extends AsynchronousDAO {}
}