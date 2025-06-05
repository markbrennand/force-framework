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
    private static void testRecordException() {
        System.runAs(AsynchronousTestHelper.getUser()) {
            AsynchronousJob__c asyncObject = new AsynchronousJob__c(
                    Id = Mocker.fakeId(AsynchronousJob__c.SObjectType),
                    Status__c = Asynchronous.Status.RUNNING.name(),
                    RetryNumber__c = 1
            );

            Exception exc = new Asynchronous.APIException('Test');

            AsynchronousDAO.INJECT = mockForRecordException(asyncObject, exc);
            AsynchronousHelper.INJECT.recordException(asyncObject, new Asynchronous.APIException('Wrapper', exc));
            Mocker.validate();
        }
    }

    @IsTest
    private static void testInternalFailure() {
        System.runAs(AsynchronousTestHelper.getUser()) {
            AsynchronousJob__c asyncObject = new AsynchronousJob__c(
                    Id = Mocker.fakeId(AsynchronousJob__c.SObjectType),
                    Status__c = Asynchronous.Status.RUNNING.name(),
                    RetryNumber__c = 3
            );

            Exception exc = new Asynchronous.APIException('Test');

            AsynchronousDAO.INJECT = mockForInternalFailure(asyncObject, exc);
            AsynchronousHelper.INJECT.recordInternalException(asyncObject, new Asynchronous.APIException('Wrapper', exc));
            Mocker.validate();
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
            AsynchronousJob__c asynchronousObject = new AsynchronousJob__c(Id = Mocker.fakeId(AsynchronousJob__c.SObjectType));
            for (Integer size : new List<Integer>{
                    AsynchronousHelper.MAX_CHUNK_SIZE, 1, 2, 4, 8, 16, 32, 62, 128, 256
            }) {
                AsynchronousHelper.MAX_CHUNK_SIZE = size;
                List<AsynchronousJobState__c> chunks = AsynchronousHelper.INJECT.encodeState(asynchronousObject, state);
                Assert.areEqual(state, AsynchronousHelper.INJECT.decodeState(chunks));
            }
        }
    }

    @IsTest
    private static void testMocking() {
        System.runAs(AsynchronousTestHelper.getUser()) {
            final AsynchronousJob__c asyncObject = new AsynchronousJob__c(Id = Mocker.fakeId(AsynchronousJob__c.SObjectType));
            final Exception exc = new DMLException('Test');

            AsynchronousHelper.INJECT = (AsynchronousHelper) Mocker.of(AsynchronousHelper.class)
                    .whenArguments(asyncObject, new Asynchronous.APIException('Wrapper', exc))
                        .withComparators(new List<Comparator<Object>>{
                                new TestHelper.ExceptionComparator()
                        })
                        .expectMethod('recordException').called(1)
                        .expectMethod('recordInternalException').called(1)
                    .whenArgument(asyncObject)
                        .expectMethod('queueJob').called(1).throws(exc)
                    .mock();

            AsynchronousHelper.INJECT.recordException(asyncObject, new Asynchronous.APIException('Wrapper', exc));
            AsynchronousHelper.INJECT.recordInternalException(asyncObject, new Asynchronous.APIException('Wrapper', exc));

            try {
                AsynchronousHelper.INJECT.queueJob(asyncObject);
                Assert.fail();
            } catch (DmlException de) {
                Assert.areEqual(de, exc, 'Unexpected exception thrown');
            }
        }
    }

    private static AsynchronousDAO mockForRecordException(AsynchronousJob__c asyncObject, Exception exc) {
        return (AsynchronousDAO) Mocker.of(AsynchronousDAO.class)
                // The error should be persisted once.
                .whenArgument(new AsynchronousJobException__c(
                        AsynchronousJob__c = asyncObject.Id,
                        RetryNumber__c = asyncObject.RetryNumber__c,
                        StatusOnError__c = Asynchronous.Status.RUNNING.name(),
                        ExceptionType__c = exc.getTypeName(),
                        ExceptionMessage__c = exc.getMessage(),
                        ExceptionStackTrace__c = exc.getStackTraceString()

                ))
                    .expectMethod('persistException').called(1)
                .mock();
    }

    private static AsynchronousDAO mockForInternalFailure(AsynchronousJob__c asyncObject, Exception exc) {
        return (AsynchronousDAO) Mocker.of(AsynchronousDAO.class)
                // The error should be persisted once.
                .whenArgument(new AsynchronousJobException__c(
                        AsynchronousJob__c = asyncObject.Id,
                        RetryNumber__c = asyncObject.RetryNumber__c,
                        StatusOnError__c = Asynchronous.Status.RUNNING.name(),
                        ExceptionType__c = exc.getTypeName(),
                        ExceptionMessage__c = exc.getMessage(),
                        ExceptionStackTrace__c = exc.getStackTraceString()

                ))
                    .expectMethod('persistException').called(1)

                // And the status of the Asynchronous object set to FAILED.
                .whenArgument(new List<AsynchronousJob__c> {
                        new AsynchronousJob__c(Id = asyncObject.Id, Status__c = Asynchronous.Status.FAILED.name())
                })
                    .expectMethod('persistObjects').called(1)
                .mock();
    }
}