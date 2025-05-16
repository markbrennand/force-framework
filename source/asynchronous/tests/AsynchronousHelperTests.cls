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
        /* TBD
        Asynchronous__c asynchronousObject = new Asynchronous__c();
        AsynchronousHelper.recordException(asynchronousObject, new DMLException('Test'));

        Assert.areEqual('System.DmlException', asynchronousObject.ExceptionType__c);
        Assert.areEqual('Test', asynchronousObject.ExceptionMessage__c);
        Assert.isTrue(asynchronousObject.ExceptionStackTrace__c.startsWith('Class'));
         */
    }

    @IsTest
    private static void testState() {
        AsynchronousHelper.MAX_CHUNK_SIZE = 1;
        Map<String, String> state = new Map<String, String> { 'property1' => 'value1', 'property2' => 'value2' };

        Asynchronous__c asynchronousObject = new Asynchronous__c(Id = TestHelper.nextId(Asynchronous__c.SObjectType));
        List<AsynchronousState__c> chunks = AsynchronousHelper.encodeState(asynchronousObject, state);

        for (AsynchronousState__c chunk : chunks) {
            System.debug(chunk.Content__c);
        }
    }

    @IsTest
    private static void testStateChunking() {
        Map<String, String> state = new Map<String, String> {
                'property1' => 'value1',
                'property2' => 'value2',
                'property3' => 'value3',
                'property4' => 'value4',
                'property5' => 'a lot longer value for value number 5'
        };

        Asynchronous__c asynchronousObject = new Asynchronous__c(Id = TestHelper.nextId(Asynchronous__c.SObjectType));
        for (Integer size : new List<Integer> { AsynchronousHelper.MAX_CHUNK_SIZE, 1, 2, 4, 8, 16, 32, 62, 128 }) {
            List<AsynchronousState__c> chunks = AsynchronousHelper.encodeState(asynchronousObject, state);
            Assert.areEqual(state, AsynchronousHelper.decodeState(chunks));
        }
    }
}