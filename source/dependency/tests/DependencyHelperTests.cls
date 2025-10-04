/**
 * @description
 * <p>
 * Unit tests for DependencyHelper class.
 * <p>
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../LICENSE target="_blank">MIT License</a>.
 *
 * @author Mark Brennand
 */
@IsTest
@SuppressWarnings('PMD')
public with sharing class DependencyHelperTests {
    private final static String TESTING = 'helpers';

    @TestSetup
    private static void createUsers() {
        TestHelper.createUsers(TESTING, new Set<String>());
    }

    @IsTest
    private static void testAll() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            Type t1 = Integer.class;
            Object o1 = 12;

            Type t2 = Double.class;
            Object o2 = (Double) 1.23;

            Type t3 = DependencyV1.Prototype.class;

            DependencyAPI.ValidationResultImpl r1 = (DependencyAPI.ValidationResultImpl) DependencyHelper.buildValidationResult(
                    o1 instanceof Integer,
                    false,
                    t1,
                    t1
            );

            Assert.isTrue(r1.isValid());
            Assert.isNull(r1.getErrorMessage());

            DependencyAPI.ValidationResultImpl r2 = (DependencyAPI.ValidationResultImpl) DependencyHelper.buildValidationResult(
                    o2 instanceof Integer,
                    false,
                    t1,
                    t2
            );

            Assert.isFalse(r2.isValid());
            Assert.areEqual('Class Double does not extend Integer', r2.getErrorMessage());

            DependencyAPI.ValidationResultImpl r3 = (DependencyAPI.ValidationResultImpl) DependencyHelper.buildValidationResult(
                    o2 instanceof DependencyV1.Prototype,
                    true,
                    t3,
                    t2
            );

            Assert.isFalse(r3.isValid());
            Assert.isTrue(TestHelper.textContains('Class Double does not implement DependencyV1.Prototype', r3.getErrorMessage()));
        }
    }
}