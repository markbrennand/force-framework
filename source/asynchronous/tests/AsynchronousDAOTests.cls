/**
 * @description
 * Unit tests for AsynchronousDAO class.
 * @author Mark Brennand
 */
@IsTest
public with sharing class AsynchronousDAOTests {

    @TestSetup
    private static void setup() {
        AsynchronousTestHelper.createUsers();
    }

    @IsTest
    private static void testCRUD() {
        System.runAs(AsynchronousTestHelper.getUser()) {
        /*
        AsynchronousHelper.INSTANCE = (AsynchronousHelper) Mocker.of(AsynchronousHelper.class)
                // Starting the Scheduler
                .whenArgument(new AsynchronousJob__c(Status__c = Asynchronous.Status.PENDING.name()))
                    .expectMethod('apiQueueJob').called(1)
                .mock();

        AsynchronousJob__c job1 = new AsynchronousJob__c(
                OwnerId = UserInfo.getUserId(),
                Runnable__c = TestRunnable.class.getName(),
                Status__c = Asynchronous.Status.PENDING.name(),
                MaximumRetries__c = 0,
                RetryInterval__c = 1000,
                Reference__c = 'TEST1',
                ScheduledRunTime__c = Datetime.now()
        );

        AsynchronousJob__c job2 = new AsynchronousJob__c(
                OwnerId = UserInfo.getUserId(),
                Runnable__c = TestRunnable.class.getName(),
                Status__c = Asynchronous.Status.PENDING.name(),
                MaximumRetries__c = 1,
                RetryInterval__c = 2000,
                Reference__c = 'TEST2',
                ScheduledRunTime__c = Datetime.now()
        );

        AsynchronousDAO.persistObjects(new List<AsynchronousJob__c> { job1, job2 });

        AsynchronousJob__c fetched1 = AsynchronousDAO.getObject(job1.Id);
        AsynchronousJob__c fetched2 = AsynchronousDAO.getObject(job2.Id);

        // Trigger should have updated the status and retry number.
        job1.Status__c = Asynchronous.Status.QUEUED.name();
        job1.RetryNumber__c = 0;
        job2.Status__c = Asynchronous.Status.QUEUED.name();
        job2.RetryNumber__c = 0;

        Assert.isTrue(ComparisonHelper.compare(job1, fetched1), 'Mis-match of data retrieved and data stored');
        Assert.isTrue(ComparisonHelper.compare(job2, fetched2), 'Mis-match of data retrieved and data stored');
        Mocker.validate();

        AsynchronousDAO.removeObjects(new List<AsynchronousJob__c> { fetched1 });

        try {
            AsynchronousDAO.getObject(fetched1.Id);
        } catch(Assertion.AssertionException ae) {
            Assert.isTrue(ae.getMessage().contains('not found'));
        }

        AsynchronousDAO.getObject(fetched2.Id);
         */
        }
    }

    @IsTest
    private static void testBindingCheck() {
        System.runAs(AsynchronousTestHelper.getUser()) {
            Dependency.bind(Asynchronous.DAO.class, AsynchronousDAO.Factory.class);
            try {
                Dependency.bind(Asynchronous.DAO.class, AsynchronousScheduler.QueueNext.class);
                Assert.fail();
            } catch (Dependency.APIException ae) {
                Assert.isTrue(
                        TestHelper.exceptionContains('Class AsynchronousScheduler.QueueNext does not implement Asynchronous.DAO', ae),
                        'Unexpected exception: ' + ae
                );
            }
        }
    }

    public with sharing class TestRunnable extends AsynchronousRunnable {

        public TestRunnable() {
            super(TestRunnable.class);
        }
    }
}