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
        Asynchronous__c asyncObject = new Asynchronous__c(Id = TestHelper.nextId(Asynchronous__c.SObjectType));
        Exception exc = new Asynchronous.APIException('Test');

        AsynchronousError__c asyncError = new AsynchronousError__c(
                Asynchronous__c = asyncObject.Id,
                StatusOnError__c = asyncObject.Status__c,
                ExceptionType__c = exc.getTypeName(),
                ExceptionMessage__c = exc.getMessage(),
                ExceptionStackTrace__c = exc.getStackTraceString()
        );

        AsynchronousDAO mockDAO = (AsynchronousDAO) Mock.stub(AsynchronousDAO.class);
        AsynchronousDAO.INSTANCE = mockDao;

        Mock.stubMethod(mockDAO, 'persistAsynchronousError')
                .withArguments(new List<Object> { asyncError })
                .expected(1);

        AsynchronousHelper.recordException(asyncObject, exc);

        Mock.validate(mockDAO);
    }

    @IsTest
    private static void testInternalFailure() {
        Asynchronous__c asyncObject = new Asynchronous__c(Id = TestHelper.nextId(Asynchronous__c.SObjectType));
        Exception exc = new Asynchronous.APIException('Test');

        AsynchronousError__c asyncError = new AsynchronousError__c(
                Asynchronous__c = asyncObject.Id,
                StatusOnError__c = asyncObject.Status__c,
                ExceptionType__c = exc.getTypeName(),
                ExceptionMessage__c = exc.getMessage(),
                ExceptionStackTrace__c = exc.getStackTraceString()
        );

        Asynchronous__c expectedAsyncObject = asyncObject.clone(true);
        expectedAsyncObject.Status__c = Asynchronous.Status.FAILED.name();

        AsynchronousDAO mockDAO = (AsynchronousDAO) Mock.stub(AsynchronousDAO.class);
        AsynchronousDAO.INSTANCE = mockDao;

        Mock.stubMethod(mockDAO, 'persistAsynchronousError')
                .withArguments(new List<Object> { asyncError })
                .expected(1);

        Mock.stubMethod(mockDAO, 'persistAsynchronous')
                .withArguments(new List<Object> { new List<Asynchronous__c> { expectedAsyncObject } })
                .expected(1);

        AsynchronousHelper.internalFailure(asyncObject, exc);

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

        Asynchronous__c asynchronousObject = new Asynchronous__c(Id = TestHelper.nextId(Asynchronous__c.SObjectType));
        for (Integer size : new List<Integer> { AsynchronousHelper.MAX_CHUNK_SIZE, 1, 2, 4, 8, 16, 32, 62, 128, 256 }) {
            AsynchronousHelper.MAX_CHUNK_SIZE = size;
            List<AsynchronousState__c> chunks = AsynchronousHelper.encodeState(asynchronousObject, state);
            Assert.areEqual(state, AsynchronousHelper.decodeState(chunks));
        }
    }
}