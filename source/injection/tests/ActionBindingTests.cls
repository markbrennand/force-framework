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
        BindingTestHelper.createUsers();
    }

    @IsTest
    static void testInstantiation() {
        System.runAs(BindingTestHelper.getManager()) {
            BindingTestHelper.testBindingFailure(BindingTestHelper.TestInterface.class, 'Test', BindingTestHelper.AbstractTest.class, 'Implementation BindingTestHelper.AbstractTest must be instantiable');
            Injection.add(BindingTestHelper.TestInterface.class, 'Test', BindingTestHelper.SingletonTest.class);
            Injection.add(BindingTestHelper.AbstractTest.class, 'Test', BindingTestHelper.SingletonTest.class);
            Injection.add(Integer.class, 'Test', BindingTestHelper.IntegerFactory.class);
            Injection.add(Map<String, Integer>.class, 'Test', BindingTestHelper.MapFactory.class);
            insert new Binding__c(Type__c = Integer.class.getName(), Action__c = 'Test', Implementation__c = BindingTestHelper.IntegerFactory.class.getName());
            insert new Binding__c(Type__c = (Map<String, Integer>.class).getName(), Action__c = 'Test', Implementation__c = BindingTestHelper.MapFactory.class.getName());
        }
    }

    @IsTest
    static void testValidation() {
        System.runAs(BindingTestHelper.getManager()) {
            BindingTestHelper.testBindingFailure(BindingTestHelper.TestInterface.class, 'Test', User.class, 'Class User does not implement TestInterface');
            BindingTestHelper.testBindingFailure(BindingTestHelper.AbstractTest.class, 'Test', User.class, 'Class User does not extend AbstractTest');
            BindingTestHelper.testBindingFailure(Integer.class, 'Test', User.class, 'Implementation User is not a super class of Integer');
            BindingTestHelper.testBindingFailure(Map<String, Integer>.class, 'Test', Map<String, Double>.class, 'Implementation Map<String,Double> is not a super class of Map<String,Integer>');
            Injection.add(BindingTestHelper.TestInterface.class, 'Test', BindingTestHelper.SingletonTest.class);
            Injection.add(BindingTestHelper.AbstractTest.class, 'Test', BindingTestHelper.SingletonTest.class);
            Injection.add(Integer.class, 'Test', BindingTestHelper.IntegerFactory.class);
            Injection.add(Map<String, Integer>.class, 'Test', BindingTestHelper.MapFactory.class);
            insert new Binding__c(Type__c = BindingTestHelper.TestInterface.class.getName(), Action__c = 'Test', Implementation__c = BindingTestHelper.SingletonTest.class.getName());
            insert new Binding__c(Type__c = BindingTestHelper.AbstractTest.class.getName(), Action__c = 'Testg', Implementation__c = BindingTestHelper.SingletonTest.class.getName());
            insert new Binding__c(Type__c = Integer.class.getName(), Action__c = 'Test', Implementation__c = BindingTestHelper.IntegerFactory.class.getName());
            insert new Binding__c(Type__c = (Map<String, Integer>.class).getName(), Action__c = 'Test', Implementation__c = BindingTestHelper.MapFactory.class.getName());
        }
    }

    @IsTest
    static void testNonExistentBinding() {
        setup(true);
        System.runAs(BindingTestHelper.getUser()) {
            try {
                Injection.wire(BindingTestHelper.TestInterface.class, 'NotTest');
                Assert.fail();
            } catch (Injection.APIException ae) {
                Assert.areEqual('Binding for BindingTestHelper.TestInterface with action NotTest not found in registry', ae.getMessage());
            }
        }
    }

    @IsTest
    static void testPropertyBinding() {
        System.runAs(BindingTestHelper.getManager()) {
            Injection.add(Integer.class, 'Test', BindingTestHelper.IntegerFactory.class);
            Injection.add(Map<String, Integer>.class, 'Test', BindingTestHelper.MapFactory.class);
        }

        System.runAs(BindingTestHelper.getUser()) {
            Integer intProperty = (Integer) Injection.wire(Integer.class, 'Test');
            Assert.areEqual(123, intProperty);

            Map<String, Integer> mapProperty = (Map<String, Integer>) Injection.wire(Map<String, Integer>.class, 'Test');
            Assert.areEqual(2, mapProperty.size());
            Assert.areEqual(456, mapProperty.get('a'));
            Assert.areEqual(789, mapProperty.get('b'));
        }
    }

    @IsTest
    static void testSingletonBinding() {
        setup(true);
        System.runAs(BindingTestHelper.getUser()) {
            Assert.areEqual('INSTANCE1', ((BindingTestHelper.TestInterface) Injection.wire(BindingTestHelper.TestInterface.class, 'Test')).getValue());
            Assert.areEqual('INSTANCE1', ((BindingTestHelper.TestInterface) Injection.wire(BindingTestHelper.TestInterface.class, 'Test')).getValue());
            Assert.areEqual('INSTANCE2', ((BindingTestHelper.TestInterface) Injection.wire(BindingTestHelper.AbstractTest.class, 'Test')).getValue());
            Assert.areEqual('INSTANCE2', ((BindingTestHelper.TestInterface) Injection.wire(BindingTestHelper.AbstractTest.class, 'Test')).getValue());
        }
    }

    @IsTest
    static void testPrototypeBinding() {
        setup(false);
        System.runAs(BindingTestHelper.getUser()) {
            Assert.areEqual('INSTANCE1', ((BindingTestHelper.TestInterface) Injection.wire(BindingTestHelper.TestInterface.class, 'Test')).getValue());
            Assert.areEqual('INSTANCE2', ((BindingTestHelper.TestInterface) Injection.wire(BindingTestHelper.TestInterface.class, 'Test')).getValue());
            Assert.areEqual('INSTANCE3', ((BindingTestHelper.TestInterface) Injection.wire(BindingTestHelper.AbstractTest.class, 'Test')).getValue());
            Assert.areEqual('INSTANCE4', ((BindingTestHelper.TestInterface) Injection.wire(BindingTestHelper.AbstractTest.class, 'Test')).getValue());
        }
    }

    @IsTest
    static void testIsBound() {
        setup(true);
        System.runAs(BindingTestHelper.getUser()) {
            Assert.isTrue(Injection.has(BindingTestHelper.TestInterface.class, 'Test'));
            Assert.isTrue(Injection.has(BindingTestHelper.AbstractTest.class, 'Test'));
            Assert.isFalse(Injection.has(BindingTestHelper.TestInterface.class, 'NotTest'));
            Assert.isFalse(Injection.has(BindingTestHelper.TestInterface.class));
            Assert.isFalse(Injection.has(User.class, 'Test'));
        }
    }

    @IsTest
    static void testCustomSingletonBindings() {
        setup(true);
        System.runAs(BindingTestHelper.getManager()) {
            insert new Binding__c(
                    Type__c = BindingTestHelper.TestInterface.class.getName(),
                    Action__c = 'Test',
                    Implementation__c = BindingTestHelper.SingletonCustomTest.class.getName()
            );

            insert new Binding__c(
                    Type__c = BindingTestHelper.AbstractTest.class.getName(),
                    Action__c = 'Test',
                    Implementation__c = BindingTestHelper.SingletonCustomTest.class.getName()
            );
        }

        System.runAs(BindingTestHelper.getUser()) {
            Assert.areEqual('CUSTOM1', ((BindingTestHelper.TestInterface) Injection.wire(BindingTestHelper.TestInterface.class, 'Test')).getValue());
            Assert.areEqual('CUSTOM1', ((BindingTestHelper.TestInterface) Injection.wire(BindingTestHelper.TestInterface.class, 'Test')).getValue());
            Assert.areEqual('CUSTOM2', ((BindingTestHelper.TestInterface) Injection.wire(BindingTestHelper.AbstractTest.class, 'Test')).getValue());
            Assert.areEqual('CUSTOM2', ((BindingTestHelper.TestInterface) Injection.wire(BindingTestHelper.AbstractTest.class, 'Test')).getValue());
        }
    }

    @IsTest
    static void testCustomPrototypeBindings() {
        setup(true);
        System.runAs(BindingTestHelper.getManager()) {
            insert new Binding__c(
                    Type__c = BindingTestHelper.TestInterface.class.getName(),
                    Action__c = 'Test',
                    Implementation__c = BindingTestHelper.PrototypeCustomTest.class.getName()
            );

            insert new Binding__c(
                    Type__c = BindingTestHelper.AbstractTest.class.getName(),
                    Action__c = 'Test',
                    Implementation__c = BindingTestHelper.PrototypeCustomTest.class.getName()
            );
        }

        System.runAs(BindingTestHelper.getUser()) {
            Assert.areEqual('CUSTOM1', ((BindingTestHelper.TestInterface) Injection.wire(BindingTestHelper.TestInterface.class, 'Test')).getValue());
            Assert.areEqual('CUSTOM2', ((BindingTestHelper.TestInterface) Injection.wire(BindingTestHelper.TestInterface.class, 'Test')).getValue());
            Assert.areEqual('CUSTOM3', ((BindingTestHelper.TestInterface) Injection.wire(BindingTestHelper.AbstractTest.class, 'Test')).getValue());
            Assert.areEqual('CUSTOM4', ((BindingTestHelper.TestInterface) Injection.wire(BindingTestHelper.AbstractTest.class, 'Test')).getValue());
        }
    }

    private static void setup(Boolean singleton) {
        if (singleton) {
            Injection.add(BindingTestHelper.TestInterface.class, 'Test', BindingTestHelper.SingletonTest.class);
            Injection.add(BindingTestHelper.AbstractTest.class, 'Test', BindingTestHelper.SingletonTest.class);
        } else {
            Injection.add(BindingTestHelper.TestInterface.class, 'Test', BindingTestHelper.PrototypeTest.class);
            Injection.add(BindingTestHelper.AbstractTest.class, 'Test', BindingTestHelper.PrototypeTest.class);
        }

        BindingTestHelper.SINGLETON_INSTANCE =
                BindingTestHelper.PROTOTYPE_INSTANCE = 0;
    }
}