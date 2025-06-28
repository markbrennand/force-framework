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
 * Unit tests for Assertions.
 *
 * @author Mark Brennand
 */
@IsTest
public with sharing class AssertionTests {

    @IsTest
    private static void testIsNotNull() {
        Assertion.isNotNull(1, 'Should pass');

        try {
            Assertion.isNotNull(null, 'Should fail');
        } catch(Assertion.AssertionException ae) {
            Assert.isTrue(ae.getMessage().contains('Should fail'));
        }
    }

    @IsTest
    private static void testIsTrue() {
        Assertion.isTrue(true, 'Should pass');

        try {
            Assertion.isTrue(false, 'Should fail');
        } catch(Assertion.AssertionException ae) {
            Assert.isTrue(ae.getMessage().contains('Should fail'));
        }
    }


    @IsTest
    private static void testAreEqual() {
        Assertion.areEqual(true, true, 'Should pass');

        try {
            Assertion.areEqual(true, false, 'Should fail');
        } catch(Assertion.AssertionException ae) {
            Assert.isTrue(ae.getMessage().contains('Should fail'));
            Assert.isTrue(ae.getMessage().contains('true'));
            Assert.isTrue(ae.getMessage().contains('false'));
        }
    }

    @IsTest
    private static void testFail() {
        try {
            Assertion.fail('Should fail');
        } catch(Assertion.AssertionException ae) {
            Assert.isTrue(ae.getMessage().contains('Should fail'));
        }
    }
}
