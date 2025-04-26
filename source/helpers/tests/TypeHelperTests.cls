/**
 * @description
 * Unit tests for type helper methods.
 *
 * @author Mark Brennand
 */
@IsTest
public with sharing class TypeHelperTests {

    @IsTest
    static void testLoadValidClass() {
        Type t = TypeHelper.loadType('Integer');
        Assert.areEqual('Integer', t.getName());
    }

    @IsTest
    static void testLoadNonExistentClass() {
        try {
            Type t = TypeHelper.loadType('TypeHelperTests.NoSuchClass');
        } catch(TypeHelper.TypeException te) {
            Assert.areEqual('Type "TypeHelperTests.NoSuchClass" does not exist', te.getMessage());
        }
    }

    @IsTest
    static void testNewInstanceOfValidClass() {
        Object instance = TypeHelper.newInstance(TestClass.class);
        Assert.isTrue(instance instanceof TestClass);
    }

    @IsTest
    static void testNewInstanceOfInvalidClasses() {
        try {
            TypeHelper.newInstance(Integer.class);
            Assert.fail();
        } catch(TypeHelper.TypeException te) {
            Assert.areEqual('Type "Integer" could not be constructed', te.getMessage());
        }

        try {
            TypeHelper.newInstance(TestInterface.class);
            Assert.fail();
        } catch(TypeHelper.TypeException te) {
            Assert.areEqual('Type "TypeHelperTests.TestInterface" could not be constructed', te.getMessage());
        }

        try {
            TypeHelper.newInstance(AbstractTestClass.class);
            Assert.fail();
        } catch(TypeHelper.TypeException te) {
            Assert.areEqual('Type "TypeHelperTests.AbstractTestClass" could not be constructed', te.getMessage());
        }
    }

    @IsTest
    static void testFactory() {
        Assert.isTrue(TypeHelper.newInstance(TestFactory.class) instanceof TestClass);
    }

    public interface TestInterface {}

    public with sharing class TestClass {}

    public with sharing abstract class AbstractTestClass {}

    public with sharing class TestFactory implements TypeHelper.Factory {

        public Object newInstance() {
            return new TestClass();
        }
    }
}