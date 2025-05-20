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
            Injection.bind(BindingTestHelper.TestInterface.class, 'Test', BindingTestHelper.SingletonTest.class);
            Injection.bind(BindingTestHelper.AbstractTest.class, 'Test', BindingTestHelper.SingletonTest.class);
            Injection.bind(Integer.class, 'Test', BindingTestHelper.IntegerFactory.class);
            Injection.bind(Map<String, Integer>.class, 'Test', BindingTestHelper.MapFactory.class);
            insert new Binding__c(Type__c = Integer.class.getName(), Action__c = 'Test', Implementation__c = BindingTestHelper.IntegerFactory.class.getName());
            insert new Binding__c(Type__c = (Map<String, Integer>.class).getName(), Action__c = 'Test', Implementation__c = BindingTestHelper.MapFactory.class.getName());
        }
    }

    @IsTest
    static void testValidation() {
        System.runAs(BindingTestHelper.getManager()) {
            BindingTestHelper.testBindingFailure(BindingTestHelper.TestInterface.class, 'Test', User.class, 'Class User does not implement TestInterface');
            BindingTestHelper.testBindingFailure(BindingTestHelper.AbstractTest.class, 'Test', User.class, 'Class User does not extend AbstractTest');
            BindingTestHelper.testBindingFailure(Integer.class, 'Test', User.class, 'Class User cannot be assigned to an Integer');
            BindingTestHelper.testBindingFailure(Map<String, Integer>.class, 'Test', Map<String, Double>.class, 'Class Map<String,Double> cannot be assigned to an Map<String,Integer>');
            Injection.bind(BindingTestHelper.TestInterface.class, 'Test', BindingTestHelper.SingletonTest.class);
            Injection.bind(BindingTestHelper.AbstractTest.class, 'Test', BindingTestHelper.SingletonTest.class);
            Injection.bind(Integer.class, 'Test', BindingTestHelper.IntegerFactory.class);
            Injection.bind(Map<String, Integer>.class, 'Test', BindingTestHelper.MapFactory.class);
            insert new Binding__c(Type__c = BindingTestHelper.TestInterface.class.getName(), Action__c = 'Test', Implementation__c = BindingTestHelper.SingletonTest.class.getName());
            insert new Binding__c(Type__c = BindingTestHelper.AbstractTest.class.getName(), Action__c = 'Testg', Implementation__c = BindingTestHelper.SingletonTest.class.getName());
            insert new Binding__c(Type__c = Integer.class.getName(), Action__c = 'Test', Implementation__c = BindingTestHelper.IntegerFactory.class.getName());
            insert new Binding__c(Type__c = (Map<String, Integer>.class).getName(), Action__c = 'Test', Implementation__c = BindingTestHelper.MapFactory.class.getName());

            // Complete testing of BindChecker;
            Injection.bind(String.class, 'Test', StringFactory.class);
            Injection.bind(Integer.class, 'Test', IntegerFactory.class);
            Injection.bind(Long.class, 'Test', LongFactory.class);
            Injection.bind(Double.class, 'Test', DoubleFactory.class);
            Injection.bind(Decimal.class, 'Test', DecimalFactory.class);
            Injection.bind(Map<String, Object>.class, 'Test', MapStringObjectFactory.class);
            Injection.bind(Map<String, String>.class, 'Test', MapStringStringFactory.class);
            Injection.bind(Map<String, Integer>.class, 'Test', MapStringIntegerFactory.class);
            BindingTestHelper.testBindingFailure(Map<String, List<Integer>>.class, 'Test', MapStringListIntegerFactory.class, 'Class Map<String,List<Integer>> has no registered bind checker');
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
            Injection.bind(Integer.class, 'Test', BindingTestHelper.IntegerFactory.class);
            Injection.bind(Map<String, Integer>.class, 'Test', BindingTestHelper.MapFactory.class);
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
            Assert.isTrue(Injection.isBound(BindingTestHelper.TestInterface.class, 'Test'));
            Assert.isTrue(Injection.isBound(BindingTestHelper.AbstractTest.class, 'Test'));
            Assert.isFalse(Injection.isBound(BindingTestHelper.TestInterface.class, 'NotTest'));
            Assert.isFalse(Injection.isBound(BindingTestHelper.TestInterface.class));
            Assert.isFalse(Injection.isBound(User.class, 'Test'));
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
            Injection.bind(BindingTestHelper.TestInterface.class, 'Test', BindingTestHelper.SingletonTest.class);
            Injection.bind(BindingTestHelper.AbstractTest.class, 'Test', BindingTestHelper.SingletonTest.class);
        } else {
            Injection.bind(BindingTestHelper.TestInterface.class, 'Test', BindingTestHelper.PrototypeTest.class);
            Injection.bind(BindingTestHelper.AbstractTest.class, 'Test', BindingTestHelper.PrototypeTest.class);
        }

        BindingTestHelper.SINGLETON_INSTANCE =
                BindingTestHelper.PROTOTYPE_INSTANCE = 0;
    }

    public with sharing class StringFactory implements TypeHelper.Factory {
        public Object newInstance() {
            return '123';
        }
    }

    public with sharing class IntegerFactory implements TypeHelper.Factory {
        public Object newInstance() {
            return 123;
        }
    }

    public with sharing class LongFactory implements TypeHelper.Factory {
        public Object newInstance() {
            return 123L;
        }
    }

    public with sharing class DoubleFactory implements TypeHelper.Factory {
        public Object newInstance() {
            return 123.123;
        }
    }
    
    public with sharing class DecimalFactory implements TypeHelper.Factory {
        public Object newInstance() {
            return 123.123;
        }
    }

    public with sharing class MapStringObjectFactory implements TypeHelper.Factory {
        public Object newInstance() {
            return new Map<String, Object>();
        }
    }

    public with sharing class MapStringStringFactory implements TypeHelper.Factory {
        public Object newInstance() {
            return new Map<String, String>();
        }
    }

    public with sharing class MapStringIntegerFactory implements TypeHelper.Factory {
        public Object newInstance() {
            return new Map<String, Integer>();
        }
    }

    public with sharing class MapStringListIntegerFactory implements TypeHelper.Factory {
        public Object newInstance() {
            return new Map<String, List<Integer>>();
        }
    }
}