/**
 * @description
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../../LICENSE target="_blank">MIT License</a>.
 * <br><br>
 * Unit tests for action binding.
 *
 * @author Mark Brennand
 */
@IsTest
public with sharing class ActionBindingTests {

    @TestSetup
    private static void createUsers() {
        BindingTestHelper.createUsers();
    }

    @IsTest
    private static void testInstantiation() {
        TestHelper.setNOW();
        System.runAs(BindingTestHelper.getManager()) {
            BindingTestHelper.testBindingFailure(BindingTestHelper.TestInterface.class, OptionalV1.of('Test'), BindingTestHelper.AbstractTest.class, 'Implementation BindingTestHelper.AbstractTest must be instantiable');
            DependencyV1.bind(BindingTestHelper.TestInterface.class, 'Test', BindingTestHelper.SingletonTest.class);
            DependencyV1.bind(BindingTestHelper.AbstractTest.class, 'Test', BindingTestHelper.SingletonTest.class);
            DependencyV1.bind(Integer.class, 'Test', BindingTestHelper.IntegerFactory.class);
            DependencyV1.bind(Map<String, Integer>.class, 'Test', BindingTestHelper.MapFactory.class);
            insert new Binding__c(Type__c = Integer.class.getName(), Action__c = 'Test', Implementation__c = BindingTestHelper.IntegerFactory.class.getName());
            insert new Binding__c(Type__c = (Map<String, Integer>.class).getName(), Action__c = 'Test', Implementation__c = BindingTestHelper.MapFactory.class.getName());

            try {
                insert new Binding__c(Type__c = (Map<Decimal, Integer>.class).getName(), Action__c = 'Test', Implementation__c = BindingTestHelper.MapFactory.class.getName());
            } catch(DMLException de) {
                Assert.isTrue(
                        TestHelper.exceptionContains('Class Map<Decimal,Integer> is not registered for bind checking', de),
                        'Unexpected exception: ' + de
                );
            }

        }
    }

    @IsTest
    private static void testValidation() {
        TestHelper.setNOW();
        System.runAs(BindingTestHelper.getManager()) {
            BindingTestHelper.testBindingFailure(BindingTestHelper.TestInterface.class, OptionalV1.of('Test'), User.class, 'Class User does not implement TestInterface');
            BindingTestHelper.testBindingFailure(BindingTestHelper.AbstractTest.class, OptionalV1.of('Test'), User.class, 'Class User does not extend AbstractTest');
            BindingTestHelper.testBindingFailure(Integer.class, OptionalV1.of('Test'), User.class, 'Class User does not extend Integer');
            BindingTestHelper.testBindingFailure(Map<String, Integer>.class, OptionalV1.of('Test'), Map<String, Double>.class, 'Class Map<String,Double> does not extend Map<String,Integer>');
            DependencyV1.bind(BindingTestHelper.TestInterface.class, 'Test', BindingTestHelper.SingletonTest.class);
            DependencyV1.bind(BindingTestHelper.AbstractTest.class, 'Test', BindingTestHelper.SingletonTest.class);
            DependencyV1.bind(Integer.class, 'Test', BindingTestHelper.IntegerFactory.class);
            DependencyV1.bind(Map<String, Integer>.class, 'Test', BindingTestHelper.MapFactory.class);
            insert new Binding__c(Type__c = BindingTestHelper.TestInterface.class.getName(), Action__c = 'Test', Implementation__c = BindingTestHelper.SingletonTest.class.getName());
            insert new Binding__c(Type__c = BindingTestHelper.AbstractTest.class.getName(), Action__c = 'Testg', Implementation__c = BindingTestHelper.SingletonTest.class.getName());
            insert new Binding__c(Type__c = Integer.class.getName(), Action__c = 'Test', Implementation__c = BindingTestHelper.IntegerFactory.class.getName());
            insert new Binding__c(Type__c = (Map<String, Integer>.class).getName(), Action__c = 'Test', Implementation__c = BindingTestHelper.MapFactory.class.getName());

            // Complete testing of BindingCheck;
            DependencyV1.bind(String.class, 'Test', StringFactory.class);
            DependencyV1.bind(Integer.class, 'Test', IntegerFactory.class);
            DependencyV1.bind(Long.class, 'Test', LongFactory.class);
            DependencyV1.bind(Double.class, 'Test', DoubleFactory.class);
            DependencyV1.bind(Decimal.class, 'Test', DecimalFactory.class);
            DependencyV1.bind(Map<String, Object>.class, 'Test', MapStringObjectFactory.class);
            DependencyV1.bind(Map<String, String>.class, 'Test', MapStringStringFactory.class);
            DependencyV1.bind(Map<String, Integer>.class, 'Test', MapStringIntegerFactory.class);
            BindingTestHelper.testBindingFailure(Map<String, List<Integer>>.class, OptionalV1.of('Test'), MapStringListIntegerFactory.class, 'Class Map<String,List<Integer>> has no registered bind checker');
        }
    }

    @IsTest
    private static void testNonExistentBinding() {
        TestHelper.setNOW();
        setup(true);
        System.runAs(BindingTestHelper.getUser()) {
            try {
                DependencyV1.inject(BindingTestHelper.TestInterface.class, 'NotTest');
                Assert.fail();
            } catch (DependencyV1.APIException ae) {
                Assert.isTrue(
                        TestHelper.exceptionContains('Binding for BindingTestHelper.TestInterface with action NotTest not found in registry', ae),
                        'Unexpected exception: ' + ae
                );
            }
        }
    }

    @IsTest
    private static void testPropertyBinding() {
        TestHelper.setNOW();
        System.runAs(BindingTestHelper.getManager()) {
            DependencyV1.bind(Integer.class, 'Test', BindingTestHelper.IntegerFactory.class);
            DependencyV1.bind(Map<String, Integer>.class, 'Test', BindingTestHelper.MapFactory.class);
        }

        System.runAs(BindingTestHelper.getUser()) {
            Integer intProperty = (Integer) DependencyV1.inject(Integer.class, 'Test');
            Assert.areEqual(123, intProperty);

            Map<String, Integer> mapProperty = (Map<String, Integer>) DependencyV1.inject(Map<String, Integer>.class, 'Test');
            Assert.areEqual(2, mapProperty.size());
            Assert.areEqual(456, mapProperty.get('a'));
            Assert.areEqual(789, mapProperty.get('b'));
        }
    }

    @IsTest
    private static void testSingletonBinding() {
        TestHelper.setNOW();
        setup(true);
        System.runAs(BindingTestHelper.getUser()) {
            Assert.areEqual('INSTANCE1', ((BindingTestHelper.TestInterface) DependencyV1.inject(BindingTestHelper.TestInterface.class, 'Test')).getValue());
            Assert.areEqual('INSTANCE1', ((BindingTestHelper.TestInterface) DependencyV1.inject(BindingTestHelper.TestInterface.class, 'Test')).getValue());
            Assert.areEqual('INSTANCE2', ((BindingTestHelper.TestInterface) DependencyV1.inject(BindingTestHelper.AbstractTest.class, 'Test')).getValue());
            Assert.areEqual('INSTANCE2', ((BindingTestHelper.TestInterface) DependencyV1.inject(BindingTestHelper.AbstractTest.class, 'Test')).getValue());
        }
    }

    @IsTest
    private static void testPrototypeBinding() {
        TestHelper.setNOW();
        setup(false);
        System.runAs(BindingTestHelper.getUser()) {
            Assert.areEqual('INSTANCE1', ((BindingTestHelper.TestInterface) DependencyV1.inject(BindingTestHelper.TestInterface.class, 'Test')).getValue());
            Assert.areEqual('INSTANCE2', ((BindingTestHelper.TestInterface) DependencyV1.inject(BindingTestHelper.TestInterface.class, 'Test')).getValue());
            Assert.areEqual('INSTANCE3', ((BindingTestHelper.TestInterface) DependencyV1.inject(BindingTestHelper.AbstractTest.class, 'Test')).getValue());
            Assert.areEqual('INSTANCE4', ((BindingTestHelper.TestInterface) DependencyV1.inject(BindingTestHelper.AbstractTest.class, 'Test')).getValue());
        }
    }

    @IsTest
    private static void testIsBound() {
        TestHelper.setNOW();
        setup(true);
        System.runAs(BindingTestHelper.getUser()) {
            Assert.isTrue(DependencyV1.isBound(BindingTestHelper.TestInterface.class, 'Test'));
            Assert.isTrue(DependencyV1.isBound(BindingTestHelper.AbstractTest.class, 'Test'));
            Assert.isFalse(DependencyV1.isBound(BindingTestHelper.TestInterface.class, 'NotTest'));
            Assert.isFalse(DependencyV1.isBound(BindingTestHelper.TestInterface.class));
            Assert.isFalse(DependencyV1.isBound(User.class, 'Test'));
        }
    }

    @IsTest
    private static void testCustomSingletonBindings() {
        TestHelper.setNOW();
        setup(true);
        System.runAs(BindingTestHelper.getManager()) {
            insert new List<Binding__c> {
                    new Binding__c(
                            Type__c = BindingTestHelper.TestInterface.class.getName(),
                            Action__c = 'Test',
                            Implementation__c = BindingTestHelper.SingletonCustomTest.class.getName()
                    ),
                    new Binding__c(
                            Type__c = BindingTestHelper.AbstractTest.class.getName(),
                            Action__c = 'Test',
                            Implementation__c = BindingTestHelper.SingletonCustomTest.class.getName()
                    )
            };
        }

        System.runAs(BindingTestHelper.getUser()) {
            Assert.areEqual('CUSTOM1', ((BindingTestHelper.TestInterface) DependencyV1.inject(BindingTestHelper.TestInterface.class, 'Test')).getValue());
            Assert.areEqual('CUSTOM1', ((BindingTestHelper.TestInterface) DependencyV1.inject(BindingTestHelper.TestInterface.class, 'Test')).getValue());
            Assert.areEqual('CUSTOM2', ((BindingTestHelper.TestInterface) DependencyV1.inject(BindingTestHelper.AbstractTest.class, 'Test')).getValue());
            Assert.areEqual('CUSTOM2', ((BindingTestHelper.TestInterface) DependencyV1.inject(BindingTestHelper.AbstractTest.class, 'Test')).getValue());
        }
    }

    @IsTest
    private static void testCustomPrototypeBindings() {
        TestHelper.setNOW();
        setup(true);
        System.runAs(BindingTestHelper.getManager()) {
            insert new List<Binding__c> {
                    new Binding__c(
                            Type__c = BindingTestHelper.TestInterface.class.getName(),
                            Action__c = 'Test',
                            Implementation__c = BindingTestHelper.PrototypeCustomTest.class.getName()
                    ),
                    new Binding__c(
                            Type__c = BindingTestHelper.AbstractTest.class.getName(),
                            Action__c = 'Test',
                            Implementation__c = BindingTestHelper.PrototypeCustomTest.class.getName()
                    )
            };
        }

        System.runAs(BindingTestHelper.getUser()) {
            Assert.areEqual('CUSTOM1', ((BindingTestHelper.TestInterface) DependencyV1.inject(BindingTestHelper.TestInterface.class, 'Test')).getValue());
            Assert.areEqual('CUSTOM2', ((BindingTestHelper.TestInterface) DependencyV1.inject(BindingTestHelper.TestInterface.class, 'Test')).getValue());
            Assert.areEqual('CUSTOM3', ((BindingTestHelper.TestInterface) DependencyV1.inject(BindingTestHelper.AbstractTest.class, 'Test')).getValue());
            Assert.areEqual('CUSTOM4', ((BindingTestHelper.TestInterface) DependencyV1.inject(BindingTestHelper.AbstractTest.class, 'Test')).getValue());
        }
    }

    private static void setup(Boolean singleton) {
        if (singleton) {
            DependencyV1.bind(BindingTestHelper.TestInterface.class, 'Test', BindingTestHelper.SingletonTest.class);
            DependencyV1.bind(BindingTestHelper.AbstractTest.class, 'Test', BindingTestHelper.SingletonTest.class);
        } else {
            DependencyV1.bind(BindingTestHelper.TestInterface.class, 'Test', BindingTestHelper.PrototypeTest.class);
            DependencyV1.bind(BindingTestHelper.AbstractTest.class, 'Test', BindingTestHelper.PrototypeTest.class);
        }

        BindingTestHelper.SINGLETON_INSTANCE =
                BindingTestHelper.PROTOTYPE_INSTANCE = 0;
    }

    public with sharing class StringFactory implements TypesV1.Factory {
        public Object newInstance() {
            return '123';
        }
    }

    public with sharing class IntegerFactory implements TypesV1.Factory {
        public Object newInstance() {
            return 123;
        }
    }

    public with sharing class LongFactory implements TypesV1.Factory {
        public Object newInstance() {
            return 123L;
        }
    }

    public with sharing class DoubleFactory implements TypesV1.Factory {
        public Object newInstance() {
            return 123.123;
        }
    }
    
    public with sharing class DecimalFactory implements TypesV1.Factory {
        public Object newInstance() {
            return 123.123;
        }
    }

    public with sharing class MapStringObjectFactory implements TypesV1.Factory {
        public Object newInstance() {
            return new Map<String, Object>();
        }
    }

    public with sharing class MapStringStringFactory implements TypesV1.Factory {
        public Object newInstance() {
            return new Map<String, String>();
        }
    }

    public with sharing class MapStringIntegerFactory implements TypesV1.Factory {
        public Object newInstance() {
            return new Map<String, Integer>();
        }
    }

    public with sharing class MapStringListIntegerFactory implements TypesV1.Factory {
        public Object newInstance() {
            return new Map<String, List<Integer>>();
        }
    }
}
