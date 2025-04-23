/**
 * @description
 * Unit tests for action binding.
 *
 * @author Mark Brennand
 */
@IsTest
public with sharing class ActionBindingTests {

    @IsTest
    static void testNonExistentBinding() {
        setup(true);
        try {
            Registry.wire(TestData.TestInterface.class, 'NotTest');
            Assert.fail();
        } catch(Registry.APIException ae) {
            Assert.areEqual('Binding for "TestData.TestInterface" for action "NotTest" not found in registry', ae.getMessage());
        }
    }

    @IsTest
    static void testSingletonBinding() {
        setup(true);
        Assert.areEqual('INSTANCE1', ((TestData.TestInterface) Registry.wire(TestData.TestInterface.class, 'Test')).getValue());
        Assert.areEqual('INSTANCE1', ((TestData.TestInterface) Registry.wire(TestData.TestInterface.class, 'Test')).getValue());
        Assert.areEqual('INSTANCE2', ((TestData.TestInterface) Registry.wire(TestData.AbstractTest.class, 'Test')).getValue());
        Assert.areEqual('INSTANCE2', ((TestData.TestInterface) Registry.wire(TestData.AbstractTest.class, 'Test')).getValue());
    }

    @IsTest
    static void testPrototypeBinding() {
        setup(false);
        Assert.areEqual('INSTANCE1', ((TestData.TestInterface) Registry.wire(TestData.TestInterface.class, 'Test')).getValue());
        Assert.areEqual('INSTANCE2', ((TestData.TestInterface) Registry.wire(TestData.TestInterface.class, 'Test')).getValue());
        Assert.areEqual('INSTANCE3', ((TestData.TestInterface) Registry.wire(TestData.AbstractTest.class, 'Test')).getValue());
        Assert.areEqual('INSTANCE4', ((TestData.TestInterface) Registry.wire(TestData.AbstractTest.class, 'Test')).getValue());
    }

    @IsTest
    static void testIsBound() {
        setup(true);
        Assert.isTrue(Registry.has(TestData.TestInterface.class,'Test'));
        Assert.isTrue(Registry.has(TestData.AbstractTest.class,'Test'));
        Assert.isFalse(Registry.has(TestData.TestInterface.class,'NotTest'));
        Assert.isFalse(Registry.has(TestData.TestInterface.class));
        Assert.isFalse(Registry.has(User.class,'Test'));
    }

    @IsTest
    static void testCustomSingletonBindings() {
        setup(true);

        insert new Binding__c(
                Type__c = TestData.TestInterface.class.getName(),
                Action__c = 'Test',
                Implementation__c = TestData.SingletonCustomTest.class.getName()
        );

        insert new Binding__c(
                Type__c = TestData.AbstractTest.class.getName(),
                Action__c = 'Test',
                Implementation__c = TestData.SingletonCustomTest.class.getName()
        );

        TestData.SINGLETON_INSTANCE =
        TestData.PROTOTYPE_INSTANCE = 0;

        // The first wire() call adds the 2 custom bindings, which will instantiate the implementation. Hence use
        // CUSTOM3 and CUSTOM4.
        Assert.areEqual('CUSTOM3', ((TestData.TestInterface) Registry.wire(TestData.TestInterface.class, 'Test')).getValue());
        Assert.areEqual('CUSTOM3', ((TestData.TestInterface) Registry.wire(TestData.TestInterface.class, 'Test')).getValue());
        Assert.areEqual('CUSTOM4', ((TestData.TestInterface) Registry.wire(TestData.AbstractTest.class, 'Test')).getValue());
        Assert.areEqual('CUSTOM4', ((TestData.TestInterface) Registry.wire(TestData.AbstractTest.class, 'Test')).getValue());
    }

    @IsTest
    static void testCustomPrototypeBindings() {
        setup(true);

        insert new Binding__c(
                Type__c = TestData.TestInterface.class.getName(),
                Action__c = 'Test',
                Implementation__c = TestData.PrototypeCustomTest.class.getName()
        );

        insert new Binding__c(
                Type__c = TestData.AbstractTest.class.getName(),
                Action__c = 'Test',
                Implementation__c = TestData.PrototypeCustomTest.class.getName()
        );

        TestData.SINGLETON_INSTANCE =
        TestData.PROTOTYPE_INSTANCE = 0;

        // The first wire() call adds the 2 custom bindings, which will instantiate the implementation. Hence use
        // CUSTOM3 onwards.
        Assert.areEqual('CUSTOM3', ((TestData.TestInterface) Registry.wire(TestData.TestInterface.class, 'Test')).getValue());
        Assert.areEqual('CUSTOM4', ((TestData.TestInterface) Registry.wire(TestData.TestInterface.class, 'Test')).getValue());
        Assert.areEqual('CUSTOM5', ((TestData.TestInterface) Registry.wire(TestData.AbstractTest.class, 'Test')).getValue());
        Assert.areEqual('CUSTOM6', ((TestData.TestInterface) Registry.wire(TestData.AbstractTest.class, 'Test')).getValue());
    }

    private static void setup(Boolean singleton) {
        if (singleton) {
            Registry.add(TestData.TestInterface.class, 'Test', TestData.SingletonTest.class);
            Registry.add(TestData.AbstractTest.class, 'Test', TestData.SingletonTest.class);
        } else {
            Registry.add(TestData.TestInterface.class, 'Test', TestData.PrototypeTest.class);
            Registry.add(TestData.AbstractTest.class, 'Test', TestData.PrototypeTest.class);
        }

        TestData.SINGLETON_INSTANCE =
        TestData.PROTOTYPE_INSTANCE = 0;
    }
}