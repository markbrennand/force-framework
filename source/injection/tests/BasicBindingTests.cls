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
        BindingTestHelper.createUsers();
    }

    @IsTest
    static void testInstantiation() {
        System.runAs(BindingTestHelper.getManager()) {
            BindingTestHelper.testBindingFailure(BindingTestHelper.SingletonTest.class, null, BindingTestHelper.SingletonTest.class, 'Class BindingTestHelper.SingletonTest must not be instantiable');
            BindingTestHelper.testBindingFailure(BindingTestHelper.TestInterface.class, null, BindingTestHelper.AbstractTest.class, 'Implementation BindingTestHelper.AbstractTest must be instantiable');
            Injection.add(BindingTestHelper.TestInterface.class, BindingTestHelper.SingletonTest.class);
            Injection.add(BindingTestHelper.AbstractTest.class, BindingTestHelper.SingletonTest.class);
            insert new Binding__c(Type__c = BindingTestHelper.TestInterface.class.getName(), Implementation__c = BindingTestHelper.SingletonTest.class.getName());
            insert new Binding__c(Type__c = BindingTestHelper.AbstractTest.class.getName(), Implementation__c = BindingTestHelper.SingletonTest.class.getName());
        }
    }

    @IsTest
    static void testValidation() {
        System.runAs(BindingTestHelper.getManager()) {
            BindingTestHelper.testBindingFailure(BindingTestHelper.TestInterface.class, null, User.class, 'Class User does not implement TestInterface');
            BindingTestHelper.testBindingFailure(BindingTestHelper.AbstractTest.class, null, User.class, 'Class User does not extend AbstractTest');
            Injection.add(BindingTestHelper.TestInterface.class, BindingTestHelper.SingletonTest.class);
            Injection.add(BindingTestHelper.AbstractTest.class, BindingTestHelper.SingletonTest.class);
            insert new Binding__c(Type__c = BindingTestHelper.TestInterface.class.getName(), Implementation__c = BindingTestHelper.SingletonTest.class.getName());
            insert new Binding__c(Type__c = BindingTestHelper.AbstractTest.class.getName(), Implementation__c = BindingTestHelper.SingletonTest.class.getName());
        }
    }

    @IsTest
    static void testPropertyBinding() {
        System.runAs(BindingTestHelper.getManager()) {
            BindingTestHelper.testBindingFailure(Map<String, Integer>.class, null, BindingTestHelper.MapFactory.class, 'Class Map<String,Integer> must not be instantiable');
        }
    }

    @IsTest
    static void testNonExistentBinding() {
        System.runAs(BindingTestHelper.getUser()) {
            try {
                Injection.wire(BindingTestHelper.TestInterface.class);
                Assert.fail();
            } catch (Injection.APIException ae) {
                Assert.areEqual('Binding for BindingTestHelper.TestInterface not found in registry', ae.getMessage());
            }
        }
    }

    @IsTest
    static void testSingletonBinding() {
        setup(true);
        System.runAs(BindingTestHelper.getUser()) {
            Assert.areEqual('INSTANCE1', ((BindingTestHelper.TestInterface) Injection.wire(BindingTestHelper.TestInterface.class)).getValue());
            Assert.areEqual('INSTANCE1', ((BindingTestHelper.TestInterface) Injection.wire(BindingTestHelper.TestInterface.class)).getValue());
            Assert.areEqual('INSTANCE2', ((BindingTestHelper.TestInterface) Injection.wire(BindingTestHelper.AbstractTest.class)).getValue());
            Assert.areEqual('INSTANCE2', ((BindingTestHelper.TestInterface) Injection.wire(BindingTestHelper.AbstractTest.class)).getValue());
        }
    }

    @IsTest
    static void testPrototypeBinding() {
        setup(false);
        System.runAs(BindingTestHelper.getUser()) {
            Assert.areEqual('INSTANCE1', ((BindingTestHelper.TestInterface) Injection.wire(BindingTestHelper.TestInterface.class)).getValue());
            Assert.areEqual('INSTANCE2', ((BindingTestHelper.TestInterface) Injection.wire(BindingTestHelper.TestInterface.class)).getValue());
            Assert.areEqual('INSTANCE3', ((BindingTestHelper.TestInterface) Injection.wire(BindingTestHelper.AbstractTest.class)).getValue());
            Assert.areEqual('INSTANCE4', ((BindingTestHelper.TestInterface) Injection.wire(BindingTestHelper.AbstractTest.class)).getValue());
        }
    }

    @IsTest
    static void testIsBound() {
        setup(true);
        System.runAs(BindingTestHelper.getUser()) {
            Assert.isTrue(Injection.has(BindingTestHelper.TestInterface.class));
            Assert.isTrue(Injection.has(BindingTestHelper.AbstractTest.class));
            Assert.isFalse(Injection.has(BindingTestHelper.TestInterface.class, 'Test'));
            Assert.isFalse(Injection.has(User.class));
        }
    }

    @IsTest
    static void testCustomSingletonBindings() {
        setup(true);
        System.runAs(BindingTestHelper.getManager()) {
            insert new Binding__c(
                    Type__c = BindingTestHelper.TestInterface.class.getName(),
                    Implementation__c = BindingTestHelper.SingletonCustomTest.class.getName()
            );

            insert new Binding__c(
                    Type__c = BindingTestHelper.AbstractTest.class.getName(),
                    Implementation__c = BindingTestHelper.SingletonCustomTest.class.getName()
            );
        }

        BindingTestHelper.SINGLETON_INSTANCE =
        BindingTestHelper.PROTOTYPE_INSTANCE = 0;

        // The first wire() call adds the 2 custom bindings, which will instantiate the implementation. Hence use
        // CUSTOM3 and CUSTOM4.
        System.runAs(BindingTestHelper.getUser()) {
            Assert.areEqual('CUSTOM1', ((BindingTestHelper.TestInterface) Injection.wire(BindingTestHelper.TestInterface.class)).getValue());
            Assert.areEqual('CUSTOM1', ((BindingTestHelper.TestInterface) Injection.wire(BindingTestHelper.TestInterface.class)).getValue());
            Assert.areEqual('CUSTOM2', ((BindingTestHelper.TestInterface) Injection.wire(BindingTestHelper.AbstractTest.class)).getValue());
            Assert.areEqual('CUSTOM2', ((BindingTestHelper.TestInterface) Injection.wire(BindingTestHelper.AbstractTest.class)).getValue());
        }
    }

    @IsTest
    static void testCustomPrototypeBindings() {
        setup(true);
        System.runAs(BindingTestHelper.getManager()) {
            insert new Binding__c(
                    Type__c = BindingTestHelper.TestInterface.class.getName(),
                    Implementation__c = BindingTestHelper.PrototypeCustomTest.class.getName()
            );

            insert new Binding__c(
                    Type__c = BindingTestHelper.AbstractTest.class.getName(),
                    Implementation__c = BindingTestHelper.PrototypeCustomTest.class.getName()
            );
        }

        System.runAs(BindingTestHelper.getUser()) {
            Assert.areEqual('CUSTOM1', ((BindingTestHelper.TestInterface) Injection.wire(BindingTestHelper.TestInterface.class)).getValue());
            Assert.areEqual('CUSTOM2', ((BindingTestHelper.TestInterface) Injection.wire(BindingTestHelper.TestInterface.class)).getValue());
            Assert.areEqual('CUSTOM3', ((BindingTestHelper.TestInterface) Injection.wire(BindingTestHelper.AbstractTest.class)).getValue());
            Assert.areEqual('CUSTOM4', ((BindingTestHelper.TestInterface) Injection.wire(BindingTestHelper.AbstractTest.class)).getValue());
        }
    }

    private static void setup(Boolean singleton) {
        System.runAs(BindingTestHelper.getManager()) {
            if (singleton) {
                Injection.add(BindingTestHelper.TestInterface.class, BindingTestHelper.SingletonTest.class);
                Injection.add(BindingTestHelper.AbstractTest.class, BindingTestHelper.SingletonTest.class);
            } else {
                Injection.add(BindingTestHelper.TestInterface.class, BindingTestHelper.PrototypeTest.class);
                Injection.add(BindingTestHelper.AbstractTest.class, BindingTestHelper.PrototypeTest.class);
            }

            BindingTestHelper.SINGLETON_INSTANCE =
                    BindingTestHelper.PROTOTYPE_INSTANCE = 0;
        }
    }
}