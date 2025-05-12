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
    static void testInstantiation() {
        System.runAs(TestData.getManager()) {
            TestData.testBindingFailure(TestData.SingletonTest.class, null, TestData.SingletonTest.class, 'Class TestData.SingletonTest must not be instantiable');
            TestData.testBindingFailure(TestData.TestInterface.class, null, TestData.AbstractTest.class, 'Implementation TestData.AbstractTest must be instantiable');
            Injection.add(TestData.TestInterface.class, TestData.SingletonTest.class);
            Injection.add(TestData.AbstractTest.class, TestData.SingletonTest.class);
            insert new Binding__c(Type__c = TestData.TestInterface.class.getName(), Implementation__c = TestData.SingletonTest.class.getName());
            insert new Binding__c(Type__c = TestData.AbstractTest.class.getName(), Implementation__c = TestData.SingletonTest.class.getName());
        }
    }

    @IsTest
    static void testValidation() {
        System.runAs(TestData.getManager()) {
            TestData.testBindingFailure(TestData.TestInterface.class, null, User.class, 'Class User does not implement TestInterface');
            TestData.testBindingFailure(TestData.AbstractTest.class, null, User.class, 'Class User does not extend AbstractTest');
            Injection.add(TestData.TestInterface.class, TestData.SingletonTest.class);
            Injection.add(TestData.AbstractTest.class, TestData.SingletonTest.class);
            insert new Binding__c(Type__c = TestData.TestInterface.class.getName(), Implementation__c = TestData.SingletonTest.class.getName());
            insert new Binding__c(Type__c = TestData.AbstractTest.class.getName(), Implementation__c = TestData.SingletonTest.class.getName());
        }
    }

    @IsTest
    static void testPropertyBinding() {
        System.runAs(TestData.getManager()) {
            TestData.testBindingFailure(Map<String, Integer>.class, null, TestData.MapFactory.class, 'Class Map<String,Integer> must not be instantiable');
        }
    }

    @IsTest
    static void testNonExistentBinding() {
        System.runAs(TestData.getUser()) {
            try {
                Injection.wire(TestData.TestInterface.class);
                Assert.fail();
            } catch (Injection.APIException ae) {
                Assert.areEqual('Binding for TestData.TestInterface not found in registry', ae.getMessage());
            }
        }
    }

    @IsTest
    static void testSingletonBinding() {
        setup(true);
        System.runAs(TestData.getUser()) {
            Assert.areEqual('INSTANCE1', ((TestData.TestInterface) Injection.wire(TestData.TestInterface.class)).getValue());
            Assert.areEqual('INSTANCE1', ((TestData.TestInterface) Injection.wire(TestData.TestInterface.class)).getValue());
            Assert.areEqual('INSTANCE2', ((TestData.TestInterface) Injection.wire(TestData.AbstractTest.class)).getValue());
            Assert.areEqual('INSTANCE2', ((TestData.TestInterface) Injection.wire(TestData.AbstractTest.class)).getValue());
        }
    }

    @IsTest
    static void testPrototypeBinding() {
        setup(false);
        System.runAs(TestData.getUser()) {
            Assert.areEqual('INSTANCE1', ((TestData.TestInterface) Injection.wire(TestData.TestInterface.class)).getValue());
            Assert.areEqual('INSTANCE2', ((TestData.TestInterface) Injection.wire(TestData.TestInterface.class)).getValue());
            Assert.areEqual('INSTANCE3', ((TestData.TestInterface) Injection.wire(TestData.AbstractTest.class)).getValue());
            Assert.areEqual('INSTANCE4', ((TestData.TestInterface) Injection.wire(TestData.AbstractTest.class)).getValue());
        }
    }

    @IsTest
    static void testIsBound() {
        setup(true);
        System.runAs(TestData.getUser()) {
            Assert.isTrue(Injection.has(TestData.TestInterface.class));
            Assert.isTrue(Injection.has(TestData.AbstractTest.class));
            Assert.isFalse(Injection.has(TestData.TestInterface.class, 'Test'));
            Assert.isFalse(Injection.has(User.class));
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
            Assert.areEqual('CUSTOM1', ((TestData.TestInterface) Injection.wire(TestData.TestInterface.class)).getValue());
            Assert.areEqual('CUSTOM1', ((TestData.TestInterface) Injection.wire(TestData.TestInterface.class)).getValue());
            Assert.areEqual('CUSTOM2', ((TestData.TestInterface) Injection.wire(TestData.AbstractTest.class)).getValue());
            Assert.areEqual('CUSTOM2', ((TestData.TestInterface) Injection.wire(TestData.AbstractTest.class)).getValue());
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

        System.runAs(TestData.getUser()) {
            Assert.areEqual('CUSTOM1', ((TestData.TestInterface) Injection.wire(TestData.TestInterface.class)).getValue());
            Assert.areEqual('CUSTOM2', ((TestData.TestInterface) Injection.wire(TestData.TestInterface.class)).getValue());
            Assert.areEqual('CUSTOM3', ((TestData.TestInterface) Injection.wire(TestData.AbstractTest.class)).getValue());
            Assert.areEqual('CUSTOM4', ((TestData.TestInterface) Injection.wire(TestData.AbstractTest.class)).getValue());
        }
    }

    private static void setup(Boolean singleton) {
        System.runAs(TestData.getManager()) {
            if (singleton) {
                Injection.add(TestData.TestInterface.class, TestData.SingletonTest.class);
                Injection.add(TestData.AbstractTest.class, TestData.SingletonTest.class);
            } else {
                Injection.add(TestData.TestInterface.class, TestData.PrototypeTest.class);
                Injection.add(TestData.AbstractTest.class, TestData.PrototypeTest.class);
            }

            TestData.SINGLETON_INSTANCE =
                    TestData.PROTOTYPE_INSTANCE = 0;
        }
    }
}