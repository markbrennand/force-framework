/**
 * @description
 * Unit tests for action binding.
 *
 * @author Mark Brennand
 */
@IsTest
public with sharing class ActionBindingTests {

    @TestSetup
    static void createUsers() {
        TestData.createUsers();
    }

    @IsTest
    static void testNonExistentBinding() {
        setup(true);
        System.runAs(TestData.getUser()) {
            try {
                Injection.wire(TestData.TestInterface.class, 'NotTest');
                Assert.fail();
            } catch (Injection.APIException ae) {
                Assert.areEqual('Binding for "TestData.TestInterface" with action "NotTest" not found in registry', ae.getMessage());
            }
        }
    }

    @IsTest
    static void testSingletonBinding() {
        setup(true);
        System.runAs(TestData.getUser()) {
            Assert.areEqual('INSTANCE1', ((TestData.TestInterface) Injection.wire(TestData.TestInterface.class, 'Test')).getValue());
            Assert.areEqual('INSTANCE1', ((TestData.TestInterface) Injection.wire(TestData.TestInterface.class, 'Test')).getValue());
            Assert.areEqual('INSTANCE2', ((TestData.TestInterface) Injection.wire(TestData.AbstractTest.class, 'Test')).getValue());
            Assert.areEqual('INSTANCE2', ((TestData.TestInterface) Injection.wire(TestData.AbstractTest.class, 'Test')).getValue());
        }
    }

    @IsTest
    static void testPrototypeBinding() {
        setup(false);
        System.runAs(TestData.getUser()) {
            Assert.areEqual('INSTANCE1', ((TestData.TestInterface) Injection.wire(TestData.TestInterface.class, 'Test')).getValue());
            Assert.areEqual('INSTANCE2', ((TestData.TestInterface) Injection.wire(TestData.TestInterface.class, 'Test')).getValue());
            Assert.areEqual('INSTANCE3', ((TestData.TestInterface) Injection.wire(TestData.AbstractTest.class, 'Test')).getValue());
            Assert.areEqual('INSTANCE4', ((TestData.TestInterface) Injection.wire(TestData.AbstractTest.class, 'Test')).getValue());
        }
    }

    @IsTest
    static void testIsBound() {
        setup(true);
        System.runAs(TestData.getUser()) {
            Assert.isTrue(Injection.has(TestData.TestInterface.class, 'Test'));
            Assert.isTrue(Injection.has(TestData.AbstractTest.class, 'Test'));
            Assert.isFalse(Injection.has(TestData.TestInterface.class, 'NotTest'));
            Assert.isFalse(Injection.has(TestData.TestInterface.class));
            Assert.isFalse(Injection.has(User.class, 'Test'));
        }
    }

    @IsTest
    static void testCustomSingletonBindings() {
        setup(true);
        System.runAs(TestData.getManager()) {
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
        }

        System.runAs(TestData.getUser()) {
            Assert.areEqual('CUSTOM1', ((TestData.TestInterface) Injection.wire(TestData.TestInterface.class, 'Test')).getValue());
            Assert.areEqual('CUSTOM1', ((TestData.TestInterface) Injection.wire(TestData.TestInterface.class, 'Test')).getValue());
            Assert.areEqual('CUSTOM2', ((TestData.TestInterface) Injection.wire(TestData.AbstractTest.class, 'Test')).getValue());
            Assert.areEqual('CUSTOM2', ((TestData.TestInterface) Injection.wire(TestData.AbstractTest.class, 'Test')).getValue());
        }
    }

    @IsTest
    static void testCustomPrototypeBindings() {
        setup(true);
        System.runAs(TestData.getManager()) {
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
        }

        System.runAs(TestData.getUser()) {
            Assert.areEqual('CUSTOM1', ((TestData.TestInterface) Injection.wire(TestData.TestInterface.class, 'Test')).getValue());
            Assert.areEqual('CUSTOM2', ((TestData.TestInterface) Injection.wire(TestData.TestInterface.class, 'Test')).getValue());
            Assert.areEqual('CUSTOM3', ((TestData.TestInterface) Injection.wire(TestData.AbstractTest.class, 'Test')).getValue());
            Assert.areEqual('CUSTOM4', ((TestData.TestInterface) Injection.wire(TestData.AbstractTest.class, 'Test')).getValue());
        }
    }

    private static void setup(Boolean singleton) {
        if (singleton) {
            Injection.add(TestData.TestInterface.class, 'Test', TestData.SingletonTest.class);
            Injection.add(TestData.AbstractTest.class, 'Test', TestData.SingletonTest.class);
        } else {
            Injection.add(TestData.TestInterface.class, 'Test', TestData.PrototypeTest.class);
            Injection.add(TestData.AbstractTest.class, 'Test', TestData.PrototypeTest.class);
        }

        TestData.SINGLETON_INSTANCE =
        TestData.PROTOTYPE_INSTANCE = 0;
    }
}