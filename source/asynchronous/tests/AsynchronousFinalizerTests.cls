/**
 * @description
 * Unit tests for Asynchronous Finalizer.
 *
 * @author Mark Brennand
 */
@IsTest
public with sharing class AsynchronousFinalizerTests {

    @IsTest
    private static void testSuccess() {

        // The first test is for when there are more jobs to run.
        // The AsynchronousJob__c object should be kept.
        AsynchronousJob__c asyncObject = new AsynchronousJob__c(Id = TestHelper.nextId(AsynchronousJob__c.SObjectType));
        asyncObject.Status__c = Asynchronous.Status.RUNNING.name();
        asyncObject.OwnerId = UserInfo.getUserId();
        asyncObject.MaximumRetries__c = 0;
        asyncObject.RetryInterval__c = 0;
        asyncObject.RetryNumber__c = 0;
        asyncObject.Runnable__c = TestRunnable.class.getName();
        asyncObject.ScheduledRunTime__c = Datetime.now();

        AsynchronousDAO.INSTANCE = mockForSuccess(asyncObject, true, false);
        AsynchronousFinalizer.createFinalizer(asyncObject.Id).execute(new Context(null));
        Mocker.validate();

        // The second test is for when there are no more jobs to run.
        // The AsynchronousJob__c object should be kept.
        asyncObject = new AsynchronousJob__c(Id = TestHelper.nextId(AsynchronousJob__c.SObjectType));
        asyncObject.Status__c = Asynchronous.Status.RUNNING.name();
        asyncObject.OwnerId = UserInfo.getUserId();
        asyncObject.MaximumRetries__c = 0;
        asyncObject.RetryInterval__c = 0;
        asyncObject.RetryNumber__c = 0;
        asyncObject.Runnable__c = TestRunnable.class.getName();
        asyncObject.ScheduledRunTime__c = Datetime.now();

        AsynchronousDAO.INSTANCE = mockForSuccess(asyncObject, false, false);
        AsynchronousFinalizer.createFinalizer(asyncObject.Id).execute(new Context(null));
        Mocker.validate();

        // The third test is for when there are no more jobs to run.
        // The AsynchronousJob__c object should be kept.
        asyncObject = new AsynchronousJob__c(Id = TestHelper.nextId(AsynchronousJob__c.SObjectType));
        asyncObject.Status__c = Asynchronous.Status.RUNNING.name();
        asyncObject.OwnerId = UserInfo.getUserId();
        asyncObject.MaximumRetries__c = 1;
        asyncObject.RetryInterval__c = 0;
        asyncObject.RetryNumber__c = 1; // Causes Runnable to ask for job to be deleted.
        asyncObject.Runnable__c = TestRunnable.class.getName();
        asyncObject.ScheduledRunTime__c = Datetime.now();

        AsynchronousDAO.INSTANCE = mockForSuccess(asyncObject, false, true);
        AsynchronousFinalizer.createFinalizer(asyncObject.Id).execute(new Context(null));
        Mocker.validate();
    }

    @IsTest
    private static void testFailure() {

        // The first test is for when there are more jobs to run.
        // The AsynchronousJob__c object should be kept.
        AsynchronousJob__c asyncObject = new AsynchronousJob__c(Id = TestHelper.nextId(AsynchronousJob__c.SObjectType));
        asyncObject.Status__c = Asynchronous.Status.RUNNING.name();
        asyncObject.OwnerId = UserInfo.getUserId();
        asyncObject.MaximumRetries__c = 0;
        asyncObject.RetryInterval__c = 0;
        asyncObject.RetryNumber__c = 0;
        asyncObject.Runnable__c = TestRunnable.class.getName();
        asyncObject.ScheduledRunTime__c = Datetime.now();

        // And the Exception.
        Exception exc = new Asynchronous.APIException('Test');

        // Add the mocking.
        AsynchronousDAO mockDAO = mockForFailure(asyncObject, Asynchronous.Status.FAILED, exc, false, true);
        AsynchronousDAO.INSTANCE = mockDao;

        // Perform the test.
        AsynchronousFinalizer.createFinalizer(asyncObject.Id).execute(new Context(exc));

        // Confirm the mocked methods were called correctly.
        Mocker.validate();

        // The second test is for when there are no more jobs to run.
        // The AsynchronousJob__c object should be kept.
        asyncObject = new AsynchronousJob__c(Id = TestHelper.nextId(AsynchronousJob__c.SObjectType));
        asyncObject.Status__c = Asynchronous.Status.RUNNING.name();
        asyncObject.OwnerId = UserInfo.getUserId();
        asyncObject.MaximumRetries__c = 0;
        asyncObject.RetryInterval__c = 0;
        asyncObject.RetryNumber__c = 0;
        asyncObject.Runnable__c = TestRunnable.class.getName();
        asyncObject.ScheduledRunTime__c = Datetime.now();

        // And the Exception.
        exc = new Asynchronous.APIException('Test');

        // Add the mocking.
        mockDAO = mockForFailure(asyncObject, Asynchronous.Status.FAILED, exc, false, false);
        AsynchronousDAO.INSTANCE = mockDao;

        // Perform the test.
        AsynchronousFinalizer.createFinalizer(asyncObject.Id).execute(new Context(exc));

        // Confirm the mocked methods were called correctly.
        Mocker.validate();

        // The third test is for when there are no more jobs to run.
        // The AsynchronousJob__c object should not be kept.
        asyncObject = new AsynchronousJob__c(Id = TestHelper.nextId(AsynchronousJob__c.SObjectType));
        asyncObject.Status__c = Asynchronous.Status.RUNNING.name();
        asyncObject.OwnerId = UserInfo.getUserId();
        asyncObject.MaximumRetries__c = 1;
        asyncObject.RetryInterval__c = 0;
        asyncObject.RetryNumber__c = 1; // Causes Runnable to ask for job to be deleted.
        asyncObject.Runnable__c = TestRunnable.class.getName();
        asyncObject.ScheduledRunTime__c = Datetime.now();

        // And the Exception.
        exc = new Asynchronous.APIException('Test');

        // Add the mocking.
        AsynchronousDAO.INSTANCE = mockForFailure(asyncObject, Asynchronous.Status.FAILED, exc, true, false);

        // Perform the test.
        AsynchronousFinalizer.createFinalizer(asyncObject.Id).execute(new Context(exc));

        // Confirm the mocked methods were called correctly.
        Mocker.validate();
    }

    @IsTest
    private static void testRequeue() {

        // The test is for when there are more jobs to run.
        AsynchronousJob__c asyncObject = new AsynchronousJob__c(Id = TestHelper.nextId(AsynchronousJob__c.SObjectType));
        asyncObject.Status__c = Asynchronous.Status.RUNNING.name();
        asyncObject.OwnerId = UserInfo.getUserId();
        asyncObject.MaximumRetries__c = 4;
        asyncObject.RetryInterval__c = 0;
        asyncObject.RetryNumber__c = 2;
        asyncObject.Runnable__c = TestRunnable.class.getName();
        asyncObject.ScheduledRunTime__c = Datetime.now();

        // And the Exception.
        Exception exc = new Asynchronous.APIException('Test');

        // Add the mocking.
        AsynchronousDAO.INSTANCE = mockForFailure(asyncObject, Asynchronous.Status.QUEUED, exc, false, true);

        // Perform the test.
        AsynchronousFinalizer.createFinalizer(asyncObject.Id).execute(new Context(exc));

        // Confirm the mocked methods were called correctly.
        Mocker.validate();
    }

    @IsTest
    private static void testCancellationFromOnError() {

        // The test is for when there are more jobs to run.
        AsynchronousJob__c asyncObject = new AsynchronousJob__c(Id = TestHelper.nextId(AsynchronousJob__c.SObjectType));
        asyncObject.Status__c = Asynchronous.Status.RUNNING.name();
        asyncObject.OwnerId = UserInfo.getUserId();
        asyncObject.MaximumRetries__c = 4;
        asyncObject.RetryInterval__c = 2;   // Causes Runnable.onError to return CANCELLED.
        asyncObject.RetryNumber__c = 2;
        asyncObject.Runnable__c = TestRunnable.class.getName();
        asyncObject.ScheduledRunTime__c = Datetime.now();

        // And the Exception.
        Exception exc = new Asynchronous.APIException('Test');

        // Add the mocking.
        AsynchronousDAO.INSTANCE = mockForFailure(asyncObject, Asynchronous.Status.CANCELLED, exc, false, true);

        // Perform the test.
        AsynchronousFinalizer.createFinalizer(asyncObject.Id).execute(new Context(exc));

        // Confirm the mocked methods were called correctly.
        Mocker.validate();
    }

    @IsTest
    private static void testExceptionInOnSuccess() {

        // The test is for an exception thrown from onSuccess.
        AsynchronousJob__c asyncObject = new AsynchronousJob__c(Id = TestHelper.nextId(AsynchronousJob__c.SObjectType));
        asyncObject.Status__c = Asynchronous.Status.RUNNING.name();
        asyncObject.OwnerId = UserInfo.getUserId();
        asyncObject.MaximumRetries__c = 4;
        asyncObject.RetryInterval__c = 1;   // Causes the Runnable to throw an Exception.
        asyncObject.RetryNumber__c = 2;
        asyncObject.Runnable__c = TestRunnable.class.getName();
        asyncObject.ScheduledRunTime__c = Datetime.now();

        // Setup the mocking.
        Mocker mocked = Mocker.of(AsynchronousDAO.class);

        mocked
                // Finalizer must get the job once.
                .whenArgument(asyncObject.Id)
                    .expectMethod('apiGetObject').called(1).returns(asyncObject)

                // And the error must be persisted.
                .whenArgument(new AsynchronousJobException__c(
                        AsynchronousJob__c = asyncObject.Id,
                        RetryNumber__c = asyncObject.RetryNumber__c,
                        StatusOnError__c = asyncObject.Status__c,
                        ExceptionType__c = Asynchronous.APIException.class.getName(),
                        ExceptionMessage__c = 'onSuccess failed'
                ))
                    .expectMethod('apiPersistException').called(1)

                // The job status will be changed to FAILED.
                .whenArgument(new List<AsynchronousJob__c> { new AsynchronousJob__c(Id = asyncObject.Id, Status__c = Asynchronous.Status.FAILED.name()) } )
                    .expectMethod('apiPersistObjects').called(1)

                // The Finalizer should then check if there are any jobs left to run. In this case, return 0 as
                // to make it think there are no more jobs to run.
                .whenArgument(false)
                    .expectMethod('apiCountScheduledObjects').called(1).returns(0);

        AsynchronousDAO.INSTANCE = (AsynchronousDAO) mocked.getMockedObject();

        // Perform the test.
        AsynchronousFinalizer.createFinalizer(asyncObject.Id).execute(new Context(null));

        // Confirm the mocked methods were called correctly.
        Mocker.validate();
    }

    @IsTest
    private static void testExceptionInOnFailure() {

        // The test is for when an Exception is thrown from onFailure.
        AsynchronousJob__c asyncObject = new AsynchronousJob__c(Id = TestHelper.nextId(AsynchronousJob__c.SObjectType));
        asyncObject.Status__c = Asynchronous.Status.RUNNING.name();
        asyncObject.OwnerId = UserInfo.getUserId();
        asyncObject.MaximumRetries__c = 2;
        asyncObject.RetryInterval__c = 1;   // Causes the Runnable to throw an Exception.
        asyncObject.RetryNumber__c = 2;
        asyncObject.Runnable__c = TestRunnable.class.getName();
        asyncObject.ScheduledRunTime__c = Datetime.now();

        // And the job fails with the Exception.
        Asynchronous.APIException exc = new Asynchronous.APIException('Test');

        // Setup the mocking.
        Mocker mocked = Mocker.of(AsynchronousDAO.class);

        mocked
                // Finalizer must get the job once.
                .whenArgument(asyncObject.Id)
                    .expectMethod('apiGetObject').called(1).returns(asyncObject)

                // And the error must be persisted.
                .whenArgument(new AsynchronousJobException__c(
                        AsynchronousJob__c = asyncObject.Id,
                        RetryNumber__c = asyncObject.RetryNumber__c,
                        StatusOnError__c = asyncObject.Status__c,
                        ExceptionType__c = exc.getTypeName(),
                        ExceptionMessage__c = exc.getMessage(),
                        ExceptionStackTrace__c = exc.getStackTraceString()
                ))
                    .expectMethod('apiPersistException').called(1)

                // The error from the onFailure method must be persisted.
                .whenArgument(new AsynchronousJobException__c(
                        AsynchronousJob__c = asyncObject.Id,
                        ExceptionType__c = Asynchronous.APIException.class.getName(),
                        RetryNumber__c = asyncObject.RetryNumber__c,
                        StatusOnError__c = asyncObject.Status__c,
                        ExceptionMessage__c = 'onFailure failed'
                ))
                    .expectMethod('apiPersistException').called(1)

                // The job status will be changed to FAILED.
                .whenArgument(new List<AsynchronousJob__c> { new AsynchronousJob__c(Id = asyncObject.Id, Status__c = Asynchronous.Status.FAILED.name()) } )
                    .expectMethod('apiPersistObjects').called(1)

                // The Finalizer should then check if there are any jobs left to run. In this case, return 0 as
                // to make it think there are no more jobs to run.
                .whenArgument(false)
                    .expectMethod('apiCountScheduledObjects').called(1).returns(0);

        AsynchronousDAO.INSTANCE = (AsynchronousDAO) mocked.getMockedObject();

        // Perform the test.
        AsynchronousFinalizer.createFinalizer(asyncObject.Id).execute(new Context(exc));

        // Confirm the mocked methods were called correctly.
        Mocker.validate();
    }

    @IsTest
    private static void testExceptionInCountScheduledObjects() {

        // The test is for when an Exception is thrown from AsynchronousDAO.countScheduledObjects.
        AsynchronousJob__c asyncObject = new AsynchronousJob__c(Id = TestHelper.nextId(AsynchronousJob__c.SObjectType));
        asyncObject.Status__c = Asynchronous.Status.RUNNING.name();
        asyncObject.OwnerId = UserInfo.getUserId();
        asyncObject.MaximumRetries__c = 0;
        asyncObject.RetryInterval__c = 0;
        asyncObject.RetryNumber__c = 0;
        asyncObject.Runnable__c = TestRunnable.class.getName();
        asyncObject.ScheduledRunTime__c = Datetime.now();

        // Setup the mocking.
        Mocker mocked = Mocker.of(AsynchronousDAO.class);

        mocked
                // Finalizer must get the job once.
                .whenArgument(asyncObject.Id)
                    .expectMethod('apiGetObject').called(1).returns(asyncObject)

                // The status must be set to SUCCEEDED initially..
                .whenArgument(new List<AsynchronousJob__c> {
                        new AsynchronousJob__c(Id = asyncObject.Id, Status__c = Asynchronous.Status.SUCCEEDED.name())
                })
                    .expectMethod('apiPersistObjects').called(1)

                // And when the count exception occurs set to FAILED.
                .whenArgument(new List<AsynchronousJob__c> {
                        new AsynchronousJob__c(Id = asyncObject.Id, Status__c = Asynchronous.Status.FAILED.name())
                })
                .expectMethod('apiPersistObjects').called(1)

                // Force an Exception when counting the number of scheduled jobs.
                .whenArgument(false)
                    .expectMethod('apiCountScheduledObjects').called(1).throws(new Asynchronous.APIException('Test'))

                // The Exception should be persisted.
                .whenArgument(new AsynchronousJobException__c(
                    AsynchronousJob__c = asyncObject.Id,
                    ExceptionType__c = Asynchronous.APIException.class.getName(),
                    ExceptionMessage__c = 'Test'
                ))
                    .expectMethod('apiPersistException').called(1);

        AsynchronousDAO.INSTANCE = (AsynchronousDAO) mocked.getMockedObject();

        // Perform the test.
        AsynchronousFinalizer.createFinalizer(asyncObject.Id).execute(new Context(null));

        // Confirm the mocked methods were called correctly.
        Mocker.validate();
    }

    private static AsynchronousDAO mockForSuccess(
            AsynchronousJob__c asyncObject,
            Boolean withMoreJobs,
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

        if (withMoreJobs) {
            mocked
                    // The Finalizer should then check if there are any jobs left to run. In this case, return 2 as
                    // the AsyncScheduler.getMaximumActive method will also call the same DAO method.
                    .whenArgument(false)
                        .expectMethod('apiCountScheduledObjects').called(2).returns(1)

                    // The AsynchronousScheduler.getMaximumActive method will call the DAO method once.
                    .whenArgument(true)
                        .expectMethod('apiCountScheduledObjects').called(1).returns(1);

            mocked
                    // The call to this method will make the Asynchronous Scheduler think it has jobs to run.
                    .whenArgument(new AsynchronousJob__c(Runnable__c = AsynchronousScheduler.QueueNext.class.getName(), Status__c = Asynchronous.Status.PENDING.name()))
                        .expectMethod('apiCountActiveObjects').called(1).returns(1);
        } else {
            mocked
                    // The Finalizer should then check if there are any jobs left to run. In this case, return 0 as
                    // to make it think there are no more jobs to run.
                    .whenArgument(false)
                        .expectMethod('apiCountScheduledObjects').called(1).returns(0);
        }

        return (AsynchronousDAO) mocked.getMockedObject();
    }

    private static AsynchronousDAO mockForFailure(
            AsynchronousJob__c asyncObject,
            Asynchronous.Status expectedStatus,
            Exception exc,
            Boolean jobToBeDeleted,
            Boolean moreJobsToRun
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

        if (moreJobsToRun) {
            mocked
                    // The Finalizer should then check if there are any jobs left to run. In this case, return 2 as
                    // the AsyncScheduler.getMaximumActive method will also call the same DAO method.
                    .whenArgument(false)
                    .expectMethod('apiCountScheduledObjects').called(2).returns(1)

                    // The AsynchronousScheduler.getMaximumActive method will call the DAO method once.
                    .whenArgument(true)
                    .expectMethod('apiCountScheduledObjects').called(1).returns(1);

            mocked
                    // The call to this method will make the Asynchronous Scheduler think it has jobs to run.
                    .whenArgument(new AsynchronousJob__c(Runnable__c = AsynchronousScheduler.QueueNext.class.getName(), Status__c = Asynchronous.Status.PENDING.name()))
                    .expectMethod('apiCountActiveObjects').called(1).returns(1);
        } else {
            mocked
                    // The Finalizer should then check if there are any jobs left to run. In this case, return 0 as
                    // to make it think there are no more jobs to run.
                    .whenArgument(false)
                    .expectMethod('apiCountScheduledObjects').called(1).returns(0);
        }

        return (AsynchronousDAO) mocked.getMockedObject();
    }

    public with sharing class TestRunnable extends AsynchronousRunnable {

        public TestRunnable() {
            super(TestRunnable.class);
        }

        public override Integer getMaximumActive() {
            return 1;
        }

        public override Boolean onSuccess(Asynchronous.Job job) {
            if (job.getRetryInterval() == 1) {
                throw new Asynchronous.APIException('onSuccess failed');
            }

            return job.getMaximumRetries() == 0;
        }

        public override Boolean onFailure(Asynchronous.Job job, Exception exc) {
            if (job.getRetryInterval() == 1) {
                throw new Asynchronous.APIException('onFailure failed');
            }

            return job.getMaximumRetries() == 0;
        }

        public override Asynchronous.Status onError(Asynchronous.Job job, Exception exc) {
            return job.getRetryInterval() == 2 ? Asynchronous.Status.CANCELLED : Asynchronous.Status.QUEUED;
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