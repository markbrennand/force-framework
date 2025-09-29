/**
 * @description
 * <p>
 * Unit tests for AsynchronousFinalizer class.
 * <p>
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../LICENSE target="_blank">MIT License</a>.
 *
 * @author Mark Brennand
 */
@IsTest
@SuppressWarnings('PMD')
public with sharing class AsynchronousFinalizerTests {
    private final static String TESTING = 'asynchronous';

    @TestSetup
    private static void createUsers() {
        TestHelper.createUsers(TESTING, new Set<String> { 'ForceFwDependencyInjectionPermissions', 'ForceFwAsynchronousPermissions' });
    }

    @IsTest
    private static void testJobKeptOnSuccess() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            AsynchronousJob__c asyncObject = new AsynchronousJob__c(
                    Id = MockerV1.fakeId(AsynchronousJob__c.SObjectType),
                    Status__c = AsynchronousV1.Status.RUNNING.name(),
                    OwnerId = UserInfo.getUserId(),
                    MaximumRetries__c = 0, // Makes FinalizerTestRunnable.onSuccess return true.
                    RetryInterval__c = 0,
                    RetryNumber__c = 0,
                    Runnable__c = FinalizerTestRunnable.class.getName(),
                    ScheduledRunTime__c = CommonHelper.now()
            );

            AsynchronousDAO.impl = (AsynchronousDAO) mockForSuccess(asyncObject, false).mock();
            AsynchronousFinalizer.createFinalizer(asyncObject.Id).execute(new Context(null));
            MockerV1.validate();
        }
    }

    @IsTest
    private static void testJobDeletedOnSuccess() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            AsynchronousJob__c asyncObject = new AsynchronousJob__c(
                    Id = MockerV1.fakeId(AsynchronousJob__c.SObjectType),
                    Status__c = AsynchronousV1.Status.RUNNING.name(),
                    OwnerId = UserInfo.getUserId(),
                    MaximumRetries__c = 1, // Makes FinalizerTestRunnable.onSuccess return false.
                    RetryInterval__c = 0,
                    RetryNumber__c = 0,
                    Runnable__c = FinalizerTestRunnable.class.getName(),
                    ScheduledRunTime__c = CommonHelper.now()
            );

            AsynchronousDAO.impl = (AsynchronousDAO) mockForSuccess(asyncObject, true).mock();
            AsynchronousFinalizer.createFinalizer(asyncObject.Id).execute(new Context(null));
            MockerV1.validate();
        }
    }

    @IsTest
    private static void testExceptionInOnSuccess() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            AsynchronousJob__c asyncObject = new AsynchronousJob__c(
                    Id = MockerV1.fakeId(AsynchronousJob__c.SObjectType),
                    Status__c = AsynchronousV1.Status.RUNNING.name(),
                    OwnerId = UserInfo.getUserId(),
                    MaximumRetries__c = 0,
                    RetryInterval__c = 1, // Makes FinalizerTestRunnable.onSuccess throw an Exception.
                    RetryNumber__c = 0,
                    Runnable__c = FinalizerTestRunnable.class.getName(),
                    ScheduledRunTime__c = CommonHelper.now()
            );

            AsynchronousDAO.impl = (AsynchronousDAO) mockForException(asyncObject, false, 'onSuccess failed').mock();
            AsynchronousFinalizer.createFinalizer(asyncObject.Id).execute(new Context(null));
            MockerV1.validate();
        }
    }

    @IsTest
    private static void testJobKeptOnFailure() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            AsynchronousJob__c asyncObject = new AsynchronousJob__c(
                    Id = MockerV1.fakeId(AsynchronousJob__c.SObjectType),
                    Status__c = AsynchronousV1.Status.RUNNING.name(),
                    OwnerId = UserInfo.getUserId(),
                    MaximumRetries__c = 0, // Makes FinalizerTestRunnable.onFailure return true.
                    RetryInterval__c = 0,
                    RetryNumber__c = 0,
                    Runnable__c = FinalizerTestRunnable.class.getName(),
                    ScheduledRunTime__c = CommonHelper.now()
            );

            Exception exc = new AsynchronousV1.APIException('Test');

            AsynchronousDAO.impl = (AsynchronousDAO) mockForFailure(asyncObject, AsynchronousV1.Status.FAILED, exc, false).mock();
            AsynchronousFinalizer.createFinalizer(asyncObject.Id).execute(new Context(exc));
            MockerV1.validate();
        }
    }

    @IsTest
    private static void testJobDeletedOnFailure() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            AsynchronousJob__c asyncObject = new AsynchronousJob__c(
                    Id = MockerV1.fakeId(AsynchronousJob__c.SObjectType),
                    Status__c = AsynchronousV1.Status.RUNNING.name(),
                    OwnerId = UserInfo.getUserId(),
                    MaximumRetries__c = 1, // Makes FinalizerTestRunnable.onFailure return false.
                    RetryInterval__c = 0,
                    RetryNumber__c = 1,
                    Runnable__c = FinalizerTestRunnable.class.getName(),
                    ScheduledRunTime__c = CommonHelper.now()
            );

            Exception exc = new AsynchronousV1.APIException('Test');

            AsynchronousDAO.impl = (AsynchronousDAO) mockForFailure(asyncObject, AsynchronousV1.Status.FAILED, exc, true).mock();
            AsynchronousFinalizer.createFinalizer(asyncObject.Id).execute(new Context(exc));
            MockerV1.validate();
        }
    }

    @IsTest
    private static void testExceptionInOnFailure() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            AsynchronousJob__c asyncObject = new AsynchronousJob__c(
                    Id = MockerV1.fakeId(AsynchronousJob__c.SObjectType),
                    Status__c = AsynchronousV1.Status.RUNNING.name(),
                    OwnerId = UserInfo.getUserId(),
                    MaximumRetries__c = 0,
                    RetryInterval__c = 1, // Makes FinalizerTestRunnable.onFailure throw an Exception.
                    RetryNumber__c = 0,
                    Runnable__c = FinalizerTestRunnable.class.getName(),
                    ScheduledRunTime__c = CommonHelper.now()
            );

            Exception exc = new AsynchronousV1.APIException('Test');

            AsynchronousDAO.impl = (AsynchronousDAO) mockForException(asyncObject, true, 'onFailure failed').mock();
            AsynchronousFinalizer.createFinalizer(asyncObject.Id).execute(new Context(exc));
            MockerV1.validate();
        }
    }

    @IsTest
    private static void testRequeue() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            AsynchronousJob__c asyncObject = new AsynchronousJob__c(
                    Id = MockerV1.fakeId(AsynchronousJob__c.SObjectType),
                    Status__c = AsynchronousV1.Status.RUNNING.name(),
                    OwnerId = UserInfo.getUserId(),
                    MaximumRetries__c = 4,
                    RetryInterval__c = 0,
                    RetryNumber__c = 2,
                    Runnable__c = FinalizerTestRunnable.class.getName(),
                    ScheduledRunTime__c = CommonHelper.now()
            );

            Exception exc = new AsynchronousV1.APIException('Test');

            AsynchronousDAO.impl = (AsynchronousDAO) mockForFailure(asyncObject, AsynchronousV1.Status.QUEUED, exc, false).mock();
            AsynchronousFinalizer.createFinalizer(asyncObject.Id).execute(new Context(exc));
            MockerV1.validate();
        }
    }

    @IsTest
    private static void testSchedulerQueued() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            AsynchronousJob__c asyncObject = new AsynchronousJob__c(
                    Id = MockerV1.fakeId(AsynchronousJob__c.SObjectType),
                    Status__c = AsynchronousV1.Status.RUNNING.name(),
                    OwnerId = UserInfo.getUserId(),
                    MaximumRetries__c = 0,
                    RetryInterval__c = 0,
                    RetryNumber__c = 0,
                    Runnable__c = AsynchronousScheduler.RunNextAvailable.class.getName(),
                    ScheduledRunTime__c = CommonHelper.now()
            );

            MockerV1 mocked = mockForSuccess(asyncObject, true);

            // Not happy about this test. For now as it it's so hard to pass state without creating the
            // AsynchronousJob__c object, the test for the Scheduler being queued is the failure to parse the JSON
            // from the job's state.
            mocked
                    .whenArgument(new AsynchronousJobException__c(
                            AsynchronousJob__c = asyncObject.Id,
                            ExceptionType__c = 'System.NullPointerException',
                            ExceptionMessage__c = 'null input to JSON parser'
                    ))
                        .forMethod('persistException').called(1)
                    .whenArgument(new List<AsynchronousJob__c>{
                            new AsynchronousJob__c(Id = asyncObject.Id, Status__c = AsynchronousV1.Status.FAILED.name())
                    })
                        .forMethod('persistObjects').called(1);

            AsynchronousDAO.impl = (AsynchronousDAO) mocked.mock();
            AsynchronousFinalizer.createFinalizer(asyncObject.Id).execute(new Context(null));
            MockerV1.validate();
        }
    }

    @IsTest
    private static void testCancellationFromOnError() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            AsynchronousJob__c asyncObject = new AsynchronousJob__c(
                    Id = MockerV1.fakeId(AsynchronousJob__c.SObjectType),
                    Status__c = AsynchronousV1.Status.RUNNING.name(),
                    OwnerId = UserInfo.getUserId(),
                    MaximumRetries__c = 4,
                    RetryInterval__c = 2, // Makes Runnable.onError return CANCELLED.
                    RetryNumber__c = 2,
                    Runnable__c = FinalizerTestRunnable.class.getName(),
                    ScheduledRunTime__c = CommonHelper.now()
            );

            Exception exc = new AsynchronousV1.APIException('Test');

            AsynchronousDAO.impl = (AsynchronousDAO) mockForFailure(asyncObject, AsynchronousV1.Status.CANCELLED, exc, false).mock();
            AsynchronousFinalizer.createFinalizer(asyncObject.Id).execute(new Context(exc));
            MockerV1.validate();
        }
    }

    private static MockerV1 mockForSuccess(
            AsynchronousJob__c asyncObject,
            Boolean jobToBeDeleted
    ) {
        MockerV1 mocked = MockerV1.of(AsynchronousDAO.class);
        mocked
                .whenArgument(asyncObject.Id)
                    .forMethod('getObject').called(1).returns(asyncObject);

        if (jobToBeDeleted) {
            mocked
                    // The Runnable onFailure method will have asked for the job to be deleted.
                    .whenArgument(new List<AsynchronousJob__c>{ asyncObject })
                        .forMethod('removeObjects').called(1);
        } else {
            mocked
                    // After a successful call to Runnable.onSuccess, the job should be marked as SUCCEEDED.
                    .whenArgument(new List<AsynchronousJob__c> { new AsynchronousJob__c(Id = asyncObject.Id, Status__c = AsynchronousV1.Status.SUCCEEDED.name()) })
                        .forMethod('persistObjects').called(1);
        }

        return mocked;
    }

    private static MockerV1 mockForFailure(
            AsynchronousJob__c asyncObject,
            AsynchronousV1.Status expectedStatus,
            Exception exc,
            Boolean jobToBeDeleted
    ) {
        MockerV1 mocked = MockerV1.of(AsynchronousDAO.class);
        mocked
                // Finalizer must get the job once.
                .whenArgument(asyncObject.Id)
                    .forMethod('getObject').called(1).returns(asyncObject)

                // An Exception should be recorded.
                .whenArgument(new AsynchronousJobException__c(
                        AsynchronousJob__c = asyncObject.Id,
                        StatusOnError__c = asyncObject.Status__c,
                        RetryNumber__c = asyncObject.RetryNumber__c,
                        ExceptionType__c = exc.getTypeName(),
                        ExceptionMessage__c = exc.getMessage(),
                        ExceptionStackTrace__c = exc.getStackTraceString()
                ))
                    .forMethod('persistException').called(1);

        if (expectedStatus == AsynchronousV1.Status.QUEUED) {
            mocked
                    // The retries have not been exhausted so the job should be queued.
                    .whenArgument(new List<AsynchronousJob__c> {
                            new AsynchronousJob__c(Id = asyncObject.Id, Status__c = expectedStatus.name(), RetryNumber__c = asyncObject.RetryNumber__c+1)
                    })
                        .forMethod('persistObjects').called(1);

        } else if (jobToBeDeleted) {
            mocked
                    // The Runnable onFailure method will have asked for the job to be deleted.
                    .whenArgument(new List<AsynchronousJob__c> {
                            new AsynchronousJob__c(Id = asyncObject.Id)
                    })
                        .forMethod('removeObjects').called(1);
        } else {
            mocked
                    // After a successful call to Runnable.onFailed, the job should be marked as FAILED.
                    .whenArgument(new List<AsynchronousJob__c> {
                            new AsynchronousJob__c(Id = asyncObject.Id, Status__c = expectedStatus.name())
                    })
                        .forMethod('persistObjects').called(1);
        }

        return mocked;
    }

    private static MockerV1 mockForException(
            AsynchronousJob__c asyncObject,
            Boolean isJobFailed,
            String exceptionMessage
    ) {
        MockerV1 mocked = MockerV1.of(AsynchronousDAO.class);

        mocked
                // Finalizer must get the job once.
                .whenArgument(asyncObject.Id)
                    .forMethod('getObject').called(1).returns(asyncObject)

                // And the error from the on method must be persisted.
                .whenArgument(new AsynchronousJobException__c(
                        AsynchronousJob__c = asyncObject.Id,
                        RetryNumber__c = asyncObject.RetryNumber__c,
                        StatusOnError__c = asyncObject.Status__c,
                        ExceptionType__c = AsynchronousV1.APIException.class.getName(),
                        ExceptionMessage__c = exceptionMessage
                ))
                    .forMethod('persistException').called(1)

                // The job status will be changed to FAILED.
                .whenArgument(new List<AsynchronousJob__c> { new AsynchronousJob__c(Id = asyncObject.Id, Status__c = AsynchronousV1.Status.FAILED.name()) } )
                    .forMethod('persistObjects').called(1);

        if (isJobFailed) {
            mocked
                    // The Exception that caused onFailure to be called must be recorded.
                    .whenArgument(new AsynchronousJobException__c(
                            AsynchronousJob__c = asyncObject.Id,
                            RetryNumber__c = asyncObject.RetryNumber__c,
                            StatusOnError__c = asyncObject.Status__c,
                            ExceptionType__c = AsynchronousV1.APIException.class.getName(),
                            ExceptionMessage__c = 'Test'
                    ))
                        .forMethod('persistException').called(1);
        }

        return mocked;
    }

    public with sharing class FinalizerTestRunnable extends AsynchronousV1.Runnable {

        public FinalizerTestRunnable() {
            super(FinalizerTestRunnable.class);
        }

        public override Integer getMaximumActive() {
            return 1;
        }

        public override Boolean onSuccess(AsynchronousV1.Job job) {
            return process(job, 'onSuccess');
        }

        public override Boolean onFailure(AsynchronousV1.Job job, Exception exc) {
            return process(job, 'onFailure');
        }

        public override AsynchronousV1.Status onError(AsynchronousV1.Job job, Exception exc) {
            return job.getRetryInterval() == 2 ? AsynchronousV1.Status.CANCELLED : AsynchronousV1.Status.QUEUED;
        }

        public override Boolean onCancellation(AsynchronousV1.Job job) {
            return process(job, 'onCancellation');
        }

        public override void run(AsynchronousV1.Job asyncJob, String apexJobId) {}

        private Boolean process(AsynchronousV1.Job job, String method) {
            if (job.getRetryInterval() == 1) {
                throw new AsynchronousV1.APIException(method + ' failed');
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