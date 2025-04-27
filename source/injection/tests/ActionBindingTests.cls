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
    static void testInstantiation() {
        System.runAs(TestData.getManager()) {
            TestData.testBindingFailure(TestData.TestInterface.class, 'Test', TestData.AbstractTest.class, 'Implementation "TestData.AbstractTest" must be instantiable');
            Injection.add(TestData.TestInterface.class, 'Test', TestData.SingletonTest.class);
            Injection.add(TestData.AbstractTest.class, 'Test', TestData.SingletonTest.class);
            Injection.add(Integer.class, 'Test', TesTData.IntegerFactory.class);
            Injection.add(Map<String, Integer>.class, 'Test', TestData.MapFactory.class);
            insert new Binding__c(Type__c = Integer.class.getName(), Action__c = 'Test', Implementation__c = TestData.IntegerFactory.class.getName());
            insert new Binding__c(Type__c = (Map<String, Integer>.class).getName(), Action__c = 'Test', Implementation__c = TestData.MapFactory.class.getName());
        }
    }

    @IsTest
    static void testValidation() {
        System.runAs(TestData.getManager()) {
            TestData.testBindingFailure(TestData.TestInterface.class, 'Test', User.class, 'Type "User" does not implement "TestInterface"');
            TestData.testBindingFailure(TestData.AbstractTest.class, 'Test', User.class, 'Type "User" does not extend "AbstractTest"');
            TestData.testBindingFailure(Integer.class, 'Test', User.class, 'Implementation "User" is not a super class of "Integer"');
            TestData.testBindingFailure(Map<String, Integer>.class, 'Test', Map<String, Double>.class, 'Implementation "Map<String,Double>" is not a super class of "Map<String,Integer>"');
            Injection.add(TestData.TestInterface.class, 'Test', TestData.SingletonTest.class);
            Injection.add(TestData.AbstractTest.class, 'Test', TestData.SingletonTest.class);
            Injection.add(Integer.class, 'Test', TestData.IntegerFactory.class);
            Injection.add(Map<String, Integer>.class, 'Test', TestData.MapFactory.class);
            insert new Binding__c(Type__c = TestData.TestInterface.class.getName(), Action__c = 'Test', Implementation__c = TestData.SingletonTest.class.getName());
            insert new Binding__c(Type__c = TestData.AbstractTest.class.getName(), Action__c = 'Testg', Implementation__c = TestData.SingletonTest.class.getName());
            insert new Binding__c(Type__c = Integer.class.getName(), Action__c = 'Test', Implementation__c = TestData.IntegerFactory.class.getName());
            insert new Binding__c(Type__c = (Map<String, Integer>.class).getName(), Action__c = 'Test', Implementation__c = TestData.MapFactory.class.getName());
        }
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
    static void testPropertyBinding() {
        System.runAs(TestData.getManager()) {
            Injection.add(Integer.class, 'Test', TestData.IntegerFactory.class);
            Injection.add(Map<String, Integer>.class, 'Test', TestData.MapFactory.class);
        }

        System.runAs(TestData.getUser()) {
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