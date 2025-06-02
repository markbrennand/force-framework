/**
 * @description
 * Unit tests for Asynchronous Finalizer.
 *
 * @author Mark Brennand
 */
@IsTest
public with sharing class AsynchronousFinalizerTests {

    @TestSetup
    private static void setup() {
        AsynchronousTestHelper.createUsers();
    }

    @IsTest
    private static void testJobKeptOnSuccess() {
        System.runAs(AsynchronousTestHelper.getUser()) {
            AsynchronousJob__c asyncObject = new AsynchronousJob__c(
                    Id = Mocker.fakeId(AsynchronousJob__c.SObjectType),
                    Status__c = Asynchronous.Status.RUNNING.name(),
                    OwnerId = UserInfo.getUserId(),
                    MaximumRetries__c = 0, // Makes TestRunnable.onSuccess return true.
                    RetryInterval__c = 0,
                    RetryNumber__c = 0,
                    Runnable__c = TestRunnable.class.getName(),
                    ScheduledRunTime__c = Datetime.now()
            );

            AsynchronousDAO.INSTANCE = (AsynchronousDAO) mockForSuccess(asyncObject, false).mock();
            AsynchronousFinalizer.createFinalizer(asyncObject.Id).execute(new Context(null));
            Mocker.validate();
        }
    }

    @IsTest
    private static void testJobDeletedOnSuccess() {
        System.runAs(AsynchronousTestHelper.getUser()) {
            AsynchronousJob__c asyncObject = new AsynchronousJob__c(
                    Id = Mocker.fakeId(AsynchronousJob__c.SObjectType),
                    Status__c = Asynchronous.Status.RUNNING.name(),
                    OwnerId = UserInfo.getUserId(),
                    MaximumRetries__c = 1, // Makes TestRunnable.onSuccess return false.
                    RetryInterval__c = 0,
                    RetryNumber__c = 0,
                    Runnable__c = TestRunnable.class.getName(),
                    ScheduledRunTime__c = Datetime.now()
            );

            AsynchronousDAO.INSTANCE = (AsynchronousDAO) mockForSuccess(asyncObject, true).mock();
            AsynchronousFinalizer.createFinalizer(asyncObject.Id).execute(new Context(null));
            Mocker.validate();
        }
    }

    @IsTest
    private static void testExceptionInOnSuccess() {
        System.runAs(AsynchronousTestHelper.getUser()) {
            AsynchronousJob__c asyncObject = new AsynchronousJob__c(
                    Id = Mocker.fakeId(AsynchronousJob__c.SObjectType),
                    Status__c = Asynchronous.Status.RUNNING.name(),
                    OwnerId = UserInfo.getUserId(),
                    MaximumRetries__c = 0,
                    RetryInterval__c = 1, // Makes TestRunnable.onSuccess throw an Exception.
                    RetryNumber__c = 0,
                    Runnable__c = TestRunnable.class.getName(),
                    ScheduledRunTime__c = Datetime.now()
            );

            AsynchronousDAO.INSTANCE = (AsynchronousDAO) mockForException(asyncObject, false, 'onSuccess failed').mock();
            AsynchronousFinalizer.createFinalizer(asyncObject.Id).execute(new Context(null));
            Mocker.validate();
        }
    }

    @IsTest
    private static void testJobKeptOnFailure() {
        System.runAs(AsynchronousTestHelper.getUser()) {
            AsynchronousJob__c asyncObject = new AsynchronousJob__c(
                    Id = Mocker.fakeId(AsynchronousJob__c.SObjectType),
                    Status__c = Asynchronous.Status.RUNNING.name(),
                    OwnerId = UserInfo.getUserId(),
                    MaximumRetries__c = 0, // Makes TestRunnable.onFailure return true.
                    RetryInterval__c = 0,
                    RetryNumber__c = 0,
                    Runnable__c = TestRunnable.class.getName(),
                    ScheduledRunTime__c = Datetime.now()
            );

            Exception exc = new Asynchronous.APIException('Test');

            AsynchronousDAO.INSTANCE = (AsynchronousDAO) mockForFailure(asyncObject, Asynchronous.Status.FAILED, exc, false).mock();
            AsynchronousFinalizer.createFinalizer(asyncObject.Id).execute(new Context(exc));
            Mocker.validate();
        }
    }

    @IsTest
    private static void testJobDeletedOnFailure() {
        System.runAs(AsynchronousTestHelper.getUser()) {
            AsynchronousJob__c asyncObject = new AsynchronousJob__c(
                    Id = Mocker.fakeId(AsynchronousJob__c.SObjectType),
                    Status__c = Asynchronous.Status.RUNNING.name(),
                    OwnerId = UserInfo.getUserId(),
                    MaximumRetries__c = 1, // Makes TestRunnable.onFailure return false.
                    RetryInterval__c = 0,
                    RetryNumber__c = 1,
                    Runnable__c = TestRunnable.class.getName(),
                    ScheduledRunTime__c = Datetime.now()
            );

            Exception exc = new Asynchronous.APIException('Test');

            AsynchronousDAO.INSTANCE = (AsynchronousDAO) mockForFailure(asyncObject, Asynchronous.Status.FAILED, exc, true).mock();
            AsynchronousFinalizer.createFinalizer(asyncObject.Id).execute(new Context(exc));
            Mocker.validate();
        }
    }

    @IsTest
    private static void testExceptionInOnFailure() {
        System.runAs(AsynchronousTestHelper.getUser()) {
            AsynchronousJob__c asyncObject = new AsynchronousJob__c(
                    Id = Mocker.fakeId(AsynchronousJob__c.SObjectType),
                    Status__c = Asynchronous.Status.RUNNING.name(),
                    OwnerId = UserInfo.getUserId(),
                    MaximumRetries__c = 0,
                    RetryInterval__c = 1, // Makes TestRunnable.onFailure throw an Exception.
                    RetryNumber__c = 0,
                    Runnable__c = TestRunnable.class.getName(),
                    ScheduledRunTime__c = Datetime.now()
            );

            Exception exc = new Asynchronous.APIException('Test');

            AsynchronousDAO.INSTANCE = (AsynchronousDAO) mockForException(asyncObject, true, 'onFailure failed').mock();
            AsynchronousFinalizer.createFinalizer(asyncObject.Id).execute(new Context(exc));
            Mocker.validate();
        }
    }

    @IsTest
    private static void testRequeue() {
        System.runAs(AsynchronousTestHelper.getUser()) {
            AsynchronousJob__c asyncObject = new AsynchronousJob__c(
                    Id = Mocker.fakeId(AsynchronousJob__c.SObjectType),
                    Status__c = Asynchronous.Status.RUNNING.name(),
                    OwnerId = UserInfo.getUserId(),
                    MaximumRetries__c = 4,
                    RetryInterval__c = 0,
                    RetryNumber__c = 2,
                    Runnable__c = TestRunnable.class.getName(),
                    ScheduledRunTime__c = Datetime.now()
            );

            Exception exc = new Asynchronous.APIException('Test');

            AsynchronousDAO.INSTANCE = (AsynchronousDAO) mockForFailure(asyncObject, Asynchronous.Status.QUEUED, exc, false).mock();
            AsynchronousFinalizer.createFinalizer(asyncObject.Id).execute(new Context(exc));
            Mocker.validate();
        }
    }

    @IsTest
    private static void testSchedulerQueued() {
        System.runAs(AsynchronousTestHelper.getUser()) {
            AsynchronousJob__c asyncObject = new AsynchronousJob__c(
                    Id = Mocker.fakeId(AsynchronousJob__c.SObjectType),
                    Status__c = Asynchronous.Status.RUNNING.name(),
                    OwnerId = UserInfo.getUserId(),
                    MaximumRetries__c = 0,
                    RetryInterval__c = 0,
                    RetryNumber__c = 0,
                    Runnable__c = AsynchronousScheduler.QueueNext.class.getName(),
                    ScheduledRunTime__c = Datetime.now()
            );

            Mocker mocked = mockForSuccess(asyncObject, true);

            // Not happy about this test. For now as it it's so hard to pass state without creating the
            // AsynchronousJob__c object, the test for the Scheduler being queued is the failure to parse the JSON
            // from the job's state.
            mocked
                    .whenArgument(new AsynchronousJobException__c(
                            AsynchronousJob__c = asyncObject.Id,
                            ExceptionType__c = 'System.NullPointerException',
                            ExceptionMessage__c = 'null input to JSON parser'
                    ))
                        .expectMethod('apiPersistException').called(1)
                    .whenArgument(new List<AsynchronousJob__c>{
                            new AsynchronousJob__c(Id = asyncObject.Id, Status__c = Asynchronous.Status.FAILED.name())
                    })
                        .expectMethod('apiPersistObjects').called(1);

            AsynchronousDAO.INSTANCE = (AsynchronousDAO) mocked.mock();
            AsynchronousFinalizer.createFinalizer(asyncObject.Id).execute(new Context(null));
            Mocker.validate();
        }
    }

    @IsTest
    private static void testCancellationFromOnError() {
        System.runAs(AsynchronousTestHelper.getUser()) {
            AsynchronousJob__c asyncObject = new AsynchronousJob__c(
                    Id = Mocker.fakeId(AsynchronousJob__c.SObjectType),
                    Status__c = Asynchronous.Status.RUNNING.name(),
                    OwnerId = UserInfo.getUserId(),
                    MaximumRetries__c = 4,
                    RetryInterval__c = 2, // Makes Runnable.onError return CANCELLED.
                    RetryNumber__c = 2,
                    Runnable__c = TestRunnable.class.getName(),
                    ScheduledRunTime__c = Datetime.now()
            );

            Exception exc = new Asynchronous.APIException('Test');

            AsynchronousDAO.INSTANCE = (AsynchronousDAO) mockForFailure(asyncObject, Asynchronous.Status.CANCELLED, exc, false).mock();
            AsynchronousFinalizer.createFinalizer(asyncObject.Id).execute(new Context(exc));
            Mocker.validate();
        }
    }

    private static Mocker mockForSuccess(
            AsynchronousJob__c asyncObject,
            Boolean jobToBeDeleted
    ) {
        Mocker mocked = Mocker.of(AsynchronousDAO.class);
        mocked
                .whenArgument(asyncObject.Id)
                    .expectMethod('apiGetObject').called(1).returns(asyncObject);

        if (jobToBeDeleted) {
            mocked
                    // The Runnable's onFailure method will have asked for the job to be deleted.
                    .whenArgument(new List<AsynchronousJob__c>{ asyncObject })
                        .expectMethod('apiRemoveObjects').called(1);
        } else {
            mocked
                    // After a successful call to Runnable.onSuccess, the job should be marked as SUCCEEDED.
                    .whenArgument(new List<AsynchronousJob__c> { new AsynchronousJob__c(Id = asyncObject.Id, Status__c = Asynchronous.Status.SUCCEEDED.name()) })
                        .expectMethod('apiPersistObjects').called(1);
        }

        return mocked;
    }

    private static Mocker mockForFailure(
            AsynchronousJob__c asyncObject,
            Asynchronous.Status expectedStatus,
            Exception exc,
            Boolean jobToBeDeleted
    ) {
        Mocker mocked = Mocker.of(AsynchronousDAO.class);
        mocked
                // Finalizer must get the job once.
                .whenArgument(asyncObject.Id)
                    .expectMethod('apiGetObject').called(1).returns(asyncObject)

                // An Exception should be recorded.
                .whenArgument(new AsynchronousJobException__c(
                        AsynchronousJob__c = asyncObject.Id,
                        StatusOnError__c = asyncObject.Status__c,
                        RetryNumber__c = asyncObject.RetryNumber__c,
                        ExceptionType__c = exc.getTypeName(),
                        ExceptionMessage__c = exc.getMessage(),
                        ExceptionStackTrace__c = exc.getStackTraceString()
                ))
                    .expectMethod('apiPersistException').called(1);

        if (expectedStatus == Asynchronous.Status.QUEUED) {
            mocked
                    // The retries have not been exhausted so the job should be queued.
                    .whenArgument(new List<AsynchronousJob__c> {
                            new AsynchronousJob__c(Id = asyncObject.Id, Status__c = expectedStatus.name(), RetryNumber__c = asyncObject.RetryNumber__c+1)
                    })
                        .expectMethod('apiPersistObjects').called(1);

        } else if (jobToBeDeleted) {
            mocked
                    // The Runnable's onFailure method will have asked for the job to be deleted.
                    .whenArgument(new List<AsynchronousJob__c> {
                            new AsynchronousJob__c(Id = asyncObject.Id)
                    })
                        .expectMethod('apiRemoveObjects').called(1);
        } else {
            mocked
                    // After a successful call to Runnable.onFailed, the job should be marked as FAILED.
                    .whenArgument(new List<AsynchronousJob__c> {
                            new AsynchronousJob__c(Id = asyncObject.Id, Status__c = expectedStatus.name())
                    })
                        .expectMethod('apiPersistObjects').called(1);
        }

        return mocked;
    }

    private static Mocker mockForException(
            AsynchronousJob__c asyncObject,
            Boolean isJobFailed,
            String exceptionMessage
    ) {
        Mocker mocked = Mocker.of(AsynchronousDAO.class);

        mocked
                // Finalizer must get the job once.
                .whenArgument(asyncObject.Id)
                    .expectMethod('apiGetObject').called(1).returns(asyncObject)

                // And the error from the on method must be persisted.
                .whenArgument(new AsynchronousJobException__c(
                        AsynchronousJob__c = asyncObject.Id,
                        RetryNumber__c = asyncObject.RetryNumber__c,
                        StatusOnError__c = asyncObject.Status__c,
                        ExceptionType__c = Asynchronous.APIException.class.getName(),
                        ExceptionMessage__c = exceptionMessage
                ))
                    .expectMethod('apiPersistException').called(1)

                // The job status will be changed to FAILED.
                .whenArgument(new List<AsynchronousJob__c> { new AsynchronousJob__c(Id = asyncObject.Id, Status__c = Asynchronous.Status.FAILED.name()) } )
                    .expectMethod('apiPersistObjects').called(1);

        if (isJobFailed) {
            mocked
                    // The Exception that caused onFailure to be called must be recorded.
                    .whenArgument(new AsynchronousJobException__c(
                            AsynchronousJob__c = asyncObject.Id,
                            RetryNumber__c = asyncObject.RetryNumber__c,
                            StatusOnError__c = asyncObject.Status__c,
                            ExceptionType__c = Asynchronous.APIException.class.getName(),
                            ExceptionMessage__c = 'Test'
                    ))
                        .expectMethod('apiPersistException').called(1);
        }

        return mocked;
    }

    public with sharing class TestRunnable extends AsynchronousRunnable {

        public TestRunnable() {
            super(TestRunnable.class);
        }

        public override Integer getMaximumActive() {
            return 1;
        }

        public override Boolean onSuccess(Asynchronous.Job job) {
            return process(job, 'onSuccess');
        }

        public override Boolean onFailure(Asynchronous.Job job, Exception exc) {
            return process(job, 'onFailure');
        }

        public override Asynchronous.Status onError(Asynchronous.Job job, Exception exc) {
            return job.getRetryInterval() == 2 ? Asynchronous.Status.CANCELLED : Asynchronous.Status.QUEUED;
        }

        public override Boolean onCancellation(Asynchronous.Job job) {
            return process(job, 'onCancellation');
        }

        private Boolean process(Asynchronous.Job job, String method) {
            if (job.getRetryInterval() == 1) {
                throw new Asynchronous.APIException(method + ' failed');
            }

            return job.getMaximumRetries() == 0;
        }
    }

    private with sharing class Context implements FinalizerContext {
        final Exception exc;

        public Context(Exception exc) {
            this.exc = exc;
        }
        public Exception getException() {
            return exc;
        }

        public ParentJobResult getResult() {
            return exc == null ? ParentJobResult.SUCCESS : ParentJobResult.UNHANDLED_EXCEPTION;
        }

        public Id getAsyncApexJobId() {
            return null;
        }

        public String getRequestId() {
            return null;
        }
    }
}