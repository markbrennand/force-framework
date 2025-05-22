/**
 * @description
 * Unit tests for the AsynchronousHelper class.
 *
 * @author Mark Brennand
 */
@IsTest
public with sharing class AsynchronousHelperTests {

    @IsTest
    private static void testRecordException() {

        // The job for the test.
        AsynchronousJob__c asyncObject = new AsynchronousJob__c(
                Id = TestHelper.nextId(AsynchronousJob__c.SObjectType),
                Status__c = Asynchronous.Status.RUNNING.name(),
                RetryNumber__c = 1
        );

        // And the Exception to record.
        Exception exc = new Asynchronous.APIException('Test');

        // Add the mocking.
        AsynchronousDAO mockDAO = mockForRecordException(asyncObject, exc);
        AsynchronousDAO.INSTANCE = mockDAO;

        // Perform the test.
        AsynchronousHelper.recordException(asyncObject, exc);

        // Confirm the mocked methods were called correctly.
        Mock.validate(mockDAO);
    }

    @IsTest
    private static void testInternalFailure() {

        // The job for the test.
        AsynchronousJob__c asyncObject = new AsynchronousJob__c(
                Id = TestHelper.nextId(AsynchronousJob__c.SObjectType),
                Status__c = Asynchronous.Status.RUNNING.name(),
                RetryNumber__c = 3
        );

        // And the Exception to record.
        Exception exc = new Asynchronous.APIException('Test');

        // Add the mocking.
        AsynchronousDAO mockDAO = mockForInternalFailure(asyncObject, exc);
        AsynchronousDAO.INSTANCE = mockDAO;

        // Perform the test.
        AsynchronousHelper.recordInternalException(asyncObject, exc);

        // Confirm the mocked methods were called correctly.
        Mock.validate(mockDAO);
    }

    @IsTest
    private static void testState() {
        Map<String, String> state = new Map<String, String> {
                'property1' => 'value1',
                'property2' => 'value2',
                'property3' => 'value3',
                'property4' => 'value4',
                'property5' => 'a lot longer value for value number 5'
        };

        // Repeat the encode/decode test for different chunk sizes.
        AsynchronousJob__c asynchronousObject = new AsynchronousJob__c(Id = TestHelper.nextId(AsynchronousJob__c.SObjectType));
        for (Integer size : new List<Integer> { AsynchronousHelper.MAX_CHUNK_SIZE, 1, 2, 4, 8, 16, 32, 62, 128, 256 }) {
            AsynchronousHelper.MAX_CHUNK_SIZE = size;
            List<AsynchronousJobState__c> chunks = AsynchronousHelper.encodeState(asynchronousObject, state);
            Assert.areEqual(state, AsynchronousHelper.decodeState(chunks));
        }
    }

    private static AsynchronousDAO mockForRecordException(AsynchronousJob__c asyncObject, Exception exc) {
        AsynchronousDAO mockDAO = (AsynchronousDAO) Mock.stub(AsynchronousDAO.class);

        // The error should be persisted once.
        Mock.stubMethod(mockDAO, 'apiPersistException')
                .withArguments(new List<Object> {
                        new AsynchronousJobException__c(
                                AsynchronousJob__c = asyncObject.Id,
                                RetryNumber__c = asyncObject.RetryNumber__c,
                                StatusOnError__c = Asynchronous.Status.RUNNING.name(),
                                ExceptionType__c = exc.getTypeName(),
                                ExceptionMessage__c = exc.getMessage(),
                                ExceptionStackTrace__c = exc.getStackTraceString()
                        )
                })
                .expected(1);

        return mockDao;
    }

    private static AsynchronousDAO mockForInternalFailure(AsynchronousJob__c asyncObject, Exception exc) {
        // The Exception should be recorded.
        AsynchronousDAO mockDAO = mockForRecordException(asyncObject, exc);

        // And the status of the Asynchronous object set to FAILED.
        AsynchronousJob__c expectedAsyncObject = asyncObject.clone(true);
        expectedAsyncObject.Status__c = Asynchronous.Status.FAILED.name();

        Mock.stubMethod(mockDAO, 'apiPersistObjects')
                .withArguments(new List<Object> { new List<AsynchronousJob__c> { expectedAsyncObject } })
                .expected(1);

        return mockDAO;
    }
}