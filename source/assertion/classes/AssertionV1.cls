/**
 * @description
 * <p>
 * Class providing programmatic Assertions.
 * <p>
 * The Salesforce Assert class is great, but it throws an Exception which cannot be caught. So, in reality, is only
 * useful for unit tests.
 * <p>
 * Ancestor methods should be able to catch assertion errors so they can be handled. For example, the Asynchronous
 * API must be able to catch any assertion failures during the processing of a job so it can record the caught
 * Exception. With the Salesforce assertion Exception, that is not possible.
 * <p>
 * The APIs in the Force Framework all use this class to check assertions, allowing any Exception to be caught.
 * <p>
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../LICENSE target="_blank">MIT License</a>.
 *
 * @author Mark Brennand
 */
@SuppressWarnings('PMD.AvoidGlobalModifier')
global with sharing class AssertionV1 {

    /**
     * @description
     * Exception thrown when an assertion fails.
     */
    global with sharing class AssertionException extends Exception {}

    /**
     * @description
     * Tests whether the given value is not null.
     *
     * @param value The value to test if not null.
     * @param errorMessage Text to display in Exception if value is null.
     */
    public static void isNotNull(final Object value, final String errorMessage) {
        if (value == null) {
            throw new AssertionException(buildMessage(String.join(
                    new List<String> {
                            'Non null value expected: ',
                            errorMessage
                    },
                    ''
            )));
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
            throw new AssertionException(buildMessage(errorMessage));
        }
    }

    /**
     * @description
     * Tests whether the given vales are identical.
     *
     * @param expected The expected value.
     * @param actual The actual value.
     * @param errorMessage Text to display in Exception if expected and actual don't match.
     */
    public static void areEqual(final Object expected, final Object actual, final String errorMessage) {
        if (expected != actual  ) {
            throw new AssertionException(buildMessage(String.join(
                    new List<String> {
                            'test: ',
                            asString(errorMessage),
                            ': Expected: ',
                            asString(expected),
                            ', Actual: ',
                            String.valueOf(actual)
                    },
                    ''
            )));
        }
    }

    /**
     * @description
     * Records a failure.
     *
     * @param errorMessage The error message to be recorded.
     */
    public static void fail(final String errorMessage) {
        throw new AssertionException(buildMessage(errorMessage));
    }

    private static String asString(final Object value) {
        return value == null ? 'null' : String.valueOf(value);
    }

    private static String buildMessage(final String errorMessage) {
        return String.join(new List<String> { 'Assertion failed: ', errorMessage }, '');
    }
}
