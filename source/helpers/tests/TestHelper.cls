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
 * Common test data and methods for all unit tests.
 *
 * @author Mark Brennand
 */
@IsTest
public with sharing class TestHelper {
    private final static String NAMESPACE = [SELECT NamespacePrefix FROM Organization LIMIT 1].NamespacePrefix;

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