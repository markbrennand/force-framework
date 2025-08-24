/**
 * @description
 * <p/>
 * Unit tests for the AsynchronousHelper class.
 * <p/>
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../LICENSE target="_blank">MIT License</a>.
 *
 * @author Mark Brennand
 */
@IsTest
@SuppressWarnings('PMD')
public with sharing class AsynchronousHelperTests {
    private final static String TESTING = 'asynchronous';

    @TestSetup
    private static void createUsers() {
        TestHelper.createUsers(TESTING, new Set<String> { 'ForceFwDependencyInjectionPermissions', 'ForceFwAsynchronousPermissions' });
    }

    @IsTest
    private static void testBindingCheck() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            try {
                DependencyV1.bind(AsynchronousHelper.API.class, AsynchronousAPI.Factory.class);
            } catch(DependencyV1.APIException ae) {
                Assert.isTrue(
                        TestHelper.exceptionContains( 'Class AsynchronousAPI.Factory does not implement AsynchronousHelper.API', ae),
                        'Unexpected exception: ' + ae
                );
            }
        }
    }

    @IsTest
    private static void testExtendedClassIsInert() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            ExtendedClass extended = new ExtendedClass();

            try {
                extended.encodeState(null, null);
                Assert.fail();
            } catch(AsynchronousV1.APIException ae) {
                Assert.areEqual('Access denied', ae.getMessage());
            }

            try {
                extended.recordException(null, null);
                Assert.fail();
            } catch(AsynchronousV1.APIException ae) {
                Assert.areEqual('Access denied', ae.getMessage());
            }

            try {
                extended.recordInternalException(null, null);
                Assert.fail();
            } catch(AsynchronousV1.APIException ae) {
                Assert.areEqual('Access denied', ae.getMessage());
            }

            try {
                extended.decodeState(null);
                Assert.fail();
            } catch(AsynchronousV1.APIException ae) {
                Assert.areEqual('Access denied', ae.getMessage());
            }

            try {
                extended.queueJob(null);
                Assert.fail();
            } catch(AsynchronousV1.APIException ae) {
                Assert.areEqual('Access denied', ae.getMessage());
            }        }
    }

    @IsTest
    private static void testRecordException() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            AsynchronousJob__c asyncObject = new AsynchronousJob__c(
                    Id = MockerV1.fakeId(AsynchronousJob__c.SObjectType),
                    Status__c = AsynchronousV1.Status.RUNNING.name(),
                    RetryNumber__c = 1
            );

            Exception exc = new AsynchronousV1.APIException('Test');

            AsynchronousDAO.API = mockForRecordException(asyncObject, exc);
            AsynchronousHelper.API.recordException(asyncObject, new AsynchronousV1.APIException('Wrapper', exc));
            MockerV1.validate();
        }
    }

    @IsTest
    private static void testInternalFailure() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            AsynchronousJob__c asyncObject = new AsynchronousJob__c(
                    Id = MockerV1.fakeId(AsynchronousJob__c.SObjectType),
                    Status__c = AsynchronousV1.Status.RUNNING.name(),
                    RetryNumber__c = 3
            );

            Exception exc = new AsynchronousV1.APIException('Test');

            AsynchronousDAO.API = mockForInternalFailure(asyncObject, exc);
            AsynchronousHelper.API.recordInternalException(asyncObject, new AsynchronousV1.APIException('Wrapper', exc));
            MockerV1.validate();
        }
    }

    @IsTest
    private static void testState() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            Map<String, String> state = new Map<String, String>{
                    'property1' => 'value1',
                    'property2' => 'value2',
                    'property3' => 'value3',
                    'property4' => 'value4',
                    'property5' => 'a lot longer value for value number 5'
            };

            // Repeat the encode/decode test for different chunk sizes.
            AsynchronousJob__c asynchronousObject = new AsynchronousJob__c(Id = MockerV1.fakeId(AsynchronousJob__c.SObjectType));

            for (Integer size : new List<Integer>{
                    AsynchronousHelper.maxChunkSize, 1, 2, 4, 8, 16, 32, 62, 128, 256
            }) {
                AsynchronousHelper.maxChunkSize = size;
                List<AsynchronousJobState__c> chunks = AsynchronousHelper.API.encodeState(asynchronousObject, state);
                Assert.areEqual(state, AsynchronousHelper.API.decodeState(chunks), 'Unexpected state for size ' + size);
            }
        }
    }

    @IsTest
    private static void testMocking() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            final AsynchronousJob__c asyncObject = new AsynchronousJob__c(Id = MockerV1.fakeId(AsynchronousJob__c.SObjectType));
            final Exception exc = new DmlException('Test');

            AsynchronousHelper.API = (AsynchronousHelper) MockerV1.of(AsynchronousHelper.class)
                    .whenArguments(asyncObject, new AsynchronousV1.APIException('Wrapper', exc))
                        .withComparators(new List<Comparator<Object>>{
                                new TestHelper.ExceptionComparator()
                        })
                        .forMethod('recordException').called(1)
                        .forMethod('recordInternalException').called(1)
                    .whenArgument(asyncObject)
                        .forMethod('queueJob').called(1).throws(exc)
                    .mock();

            AsynchronousHelper.API.recordException(asyncObject, new AsynchronousV1.APIException('Wrapper', exc));
            AsynchronousHelper.API.recordInternalException(asyncObject, new AsynchronousV1.APIException('Wrapper', exc));

            try {
                AsynchronousHelper.API.queueJob(asyncObject);
                Assert.fail('Queue job should fail');
            } catch (DmlException de) {
                Assert.areEqual(de, exc, 'Unexpected exception thrown');
            }
        }
    }

    private static AsynchronousDAO mockForRecordException(AsynchronousJob__c asyncObject, Exception exc) {
        return (AsynchronousDAO) MockerV1.of(AsynchronousDAO.class)
                // The error should be persisted once.
                .whenArgument(new AsynchronousJobException__c(
                        AsynchronousJob__c = asyncObject.Id,
                        RetryNumber__c = asyncObject.RetryNumber__c,
                        StatusOnError__c = AsynchronousV1.Status.RUNNING.name(),
                        ExceptionType__c = exc.getTypeName(),
                        ExceptionMessage__c = exc.getMessage(),
                        ExceptionStackTrace__c = exc.getStackTraceString()

                ))
                    .forMethod('persistException').called(1)
                .mock();
    }

    private static AsynchronousDAO mockForInternalFailure(AsynchronousJob__c asyncObject, Exception exc) {
        return (AsynchronousDAO) MockerV1.of(AsynchronousDAO.class)
                // The error should be persisted once.
                .whenArgument(new AsynchronousJobException__c(
                        AsynchronousJob__c = asyncObject.Id,
                        RetryNumber__c = asyncObject.RetryNumber__c,
                        StatusOnError__c = AsynchronousV1.Status.RUNNING.name(),
                        ExceptionType__c = exc.getTypeName(),
                        ExceptionMessage__c = exc.getMessage(),
                        ExceptionStackTrace__c = exc.getStackTraceString()

                ))
                    .forMethod('persistException').called(1)

                // And the status of the Asynchronous object set to FAILED.
                .whenArgument(new List<AsynchronousJob__c> {
                        new AsynchronousJob__c(Id = asyncObject.Id, Status__c = AsynchronousV1.Status.FAILED.name())
                })
                    .forMethod('persistObjects').called(1)
                .mock();
    }

    private with sharing class ExtendedClass extends AsynchronousHelper {}
}
