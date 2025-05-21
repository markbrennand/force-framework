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
        // The Asynchronous__c object should be kept.
        Asynchronous__c asyncObject = new Asynchronous__c(Id = TestHelper.nextId(Asynchronous__c.SObjectType));
        asyncObject.Status__c = Asynchronous.Status.RUNNING.name();
        asyncObject.OwnerId = UserInfo.getUserId();
        asyncObject.MaximumRetries__c = 0;
        asyncObject.RetryInterval__c = 0;
        asyncObject.RetryNumber__c = 0;
        asyncObject.Runnable__c = TestRunnable.class.getName();
        asyncObject.ScheduledRunTime__c = Datetime.now();

        AsynchronousDAO mockDAO = mockForSuccess(asyncObject, true, false);
        AsynchronousDAO.INSTANCE = mockDao;

        AsynchronousFinalizer.createFinalizer(asyncObject.Id).execute(new Context(null));

        Mock.validate(mockDAO);

        // The second test is for when there are no more jobs to run.
        // The Asynchronous__c object should be kept.
        asyncObject = new Asynchronous__c(Id = TestHelper.nextId(Asynchronous__c.SObjectType));
        asyncObject.Status__c = Asynchronous.Status.RUNNING.name();
        asyncObject.OwnerId = UserInfo.getUserId();
        asyncObject.MaximumRetries__c = 0;
        asyncObject.RetryInterval__c = 0;
        asyncObject.RetryNumber__c = 0;
        asyncObject.Runnable__c = TestRunnable.class.getName();
        asyncObject.ScheduledRunTime__c = Datetime.now();

        mockDAO = mockForSuccess(asyncObject, false, false);
        AsynchronousDAO.INSTANCE = mockDao;

        AsynchronousFinalizer.createFinalizer(asyncObject.Id).execute(new Context(null));

        Mock.validate(mockDAO);

        // The third test is for when there are no more jobs to run.
        // The Asynchronous__c object should be kept.
        asyncObject = new Asynchronous__c(Id = TestHelper.nextId(Asynchronous__c.SObjectType));
        asyncObject.Status__c = Asynchronous.Status.RUNNING.name();
        asyncObject.OwnerId = UserInfo.getUserId();
        asyncObject.MaximumRetries__c = 1;
        asyncObject.RetryInterval__c = 0;
        asyncObject.RetryNumber__c = 1; // Causes Runnable to ask for job to be deleted.
        asyncObject.Runnable__c = TestRunnable.class.getName();
        asyncObject.ScheduledRunTime__c = Datetime.now();

        mockDAO = mockForSuccess(asyncObject, false, true);
        AsynchronousDAO.INSTANCE = mockDao;

        AsynchronousFinalizer.createFinalizer(asyncObject.Id).execute(new Context(null));

        Mock.validate(mockDAO);
    }

    @IsTest
    private static void testFailure() {

        // The first test is for when there are more jobs to run.
        // The Asynchronous__c object should be kept.
        Asynchronous__c asyncObject = new Asynchronous__c(Id = TestHelper.nextId(Asynchronous__c.SObjectType));
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
        Mock.validate(mockDAO);

        // The second test is for when there are no more jobs to run.
        // The Asynchronous__c object should be kept.
        asyncObject = new Asynchronous__c(Id = TestHelper.nextId(Asynchronous__c.SObjectType));
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
        Mock.validate(mockDAO);

        // The third test is for when there are no more jobs to run.
        // The Asynchronous__c object should not be kept.
        asyncObject = new Asynchronous__c(Id = TestHelper.nextId(Asynchronous__c.SObjectType));
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
        mockDAO = mockForFailure(asyncObject, Asynchronous.Status.FAILED, exc, true, false);
        AsynchronousDAO.INSTANCE = mockDao;

        // Perform the test.
        AsynchronousFinalizer.createFinalizer(asyncObject.Id).execute(new Context(exc));

        // Confirm the mocked methods were called correctly.
        Mock.validate(mockDAO);
    }

    @IsTest
    private static void testRequeue() {

        // The test is for when there are more jobs to run.
        Asynchronous__c asyncObject = new Asynchronous__c(Id = TestHelper.nextId(Asynchronous__c.SObjectType));
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
        AsynchronousDAO mockDAO = mockForFailure(asyncObject, Asynchronous.Status.QUEUED, exc, false, true);
        AsynchronousDAO.INSTANCE = mockDao;

        // Perform the test.
        AsynchronousFinalizer.createFinalizer(asyncObject.Id).execute(new Context(exc));

        // Confirm the mocked methods were called correctly.
        Mock.validate(mockDAO);
    }

    @IsTest
    private static void testCancellationFromOnError() {

        // The test is for when there are more jobs to run.
        Asynchronous__c asyncObject = new Asynchronous__c(Id = TestHelper.nextId(Asynchronous__c.SObjectType));
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
        AsynchronousDAO mockDAO = mockForFailure(asyncObject, Asynchronous.Status.CANCELLED, exc, false, true);
        AsynchronousDAO.INSTANCE = mockDao;

        // Perform the test.
        AsynchronousFinalizer.createFinalizer(asyncObject.Id).execute(new Context(exc));

        // Confirm the mocked methods were called correctly.
        Mock.validate(mockDAO);
    }

    @IsTest
    private static void testExceptionInOnSuccess() {

        // The test is for an exception thrown from onSuccess.
        Asynchronous__c asyncObject = new Asynchronous__c(Id = TestHelper.nextId(Asynchronous__c.SObjectType));
        asyncObject.Status__c = Asynchronous.Status.RUNNING.name();
        asyncObject.OwnerId = UserInfo.getUserId();
        asyncObject.MaximumRetries__c = 4;
        asyncObject.RetryInterval__c = 1;   // Causes the Runnable to throw an Exception.
        asyncObject.RetryNumber__c = 2;
        asyncObject.Runnable__c = TestRunnable.class.getName();
        asyncObject.ScheduledRunTime__c = Datetime.now();

        // Setup the mocking.
        AsynchronousDAO mockDAO = (AsynchronousDAO) Mock.stub(AsynchronousDAO.class);
        AsynchronousDAO.INSTANCE = mockDAO;

        // Finalizer must get the job once.
        Mock.stubMethod(mockDAO, 'apiGetObject')
                .withArguments(new List<Object> { asyncObject.Id })
                .expected(1)
                .returns(asyncObject);

        // And the error must be persisted.
        Mock.stubMethod(mockDAO, 'apiPersistException')
                .withArguments(new List<Object> {
                        new AsynchronousException__c(
                                Asynchronous__c = asyncObject.Id,
                                ExceptionType__c = Asynchronous.APIException.class.getName(),
                                RetryNumber__c = asyncObject.RetryNumber__c,
                                StatusOnError__c = asyncObject.Status__c,
                                ExceptionMessage__c = 'onSuccess failed'
                        )
                })
                .expected(1);

        // The job status will be changed to FAILED.
        Asynchronous__c persistedObject = AsyncObject.clone(true);
        persistedObject.Status__c = Asynchronous.Status.FAILED.name();

        Mock.stubMethod(mockDAO, 'apiPersistObjects')
                .withArguments(new List<Object> { new List<Asynchronous__c> { persistedObject } })
                .expected(1);

        // The Finalizer should then check if there are any jobs left to run. In this case, return 0 as
        // to make it think there are no more jobs to run.
        Mock.stubMethod(mockDAO, 'apiCountScheduledObjects')
                .withArguments(new List<Object>{ false })
                .expected(1)
                .returns(0);

        // Perform the test.
        AsynchronousFinalizer.createFinalizer(asyncObject.Id).execute(new Context(null));

        // Confirm the mocked methods were called correctly.
        Mock.validate(mockDAO);
    }

    @IsTest
    private static void testExceptionInOnFailure() {

        // The test is for when an Exception is thrown from onFailure.
        Asynchronous__c asyncObject = new Asynchronous__c(Id = TestHelper.nextId(Asynchronous__c.SObjectType));
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
        AsynchronousDAO mockDAO = (AsynchronousDAO) Mock.stub(AsynchronousDAO.class);
        AsynchronousDAO.INSTANCE = mockDAO;

        // Finalizer must get the job once.
        Mock.stubMethod(mockDAO, 'apiGetObject')
                .withArguments(new List<Object> { asyncObject.Id })
                .expected(1)
                .returns(asyncObject);

        // The error from the job must be persisted.
        Mock.stubMethod(mockDAO, 'apiPersistException')
                .withArguments(new List<Object> {
                        new AsynchronousException__c(
                                Asynchronous__c = asyncObject.Id,
                                ExceptionType__c = exc.getTypeName(),
                                RetryNumber__c = asyncObject.RetryNumber__c,
                                StatusOnError__c = asyncObject.Status__c,
                                ExceptionMessage__c = exc.getMessage(),
                                ExceptionStackTrace__c = exc.getStackTraceString()
                        )
                })
                .expected(1);

        // The error from the onFailure method must be persisted.
        Mock.stubMethod(mockDAO, 'apiPersistException')
                .withArguments(new List<Object> {
                        new AsynchronousException__c(
                                Asynchronous__c = asyncObject.Id,
                                ExceptionType__c = Asynchronous.APIException.class.getName(),
                                RetryNumber__c = asyncObject.RetryNumber__c,
                                StatusOnError__c = asyncObject.Status__c,
                                ExceptionMessage__c = 'onFailure failed'
                        )
                })
                .expected(1);

        // The job status will be changed to FAILED.
        Asynchronous__c persistedObject = AsyncObject.clone(true);
        persistedObject.Status__c = Asynchronous.Status.FAILED.name();

        Mock.stubMethod(mockDAO, 'apiPersistObjects')
                .withArguments(new List<Object> { new List<Asynchronous__c> { persistedObject } })
                .expected(1);

        // The Finalizer should then check if there are any jobs left to run. In this case, return 0 as
        // to make it think there are no more jobs to run.
        Mock.stubMethod(mockDAO, 'apiCountScheduledObjects')
                .withArguments(new List<Object>{ false })
                .expected(1)
                .returns(0);

        // Perform the test.
        AsynchronousFinalizer.createFinalizer(asyncObject.Id).execute(new Context(exc));

        // Confirm the mocked methods were called correctly.
        Mock.validate(mockDAO);
    }

    @IsTest
    private static void testExceptionInCountScheduledObjects() {

        // The test is for when an Exception is thrown from AsynchronousDAO.countScheduledObjects.
        Asynchronous__c asyncObject = new Asynchronous__c(Id = TestHelper.nextId(Asynchronous__c.SObjectType));
        asyncObject.Status__c = Asynchronous.Status.RUNNING.name();
        asyncObject.OwnerId = UserInfo.getUserId();
        asyncObject.MaximumRetries__c = 0;
        asyncObject.RetryInterval__c = 0;
        asyncObject.RetryNumber__c = 0;
        asyncObject.Runnable__c = TestRunnable.class.getName();
        asyncObject.ScheduledRunTime__c = Datetime.now();

        // Setup the mocking.
        AsynchronousDAO mockDAO = (AsynchronousDAO) Mock.stub(AsynchronousDAO.class);
        AsynchronousDAO.INSTANCE = mockDAO;

        // Finalizer must get the job once.
        Mock.stubMethod(mockDAO, 'apiGetObject')
                .withArguments(new List<Object> { asyncObject.Id })
                .expected(1)
                .returns(asyncObject);

        // The status must be set to SUCCEEDED initially..
        Asynchronous__c succeededAsyncObject = asyncObject.clone(true);
        succeededAsyncObject.Status__c = Asynchronous.Status.SUCCEEDED.name();

        Mock.stubMethod(mockDAO, 'apiPersistObjects')
                .withArguments(new List<Object> { new List <Asynchronous__c> { succeededAsyncObject } })
                .expected(1);

        // And when the count exception occurs set to FAILED.
        Asynchronous__c failureAsyncObject = asyncObject.clone(true);
        failureAsyncObject.Status__c = Asynchronous.Status.FAILED.name();

        Mock.stubMethod(mockDAO, 'apiPersistObjects')
                .withArguments(new List<Object> { new List <Asynchronous__c> { failureAsyncObject } })
                .expected(1);

        // Force an Exception when counting the number of scheduled jobs.
        Mock.stubMethod(mockDAO, 'apiCountScheduledObjects')
                .withArguments(new List<Object> { false })
                .throws(new Asynchronous.APIException('Test'));

        // The Exception should be persisted.
        Mock.stubMethod(mockDAO, 'apiPersistException')
                .withArguments(new List<Object> {
                        new AsynchronousException__c(
                                Asynchronous__c = asyncObject.Id,
                                ExceptionType__c = Asynchronous.APIException.class.getName(),
                                ExceptionMessage__c = 'Test'
                        )
                });

        // Perform the test.
        AsynchronousFinalizer.createFinalizer(asyncObject.Id).execute(new Context(null));

        // Confirm the mocked methods were called correctly.
        Mock.validate(mockDAO);
    }

    private static AsynchronousDAO mockForSuccess(
            Asynchronous__c asyncObject,
            Boolean withMoreJobs,
            Boolean jobToBeDeleted
    ) {
        AsynchronousDAO mockDAO = (AsynchronousDAO) Mock.stub(AsynchronousDAO.class);

        // Finalizer must get the job once.
        Mock.stubMethod(mockDAO, 'apiGetObject')
                .withArguments(new List<Object> { asyncObject.Id })
                .expected(1)
                .returns(asyncObject);

        if (jobToBeDeleted) {
            // The Runnable's onFailure method will have asked for the job to be deleted.
            Mock.stubMethod(mockDAO, 'apiRemoveObjects')
                    .withArguments(new List<Object>{new List<Asynchronous__c>{ asyncObject } })
                    .expected(1);
        } else {
            // After a successful call to Runnable.onSuccess, the job should be marked as SUCCEEDED.
            Asynchronous__c persistedAsyncObject = asyncObject.clone(true);
            persistedAsyncObject.Status__c = Asynchronous.Status.SUCCEEDED.name();

            Mock.stubMethod(mockDAO, 'apiPersistObjects')
                    .withArguments(new List<Object> { new List<Asynchronous__c> { persistedAsyncObject } })
                    .expected(1);
        }

        if (withMoreJobs) {
            // The Finalizer should then check if there are any jobs left to run. In this case, return 2 as
            // the AsyncScheduler.getMaximumActive method will also call the same DAO method.
            Mock.stubMethod(mockDAO, 'apiCountScheduledObjects')
                    .withArguments(new List<Object>{ false })
                    .expected(2)
                    .returns(1);

            // The AsynchronousScheduler.getMaximumActive method will call the DAO method once.
            Mock.stubMethod(mockDAO, 'apiCountScheduledObjects')
                    .withArguments(new List<Object>{ true })
                    .expected(1)
                    .returns(1);

            // The Finalizer will then try to start the scheduler.
            Asynchronous__c schedulerAsyncObject = new Asynchronous__c(
                    Id = null,
                    OwnerId = UserInfo.getUserId(),
                    Status__c = Asynchronous.Status.PENDING.name(),
                    Reference__c = null,
                    Runnable__c = AsynchronousScheduler.Executor.class.getName(),
                    MaximumRetries__c = 0,
                    RetryInterval__c = 0,
                    RetryNumber__c = 0
            );

            // The call to this method will make the Asynchronous Scheduler think it has jobs to run.
            Mock.stubMethod(mockDAO, 'apiCountActiveObjects')
                    .withArguments(new List<Object>{ schedulerAsyncObject })
                    .expected(1)
                    .returns(1);

        } else {
            // The Finalizer should then check if there are any jobs left to run. In this case, return 0 as
            // to make it think there are no more jobs to run.
            Mock.stubMethod(mockDAO, 'apiCountScheduledObjects')
                    .withArguments(new List<Object>{ false })
                    .expected(1)
                    .returns(0);
        }

        return mockDAO;
    }

    private static AsynchronousDAO mockForFailure(
            Asynchronous__c asyncObject,
            Asynchronous.Status expectedStatus,
            Exception exc,
            Boolean jobToBeDeleted,
            Boolean moreTestsToRun
    ) {
        AsynchronousDAO mockDAO = (AsynchronousDAO) Mock.stub(AsynchronousDAO.class);

        // Finalizer must get the job once.
        Mock.stubMethod(mockDAO, 'apiGetObject')
                .withArguments(new List<Object> { asyncObject.Id })
                .expected(1)
                .returns(asyncObject);

        // An Exception should be recorded.
        Mock.stubMethod(mockDAO, 'apiPersistException')
                .withArguments(new List<Object> {
                        new AsynchronousException__c(
                                StatusOnError__c = asyncObject.Status__c,
                                RetryNumber__c = asyncObject.RetryNumber__c,
                                ExceptionType__c = exc.getTypeName(),
                                ExceptionMessage__c = exc.getMessage(),
                                ExceptionStackTrace__c = exc.getStackTraceString()
                        )
                })
                .expected(1);

        if (expectedStatus == Asynchronous.Status.QUEUED) {
            // The retries have not been exhausted so the job should be queued.
            Asynchronous__c queuedAsyncObject = asyncObject.clone(true);
            queuedAsyncObject.Status__c = expectedStatus.name();
            queuedAsyncObject.RetryNumber__c++;

            Mock.stubMethod(mockDAO, 'apiPersistObjects')
                    .withArguments(new List<Object> { new List<Asynchronous__c> { queuedAsyncObject } })
                    .expected(1);

        } else if (jobToBeDeleted) {
                // The Runnable's onFailure method will have asked for the job to be deleted.
                Mock.stubMethod(mockDAO, 'apiRemoveObjects')
                        .withArguments(new List<Object>{new List<Asynchronous__c>{ asyncObject } })
                        .expected(1);
        } else {
            // After a successful call to Runnable.onFailed, the job should be marked as FAILED.
            Asynchronous__c persistedAsyncObject = asyncObject.clone(true);
            persistedAsyncObject.Status__c = expectedStatus.name();

            Mock.stubMethod(mockDAO, 'apiPersistObjects')
                    .withArguments(new List<Object> { new List<Asynchronous__c> { persistedAsyncObject } })
                    .expected(1);
        }

        if (moreTestsToRun) {
            // The Finalizer should then check if there are any jobs left to run. In this case, return 2 as
            // the AsyncScheduler.getMaximumActive method will also call the same DAO method.
            Mock.stubMethod(mockDAO, 'apiCountScheduledObjects')
                    .withArguments(new List<Object>{ false })
                    .expected(2)
                    .returns(1);

            // The AsynchronousScheduler.getMaximumActive method will call the DAO method once.
            Mock.stubMethod(mockDAO, 'apiCountScheduledObjects')
                    .withArguments(new List<Object>{ true })
                    .expected(1)
                    .returns(1);

            // The Finalizer will then try to start the scheduler.
            Asynchronous__c schedulerAsyncObject = new Asynchronous__c(
                    Id = null,
                    OwnerId = UserInfo.getUserId(),
                    Status__c = Asynchronous.Status.PENDING.name(),
                    Reference__c = null,
                    Runnable__c = AsynchronousScheduler.Executor.class.getName(),
                    MaximumRetries__c = 0,
                    RetryInterval__c = 0,
                    RetryNumber__c = 0
            );

            // The call to this method will make the Asynchronous Scheduler think it has jobs to run.
            Mock.stubMethod(mockDAO, 'apiCountActiveObjects')
                    .withArguments(new List<Object>{ schedulerAsyncObject })
                    .expected(1)
                    .returns(1);

        } else {
            // The Finalizer should then check if there are any jobs left to run. In this case, return 0 as
            // to make it think there are no more jobs to run.
            Mock.stubMethod(mockDAO, 'apiCountScheduledObjects')
                    .withArguments(new List<Object>{
                            false
                    })
                    .expected(1)
                    .returns(0);
        }

        return mockDAO;
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