/**
 * @description
 * Unit tests for Types class.
 *
 * @author Mark Brennand
 */
@IsTest
public with sharing class TypesTests {

    @IsTest
    static void testLoadValidClass() {
        Type t = Types.load('Integer');
        Assert.areEqual('Integer', t.getName());
    }

    @IsTest
    static void testLoadNonExistentClass() {
        try {
            Type t = Types.load('TypeHelperTests.NoSuchClass');
            Assert.fail();
        } catch(Types.TypeException te) {
            Assert.areEqual('Class TypeHelperTests.NoSuchClass does not exist', te.getMessage());
        }
    }

    @IsTest
    static void testNewInstanceOfValidClass() {
        Object instance = Types.newInstance(TestClass.class);
        Assert.isTrue(instance instanceof TestClass);
    }

    @IsTest
    static void testNewInstanceOfInvalidClasses() {
        try {
            Types.newInstance(Integer.class);
            Assert.fail();
        } catch(Types.TypeException te) {
            Assert.isTrue(te.getMessage().endsWith('Integer could not be constructed'));
        }

        try {
            Types.newInstance(TestInterface.class);
            Assert.fail();
        } catch(Types.TypeException te) {
            Assert.isTrue(te.getMessage().endsWith('TypesTests.TestInterface could not be constructed'));
        }

        try {
            Types.newInstance(AbstractTestClass.class);
            Assert.fail();
        } catch(Types.TypeException te) {
            Assert.isTrue(te.getMessage().endsWith('TypesTests.AbstractTestClass could not be constructed'));
        }
    }

    @IsTest
    static void testFactory() {
        Assert.isTrue(Types.newInstance(TestFactory.class) instanceof TestClass);
    }

    public interface TestInterface {}

    public with sharing class TestClass {}

    public with sharing abstract class AbstractTestClass {}

    public with sharing class TestFactory implements Types.Factory {

        public Object newInstance() {
            return new TestClass();
        }
    }
}