/**
 * MIT License
 *
 * Copyright (c) 2025 Mark Brennand
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */
/**
 * @description
 * Class providing programmatic Assertions.
 * <br><br>
 * The Salesforce Assert class is great, but it throws an Exception which cannot be caught. So, in reality, is only
 * useful for unit tests.
 * <br><br>
 * Ancestor methods should be able to catch assertion errors so they can be handled. For example, the Asynchronous
 * API must be able to catch any assertion failures during the processing of a job so it can record the caught
 * Exception. With the Salesforce assertion Exception, that is not possible.
 * <br><<br>
 * The APIs in the Force Framework all use this class to check assertions, allowing any Exception to be caught.
 *
 * @author Mark Brennand
 */
global with sharing class Assertion {

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

    /**
     * @description
     * Exception thrown when an assertion fails.
     */
    global with sharing class AssertionException extends Exception {}

    private static String asString(Object value) {
        return value == null ? 'null' : String.valueOf(value);
    }

    private static String buildMessage(final String errorMessage) {
        return String.join(new List<String> { 'Assertion failed: ', errorMessage }, '');
    }
}
