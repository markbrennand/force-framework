/**
 * @description
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../../LICENSE target="_blank">MIT License</a>.
 * <br><br>
 * Unit tests for TypesV1 class.
 *
 * @author Mark Brennand
 */
@IsTest
public with sharing class TypesTests {

    @IsTest
    static void testLoadValidClass() {
        Type t = TypesV1.load('Integer');
        Assert.areEqual('Integer', t.getName());
    }

    @IsTest
    static void testLoadNonExistentClass() {
        try {
            Type t = TypesV1.load('TypeHelperTests.NoSuchClass');
            Assert.fail();
        } catch(TypesV1.APIException te) {
            Assert.areEqual('Class TypeHelperTests.NoSuchClass does not exist', te.getMessage());
        }
    }

    @IsTest
    static void testNewInstanceOfValidClass() {
        Object instance = TypesV1.newInstance(TestClass.class);
        Assert.isTrue(instance instanceof TestClass);
    }

    @IsTest
    static void testNewInstanceOfInvalidClasses() {
        try {
            TypesV1.newInstance(Integer.class);
            Assert.fail();
        } catch(TypesV1.APIException te) {
            Assert.isTrue(te.getMessage().endsWith('Integer could not be constructed'));
        }

        try {
            TypesV1.newInstance(TestInterface.class);
            Assert.fail();
        } catch(TypesV1.APIException te) {
            Assert.isTrue(te.getMessage().endsWith('TypesTests.TestInterface could not be constructed'));
        }

        try {
            TypesV1.newInstance(AbstractTestClass.class);
            Assert.fail();
        } catch(TypesV1.APIException te) {
            Assert.isTrue(te.getMessage().endsWith('TypesTests.AbstractTestClass could not be constructed'));
        }
    }

    @IsTest
    static void testFactory() {
        Assert.isTrue(TypesV1.newInstance(TestFactory.class) instanceof TestClass);
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