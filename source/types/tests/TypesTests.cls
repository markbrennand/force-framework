/**
 * @description
 * <p/>
 * Unit tests for TypesV1 class.
 * <p/>
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../LICENSE target="_blank">MIT License</a>.
 *
 * @author Mark Brennand
 */
@IsTest
@SuppressWarnings('PMD')
public with sharing class TypesTests {
    private final static String TESTING = 'types';

    @TestSetup
    private static void createUsers() {
        TestHelper.createUsers(TESTING, new Set<String> { 'ForceFwDependencyInjectionPermissions' });
    }

    @IsTest
    private static void testLoadValidClass() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            Type t = TypesV1.load('Integer');
            Assert.areEqual('Integer', t.getName());
        }
    }

    @IsTest
    private static void testLoadNonExistentClass() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            try {
                TypesV1.load('TypeHelperTests.NoSuchClass');
                Assert.fail();
            } catch (TypesV1.APIException te) {
                Assert.areEqual('Class TypeHelperTests.NoSuchClass does not exist', te.getMessage());
            }
        }
    }

    @IsTest
    private static void testNewInstanceOfValidClass() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            Object instance = TypesV1.newInstance(TestClass.class);
            Assert.isTrue(instance instanceof TestClass);
        }
    }

    @IsTest
    private static void testNewInstanceOfInvalidClasses() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            try {
                TypesV1.newInstance(Integer.class);
                Assert.fail();
            } catch (TypesV1.APIException te) {
                Assert.isTrue(te.getMessage().endsWith('Integer could not be constructed'));
            }

            try {
                TypesV1.newInstance(TestInterface.class);
                Assert.fail();
            } catch (TypesV1.APIException te) {
                Assert.isTrue(te.getMessage().endsWith('TypesTests.TestInterface could not be constructed'));
            }

            try {
                TypesV1.newInstance(AbstractTestClass.class);
                Assert.fail();
            } catch (TypesV1.APIException te) {
                Assert.isTrue(te.getMessage().endsWith('TypesTests.AbstractTestClass could not be constructed'));
            }
        }
    }

    @IsTest
    private static void testFactory() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            Assert.isTrue(TypesV1.newInstance(TestFactory.class) instanceof TestClass);
        }
    }

    public interface TestInterface {}

    public with sharing class TestClass {}

    public with sharing abstract class AbstractTestClass {}

    public with sharing class TestFactory implements TypesV1.Factory {
        public Object newInstance() {
            return new TestClass();
        }
    }
}