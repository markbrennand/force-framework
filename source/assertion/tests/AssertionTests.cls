/**
 * @description
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../LICENSE target="_blank">MIT License</a>.
 * <br><br>
 * Unit tests for Assertions.
 *
 * @author Mark Brennand
 */
@IsTest
@SuppressWarnings('PMD')
public with sharing class AssertionTests {
    private final static String TESTING = 'assertion';

    @TestSetup
    private static void createUsers() {
        TestHelper.createUsers(TESTING, new Set<String>());
    }

    @IsTest
    private static void testIsNotNull() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            AssertionV1.isNotNull(1, 'Should pass');

            try {
                AssertionV1.isNotNull(null, 'Should fail');
            } catch(AssertionV1.AssertionException ae) {
                Assert.isTrue(ae.getMessage().contains('Should fail'));
            }
        }
    }

    @IsTest
    private static void testIsTrue() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            AssertionV1.isTrue(true, 'Should pass');

            try {
                AssertionV1.isTrue(false, 'Should fail');
            } catch(AssertionV1.AssertionException ae) {
                Assert.isTrue(ae.getMessage().contains('Should fail'));
            }
        }
    }


    @IsTest
    private static void testAreEqual() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            AssertionV1.areEqual(true, true, 'Should pass');

            try {
                AssertionV1.areEqual(true, false, 'Should fail');
            } catch(AssertionV1.AssertionException ae) {
                Assert.isTrue(ae.getMessage().contains('Should fail'));
                Assert.isTrue(ae.getMessage().contains('true'));
                Assert.isTrue(ae.getMessage().contains('false'));
            }
        }
    }

    @IsTest
    private static void testFail() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            try {
                AssertionV1.fail('Should fail');
            } catch(AssertionV1.AssertionException ae) {
                Assert.isTrue(ae.getMessage().contains('Should fail'));
            }
        }
    }
}