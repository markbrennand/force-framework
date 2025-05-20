/**
 * @description
 * Common test data and methods for all unit tests.
 *
 * @author Mark Brennand
 */
@IsTest
public with sharing class TestHelper {
    private static Integer nextId = 0;

    @TestVisible
    private static String nextId(SObjectType objectType) {
        final String id = String.valueOf(++nextId);
        final Integer length = id.length();

        return String.join(
                new List<String> {
                        objectType.getDescribe().keyPrefix,
                        '0'.repeat(15 - length),
                        id
                },
                ''
        );
    }
}