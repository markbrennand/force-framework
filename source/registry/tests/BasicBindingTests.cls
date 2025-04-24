/**
 * @description
 * Unit tests for basic binding.
 *
 * @author Mark Brennand
 */
@IsTest
public with sharing class BasicBindingTests {

    @TestSetup
    static void createUsers() {
        TestData.createUsers();
    }

    @IsTest
    static void testNonExistentBinding() {
        System.runAs(TestData.getUser()) {
            try {
                Registry.wire(TestData.TestInterface.class);
                Assert.fail();
            } catch (Registry.APIException ae) {
                Assert.areEqual('Binding for "TestData.TestInterface" not found in registry', ae.getMessage());
            }
        }
    }

    @IsTest
    static void testSingletonBinding() {
        setup(true);
        System.runAs(TestData.getUser()) {
            Assert.areEqual('INSTANCE1', ((TestData.TestInterface) Registry.wire(TestData.TestInterface.class)).getValue());
            Assert.areEqual('INSTANCE1', ((TestData.TestInterface) Registry.wire(TestData.TestInterface.class)).getValue());
            Assert.areEqual('INSTANCE2', ((TestData.TestInterface) Registry.wire(TestData.AbstractTest.class)).getValue());
            Assert.areEqual('INSTANCE2', ((TestData.TestInterface) Registry.wire(TestData.AbstractTest.class)).getValue());
        }
    }

    @IsTest
    static void testPrototypeBinding() {
        setup(false);
        System.runAs(TestData.getUser()) {
            Assert.areEqual('INSTANCE1', ((TestData.TestInterface) Registry.wire(TestData.TestInterface.class)).getValue());
            Assert.areEqual('INSTANCE2', ((TestData.TestInterface) Registry.wire(TestData.TestInterface.class)).getValue());
            Assert.areEqual('INSTANCE3', ((TestData.TestInterface) Registry.wire(TestData.AbstractTest.class)).getValue());
            Assert.areEqual('INSTANCE4', ((TestData.TestInterface) Registry.wire(TestData.AbstractTest.class)).getValue());
        }
    }

    @IsTest
    static void testIsBound() {
        setup(true);
        System.runAs(TestData.getUser()) {
            Assert.isTrue(Registry.has(TestData.TestInterface.class));
            Assert.isTrue(Registry.has(TestData.AbstractTest.class));
            Assert.isFalse(Registry.has(TestData.TestInterface.class, 'Test'));
            Assert.isFalse(Registry.has(User.class));
        }
    }

    @IsTest
    static void testCustomSingletonBindings() {
        setup(true);
        System.runAs(TestData.getManager()) {
            insert new Binding__c(
                    Type__c = TestData.TestInterface.class.getName(),
                    Implementation__c = TestData.SingletonCustomTest.class.getName()
            );

            insert new Binding__c(
                    Type__c = TestData.AbstractTest.class.getName(),
                    Implementation__c = TestData.SingletonCustomTest.class.getName()
            );
        }

        TestData.SINGLETON_INSTANCE =
        TestData.PROTOTYPE_INSTANCE = 0;

        // The first wire() call adds the 2 custom bindings, which will instantiate the implementation. Hence use
        // CUSTOM3 and CUSTOM4.
        System.runAs(TestData.getUser()) {
            Assert.areEqual('CUSTOM3', ((TestData.TestInterface) Registry.wire(TestData.TestInterface.class)).getValue());
            Assert.areEqual('CUSTOM3', ((TestData.TestInterface) Registry.wire(TestData.TestInterface.class)).getValue());
            Assert.areEqual('CUSTOM4', ((TestData.TestInterface) Registry.wire(TestData.AbstractTest.class)).getValue());
            Assert.areEqual('CUSTOM4', ((TestData.TestInterface) Registry.wire(TestData.AbstractTest.class)).getValue());
        }
    }

    @IsTest
    static void testCustomPrototypeBindings() {
        setup(true);
        System.runAs(TestData.getManager()) {
            insert new Binding__c(
                    Type__c = TestData.TestInterface.class.getName(),
                    Implementation__c = TestData.PrototypeCustomTest.class.getName()
            );

            insert new Binding__c(
                    Type__c = TestData.AbstractTest.class.getName(),
                    Implementation__c = TestData.PrototypeCustomTest.class.getName()
            );
        }

        TestData.SINGLETON_INSTANCE =
        TestData.PROTOTYPE_INSTANCE = 0;

        // The first wire() call adds the 2 custom bindings, which will instantiate the implementation. Hence use
        // CUSTOM3 onwards.
        System.runAs(TestData.getUser()) {
            Assert.areEqual('CUSTOM3', ((TestData.TestInterface) Registry.wire(TestData.TestInterface.class)).getValue());
            Assert.areEqual('CUSTOM4', ((TestData.TestInterface) Registry.wire(TestData.TestInterface.class)).getValue());
            Assert.areEqual('CUSTOM5', ((TestData.TestInterface) Registry.wire(TestData.AbstractTest.class)).getValue());
            Assert.areEqual('CUSTOM6', ((TestData.TestInterface) Registry.wire(TestData.AbstractTest.class)).getValue());
        }
    }

    private static void setup(Boolean singleton) {
        if (singleton) {
            Registry.add(TestData.TestInterface.class, TestData.SingletonTest.class);
            Registry.add(TestData.AbstractTest.class, TestData.SingletonTest.class);
        } else {
            Registry.add(TestData.TestInterface.class, TestData.PrototypeTest.class);
            Registry.add(TestData.AbstractTest.class, TestData.PrototypeTest.class);
        }

        TestData.SINGLETON_INSTANCE =
        TestData.PROTOTYPE_INSTANCE = 0;
    }
}