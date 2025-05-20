/**
 * @description
 * Unit tests for Asynchronous Finalizer.
 *
 * @author Mark Brennand
 */
@IsTest
public with sharing class AsynchronousFinalizerTests {
    private static Integer successCalls = 0;
    private static Integer failureCalls = 0;
    private static Integer errorCalls = 0;

    @IsTest
    private static void testSuccess() {

        // The job to be finalized.
        Asynchronous__c asyncObject = new Asynchronous__c(Id = TestHelper.nextId(Asynchronous__c.SObjectType));
        asyncObject.Status__c = Asynchronous.Status.RUNNING.name();
        asyncObject.OwnerId = UserInfo.getUserId();
        asyncObject.MaximumRetries__c = 0;
        asyncObject.RetryInterval__c = 0;
        asyncObject.RetryNumber__c = 0;
        asyncObject.Runnable__c = TestRunnable.class.getName();
        asyncObject.ScheduledRunTime__c = Datetime.now();

        AsynchronousDAO mockDAO = mockForSuccess(asyncObject);
        AsynchronousDAO.INSTANCE = mockDao;

        Finalizer finalizer = AsynchronousFinalizer.createFinalizer(asyncObject.Id);
        finalizer.execute(new Context(null));

        Mock.validate(mockDAO);
    }

    @IsTest
    private static void testFailure() {

        // The job to be finalized.
        Asynchronous__c asyncObject = new Asynchronous__c(Id = TestHelper.nextId(Asynchronous__c.SObjectType));
        asyncObject.Status__c = Asynchronous.Status.RUNNING.name();
        asyncObject.OwnerId = UserInfo.getUserId();
        asyncObject.MaximumRetries__c = 4;
        asyncObject.RetryInterval__c = 0;
        asyncObject.RetryNumber__c = 4;
        asyncObject.Runnable__c = TestRunnable.class.getName();
        asyncObject.ScheduledRunTime__c = Datetime.now();

        // And the Exception.
        Exception exc = new Asynchronous.APIException('Test');

        // Add the mocking.
        AsynchronousDAO mockDAO = mockForFailure(asyncObject, exc);
        AsynchronousDAO.INSTANCE = mockDao;

        // Perform the test.
        AsynchronousFinalizer.createFinalizer(asyncObject.Id).execute(new Context(exc));

        // Confirm the mocked methods were called correctly.
        Mock.validate(mockDAO);
    }

    private static AsynchronousDAO mockForSuccess(Asynchronous__c asyncObject) {
        AsynchronousDAO mockDAO = (AsynchronousDAO) Mock.stub(AsynchronousDAO.class);

        // Finalizer must get the job once.
        Mock.stubMethod(mockDAO, 'getObject')
                .withArguments(new List<Object> { asyncObject.Id })
                .expected(1)
                .returns(asyncObject);

        // After a successful call to Runnable.onSuccess, the job should be marked as SUCCEEDED.
        Asynchronous__c persistedAsyncObject = asyncObject.clone(true);
        persistedAsyncObject.Status__c = Asynchronous.Status.SUCCEEDED.name();

        Mock.stubMethod(mockDAO, 'persistAsynchronous')
                .withArguments(new List<Object> { new List<Asynchronous__c> { persistedAsyncObject } })
                .expected(1);

        // The Finalizer should then check if there are any jobs left to run. In this case, return 2 as
        // the AsyncScheduler.getMaximumActive method will also call the same DAO method.
        Mock.stubMethod(mockDAO, 'countScheduledObjects')
                .withArguments(new List<Object> { false })
                .expected(2)
                .returns(1);

        // The AsynchronousScheduler.getMaximumActive method will call the DAO method once.
        Mock.stubMethod(mockDAO, 'countScheduledObjects')
                .withArguments(new List<Object> { true })
                .expected(1)
                .returns(1);

        // The Finalizer will then try to start the scheduler.
        Asynchronous__c schedulerAsyncObject = new Asynchronous__c(
                Id = null,
                OwnerId = UserInfo.getUserId(),
                Status__c = Asynchronous.Status.PENDING.name(),
                Reference__c = null,
                Runnable__c = AsynchronousScheduler.class.getName(),
                MaximumRetries__c = 0,
                RetryInterval__c = 0,
                RetryNumber__c = 0
        );

        // The call to this method will make the Asynchronous Scheduler think it has jobs to run.
        Mock.stubMethod(mockDAO, 'countActiveObjects')
                .withArguments(new List<Object> { schedulerAsyncObject })
                .expected(1)
                .returns(1);

        return mockDAO;
    }

    private static AsynchronousDAO mockForFailure(Asynchronous__c asyncObject, Exception exc) {
        AsynchronousDAO mockDAO = (AsynchronousDAO) Mock.stub(AsynchronousDAO.class);

        // Finalizer must get the job once.
        Mock.stubMethod(mockDAO, 'getObject')
                .withArguments(new List<Object> { asyncObject.Id })
                .expected(1)
                .returns(asyncObject);

        // An Exception should be recorded.
        Mock.stubMethod(mockDAO, 'persistAsynchronousError')
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

        // And the Runnable's onFailure method will have asked for the job to be deleted.
        Mock.stubMethod(mockDAO, 'removeAsynchronous')
                .withArguments(new List<Object> { new List<Asynchronous__c> { asyncObject } })
                .expected(1);

        // The Finalizer should then check if there are any jobs left to run. In this case, return 2 as
        // the AsyncScheduler.getMaximumActive method will also call the same DAO method.
        Mock.stubMethod(mockDAO, 'countScheduledObjects')
                .withArguments(new List<Object> { false })
                .expected(2)
                .returns(1);

        // The AsynchronousScheduler.getMaximumActive method will call the DAO method once.
        Mock.stubMethod(mockDAO, 'countScheduledObjects')
                .withArguments(new List<Object> { true })
                .expected(1)
                .returns(1);

        // The Finalizer will then try to start the scheduler.
        Asynchronous__c schedulerAsyncObject = new Asynchronous__c(
                Id = null,
                OwnerId = UserInfo.getUserId(),
                Status__c = Asynchronous.Status.PENDING.name(),
                Reference__c = null,
                Runnable__c = AsynchronousScheduler.class.getName(),
                MaximumRetries__c = 0,
                RetryInterval__c = 0,
                RetryNumber__c = 0
        );

        // The call to this method will make the Asynchronous Scheduler think it has jobs to run.
        Mock.stubMethod(mockDAO, 'countActiveObjects')
                .withArguments(new List<Object> { schedulerAsyncObject })
                .expected(1)
                .returns(1);

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
            successCalls++;
            return job.getMaximumRetries() == 0;
        }

        public override Boolean onFailure(Asynchronous.Job job, Exception exc) {
            failureCalls++;
            return job.getMaximumRetries() == 0;
        }

        public override Asynchronous.Status onError(Asynchronous.Job job, Exception exc) {
            errorCalls++;
            return job.getMaximumRetries() == 0 ? Asynchronous.Status.CANCELLED : Asynchronous.Status.QUEUED;
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