/**
 * @description
 * Unit tests for the AsynchronousHelper class.
 *
 * @author Mark Brennand
 */
@IsTest
public with sharing class AsynchronousHelperTests {

    @TestSetup
    private static void setup() {
        AsynchronousTestHelper.createUsers();
    }

    @IsTest
    private static void testBindingCheck() {
        try {
            DependencyV1.bind(AsynchronousHelper.API.class, AsynchronousAPI.Factory.class);
        } catch(Dependency.APIException ae) {
            Assert.isTrue(
                    TestHelper.exceptionContains( 'Class AsynchronousAPI.Factory does not implement AsynchronousHelper.API', ae),
                    'Unexpected exception: ' + ae
            );
        }
    }

    @IsTest
    private static void testExtendedClassIsInsert() {
        ExtendedClass extended = new ExtendedClass();

        try {
            extended.encodeState(null, null);
            Assert.fail();
        } catch(Asynchronous.APIException ae) {
            Assert.areEqual('Access denied', ae.getMessage());
        }

        try {
            extended.recordException(null, null);
            Assert.fail();
        } catch(Asynchronous.APIException ae) {
            Assert.areEqual('Access denied', ae.getMessage());
        }

        try {
            extended.recordInternalException(null, null);
            Assert.fail();
        } catch(Asynchronous.APIException ae) {
            Assert.areEqual('Access denied', ae.getMessage());
        }

        try {
            extended.decodeState(null);
            Assert.fail();
        } catch(Asynchronous.APIException ae) {
            Assert.areEqual('Access denied', ae.getMessage());
        }

        try {
            extended.queueJob(null);
            Assert.fail();
        } catch(Asynchronous.APIException ae) {
            Assert.areEqual('Access denied', ae.getMessage());
        }
    }

    @IsTest
    private static void testRecordException() {
        System.runAs(AsynchronousTestHelper.getUser()) {
            AsynchronousJob__c asyncObject = new AsynchronousJob__c(
                    Id = MockerV1.fakeId(AsynchronousJob__c.SObjectType),
                    Status__c = Asynchronous.Status.RUNNING.name(),
                    RetryNumber__c = 1
            );

            Exception exc = new Asynchronous.APIException('Test');

            AsynchronousDAO.API = mockForRecordException(asyncObject, exc);
            AsynchronousHelper.API.recordException(asyncObject, new Asynchronous.APIException('Wrapper', exc));
            MockerV1.validate();
        }
    }

    @IsTest
    private static void testInternalFailure() {
        System.runAs(AsynchronousTestHelper.getUser()) {
            AsynchronousJob__c asyncObject = new AsynchronousJob__c(
                    Id = MockerV1.fakeId(AsynchronousJob__c.SObjectType),
                    Status__c = Asynchronous.Status.RUNNING.name(),
                    RetryNumber__c = 3
            );

            Exception exc = new Asynchronous.APIException('Test');

            AsynchronousDAO.API = mockForInternalFailure(asyncObject, exc);
            AsynchronousHelper.API.recordInternalException(asyncObject, new Asynchronous.APIException('Wrapper', exc));
            MockerV1.validate();
        }
    }

    @IsTest
    private static void testState() {
        System.runAs(AsynchronousTestHelper.getUser()) {
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
                    AsynchronousHelper.MAX_CHUNK_SIZE, 1, 2, 4, 8, 16, 32, 62, 128, 256
            }) {
                AsynchronousHelper.MAX_CHUNK_SIZE = size;
                List<AsynchronousJobState__c> chunks = AsynchronousHelper.API.encodeState(asynchronousObject, state);
                Assert.areEqual(state, AsynchronousHelper.API.decodeState(chunks), 'Unexpected state for size ' + size);
            }
        }
    }

    @IsTest
    private static void testMocking() {
        System.runAs(AsynchronousTestHelper.getUser()) {
            final AsynchronousJob__c asyncObject = new AsynchronousJob__c(Id = MockerV1.fakeId(AsynchronousJob__c.SObjectType));
            final Exception exc = new DMLException('Test');

            AsynchronousHelper.API = (AsynchronousHelper) MockerV1.of(AsynchronousHelper.class)
                    .whenArguments(asyncObject, new Asynchronous.APIException('Wrapper', exc))
                        .withComparators(new List<Comparator<Object>>{
                                new TestHelper.ExceptionComparator()
                        })
                        .forMethod('recordException').called(1)
                        .forMethod('recordInternalException').called(1)
                    .whenArgument(asyncObject)
                        .forMethod('queueJob').called(1).throws(exc)
                    .mock();

            AsynchronousHelper.API.recordException(asyncObject, new Asynchronous.APIException('Wrapper', exc));
            AsynchronousHelper.API.recordInternalException(asyncObject, new Asynchronous.APIException('Wrapper', exc));

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
                        StatusOnError__c = Asynchronous.Status.RUNNING.name(),
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
                        StatusOnError__c = Asynchronous.Status.RUNNING.name(),
                        ExceptionType__c = exc.getTypeName(),
                        ExceptionMessage__c = exc.getMessage(),
                        ExceptionStackTrace__c = exc.getStackTraceString()

                ))
                    .forMethod('persistException').called(1)

                // And the status of the Asynchronous object set to FAILED.
                .whenArgument(new List<AsynchronousJob__c> {
                        new AsynchronousJob__c(Id = asyncObject.Id, Status__c = Asynchronous.Status.FAILED.name())
                })
                    .forMethod('persistObjects').called(1)
                .mock();
    }

    private with sharing class ExtendedClass extends AsynchronousHelper {}
}