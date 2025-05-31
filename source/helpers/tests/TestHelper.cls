/**
 * @description
 * Common test data and methods for all unit tests.
 *
 * @author Mark Brennand
 */
@IsTest
public with sharing class TestHelper {
    private final static String NAMESPACE = [SELECT NamespacePrefix FROM Organization LIMIT 1].NamespacePrefix;
    private static Integer nextId = 0;

    @TestVisible
    private static String nextId(final SObjectType objectType) {
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

    @TestVisible
    private with sharing class ExceptionComparator implements Comparator<Object> {

        public Integer compare(final Object param1, final Object param2) {
            return param1 instanceof Exception
                    && param2 instanceof Exception
                    && ((Exception) param1).getMessage() == ((Exception) param2).getMessage()
                    && ((Exception) param1).getCause()?.getTypeName() == ((Exception) param2).getCause()?.getTypeName()
                    && ((Exception) param1).getCause()?.getMessage() == ((Exception) param2).getCause()?.getMessage()
                    ? 0 : -1;
        }
    }

    @TestVisible
    private static Boolean exceptionContains(final String expectedMessage, final Exception exc) {
        if (String.isEmpty(NAMESPACE)) {
            return exc.getMessage().contains(expectedMessage);
        } else {
            return exc.getMessage().replace(NAMESPACE + '.', '').contains(expectedMessage);
        }
    }
}