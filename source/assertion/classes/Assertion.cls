/**
 * @description
 * Class providing programmatic Assertions.
 *
 * The Salesforce Assert class is great, but it throws an Exception which cannot be caught. So, in reality, is only
 * useful for unit tests. All unit tests should use their class.
 *
 * @author Mark Brennand
 */

public with sharing class Assertion {

    /**
     * @description
     * Tests whether the given value is not null.
     *
     * @param value The value to test if not null.
     * @param errorMessage Text to display in Exception if value is null.
     */
    public static void isNotNull(final Object value, final String errorMessage) {
        if (value == null) {
            throw new AssertionException(String.join(
                    new List<String> {
                            'Assertion Failed: Non null value expected: ',
                            errorMessage
                    },
                    ''
            ));
        }
    }

    /**
     * @description
     * Tests whether the given value is true or not.
     *
     * @param value The value to test if truel.
     * @param errorMessage Text to display in Exception if value is false.
     */
    public static void isTrue(final Boolean value, final String errorMessage) {
        if (value != true) {
            throw new AssertionException(String.join(
                    new List<String> {
                            'Assertion Failed: ',
                            errorMessage
                    },
                    ''
            ));
        }
    }

    /**
     * @param expected The expected value.
     * @param actual The actual value.
     * @param errorMessage Text to display in Exception if expected and actual don't match.
     */
    public static void areEqual(final Object expected, final Object actual, final String errorMessage) {
        if (expected != actual  ) {
            throw new AssertionException(String.join(
                    new List<String> {
                            'Assertion Failed: test: ',
                            asString(errorMessage),
                            ': Expected: ',
                            asString(expected),
                            ', Actual: ',
                            String.valueOf(actual)
                    },
                    ''
            ));
        }
    }

    public with sharing class AssertionException extends Exception {}

    private static String asString(Object value) {
        return value == null ? 'null' : String.valueOf(value);
    }
}