/**
 * @description
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../../LICENSE target="_blank">MIT License</a>.
 * <br><br>
 * Unit tests for Assertions.
 *
 * @author Mark Brennand
 */
@IsTest
public with sharing class AssertionTests {

    @IsTest
    private static void testIsNotNull() {
        TestHelper.setNOW();
        Assertion.isNotNull(1, 'Should pass');

        try {
            Assertion.isNotNull(null, 'Should fail');
        } catch(Assertion.AssertionException ae) {
            Assert.isTrue(ae.getMessage().contains('Should fail'));
        }
    }

    @IsTest
    private static void testIsTrue() {
        TestHelper.setNOW();
        Assertion.isTrue(true, 'Should pass');

        try {
            Assertion.isTrue(false, 'Should fail');
        } catch(Assertion.AssertionException ae) {
            Assert.isTrue(ae.getMessage().contains('Should fail'));
        }
    }


    @IsTest
    private static void testAreEqual() {
        TestHelper.setNOW();
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
        TestHelper.setNOW();
        try {
            Assertion.fail('Should fail');
        } catch(Assertion.AssertionException ae) {
            Assert.isTrue(ae.getMessage().contains('Should fail'));
        }
    }
}