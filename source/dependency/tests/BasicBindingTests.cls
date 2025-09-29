/**
 * @description
 * <p>
 * Unit tests for basic binding.
 * <p>
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../LICENSE target="_blank">MIT License</a>.
 *
 * @author Mark Brennand
 */
@IsTest
@SuppressWarnings('PMD')
public with sharing class BasicBindingTests {
    private final static String TESTING = 'dependency';

    @TestSetup
    private static void createUsers() {
        TestHelper.createUsers(TESTING, new Set<String> { 'ForceFwDependencyInjectionPermissions' });
    }

    @IsTest
    private static void testInstantiation() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getManager(TESTING)) {
            BindingTestHelper.testBindingFailure(BindingTestHelper.SingletonTest.class, OptionalV1.empty(), BindingTestHelper.SingletonTest.class, 'Class BindingTestHelper.SingletonTest must not be instantiable');
            BindingTestHelper.testBindingFailure(BindingTestHelper.TestInterface.class, OptionalV1.empty(), BindingTestHelper.AbstractTest.class, 'Implementation BindingTestHelper.AbstractTest must be instantiable');
            DependencyV1.bind(BindingTestHelper.TestInterface.class, BindingTestHelper.SingletonTest.class);
            DependencyV1.bind(BindingTestHelper.AbstractTest.class, BindingTestHelper.SingletonTest.class);
            insert new Binding__c(Type__c = BindingTestHelper.TestInterface.class.getName(), Implementation__c = BindingTestHelper.SingletonTest.class.getName());
            insert new Binding__c(Type__c = BindingTestHelper.AbstractTest.class.getName(), Implementation__c = BindingTestHelper.SingletonTest.class.getName());
        }
    }

    @IsTest
    private static void testValidation() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getManager(TESTING)) {
            BindingTestHelper.testBindingFailure(BindingTestHelper.TestInterface.class, OptionalV1.empty(), User.class, 'Class User does not implement TestInterface');
            BindingTestHelper.testBindingFailure(BindingTestHelper.AbstractTest.class, OptionalV1.empty(), User.class, 'Class User does not extend AbstractTest');
            DependencyV1.bind(BindingTestHelper.TestInterface.class, BindingTestHelper.SingletonTest.class);
            DependencyV1.bind(BindingTestHelper.AbstractTest.class, BindingTestHelper.SingletonTest.class);
            insert new Binding__c(Type__c = BindingTestHelper.TestInterface.class.getName(), Implementation__c = BindingTestHelper.SingletonTest.class.getName());
            insert new Binding__c(Type__c = BindingTestHelper.AbstractTest.class.getName(), Implementation__c = BindingTestHelper.SingletonTest.class.getName());
        }
    }

    @IsTest
    private static void testPropertyBinding() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getManager(TESTING)) {
            BindingTestHelper.testBindingFailure(Map<String, Integer>.class, OptionalV1.empty(), BindingTestHelper.MapFactory.class, 'Class Map<String,Integer> must not be instantiable');
        }
    }

    @IsTest
    private static void testNonExistentBinding() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            try {
                DependencyV1.inject(BindingTestHelper.TestInterface.class);
                Assert.fail();
            } catch (DependencyV1.APIException ae) {
                Assert.isTrue(
                        TestHelper.exceptionContains('Binding for BindingTestHelper.TestInterface not found in registry', ae),
                        'Unexpected exception: ' + ae
                );
            }
        }
    }

    @IsTest
    private static void testSingletonBinding() {
        TestHelper.setNOW();
        setup(true);
        System.runAs(TestHelper.getUser(TESTING)) {
            Assert.areEqual('INSTANCE1', ((BindingTestHelper.TestInterface) DependencyV1.inject(BindingTestHelper.TestInterface.class)).getValue());
            Assert.areEqual('INSTANCE1', ((BindingTestHelper.TestInterface) DependencyV1.inject(BindingTestHelper.TestInterface.class)).getValue());
            Assert.areEqual('INSTANCE2', ((BindingTestHelper.TestInterface) DependencyV1.inject(BindingTestHelper.AbstractTest.class)).getValue());
            Assert.areEqual('INSTANCE2', ((BindingTestHelper.TestInterface) DependencyV1.inject(BindingTestHelper.AbstractTest.class)).getValue());
        }
    }

    @IsTest
    private static void testPrototypeBinding() {
        TestHelper.setNOW();
        setup(false);
        System.runAs(TestHelper.getUser(TESTING)) {
            Assert.areEqual('INSTANCE1', ((BindingTestHelper.TestInterface) DependencyV1.inject(BindingTestHelper.TestInterface.class)).getValue());
            Assert.areEqual('INSTANCE2', ((BindingTestHelper.TestInterface) DependencyV1.inject(BindingTestHelper.TestInterface.class)).getValue());
            Assert.areEqual('INSTANCE3', ((BindingTestHelper.TestInterface) DependencyV1.inject(BindingTestHelper.AbstractTest.class)).getValue());
            Assert.areEqual('INSTANCE4', ((BindingTestHelper.TestInterface) DependencyV1.inject(BindingTestHelper.AbstractTest.class)).getValue());
        }
    }

    @IsTest
    private static void testIsBound() {
        TestHelper.setNOW();
        setup(true);
        System.runAs(TestHelper.getUser(TESTING)) {
            Assert.isTrue(DependencyV1.isBound(BindingTestHelper.TestInterface.class));
            Assert.isTrue(DependencyV1.isBound(BindingTestHelper.AbstractTest.class));
            Assert.isFalse(DependencyV1.isBound(BindingTestHelper.TestInterface.class, 'Test'));
            Assert.isFalse(DependencyV1.isBound(User.class));
        }
    }

    @IsTest
    private static void testCustomSingletonBindings() {
        TestHelper.setNOW();
        setup(true);
        System.runAs(TestHelper.getManager(TESTING)) {
            insert new List<Binding__c> {
                    new Binding__c(
                            Type__c = BindingTestHelper.TestInterface.class.getName(),
                            Implementation__c = BindingTestHelper.SingletonCustomTest.class.getName()
                    ),
                    new Binding__c(
                            Type__c = BindingTestHelper.AbstractTest.class.getName(),
                            Implementation__c = BindingTestHelper.SingletonCustomTest.class.getName()
                    )
            };
        }

        BindingTestHelper.singletonInstance =
        BindingTestHelper.prototypeInstance = 0;

        // The first inject call adds the 2 custom bindings, which will instantiate the implementation. Hence use
        // CUSTOM3 and CUSTOM4.
        System.runAs(TestHelper.getUser(TESTING)) {
            Assert.areEqual('CUSTOM1', ((BindingTestHelper.TestInterface) DependencyV1.inject(BindingTestHelper.TestInterface.class)).getValue());
            Assert.areEqual('CUSTOM1', ((BindingTestHelper.TestInterface) DependencyV1.inject(BindingTestHelper.TestInterface.class)).getValue());
            Assert.areEqual('CUSTOM2', ((BindingTestHelper.TestInterface) DependencyV1.inject(BindingTestHelper.AbstractTest.class)).getValue());
            Assert.areEqual('CUSTOM2', ((BindingTestHelper.TestInterface) DependencyV1.inject(BindingTestHelper.AbstractTest.class)).getValue());
        }
    }

    @IsTest
    private static void testCustomPrototypeBindings() {
        TestHelper.setNOW();
        setup(true);
        System.runAs(TestHelper.getManager(TESTING)) {
            insert new List<Binding__c> {
                    new Binding__c(
                            Type__c = BindingTestHelper.TestInterface.class.getName(),
                            Implementation__c = BindingTestHelper.PrototypeCustomTest.class.getName()
                    ),
                    new Binding__c(
                            Type__c = BindingTestHelper.AbstractTest.class.getName(),
                            Implementation__c = BindingTestHelper.PrototypeCustomTest.class.getName()
                    )
            };
        }

        System.runAs(TestHelper.getUser(TESTING)) {
            Assert.areEqual('CUSTOM1', ((BindingTestHelper.TestInterface) DependencyV1.inject(BindingTestHelper.TestInterface.class)).getValue());
            Assert.areEqual('CUSTOM2', ((BindingTestHelper.TestInterface) DependencyV1.inject(BindingTestHelper.TestInterface.class)).getValue());
            Assert.areEqual('CUSTOM3', ((BindingTestHelper.TestInterface) DependencyV1.inject(BindingTestHelper.AbstractTest.class)).getValue());
            Assert.areEqual('CUSTOM4', ((BindingTestHelper.TestInterface) DependencyV1.inject(BindingTestHelper.AbstractTest.class)).getValue());
        }
    }

    private static void setup(Boolean singleton) {
        System.runAs(TestHelper.getManager(TESTING)) {
            if (singleton) {
                DependencyV1.bind(BindingTestHelper.TestInterface.class, BindingTestHelper.SingletonTest.class);
                DependencyV1.bind(BindingTestHelper.AbstractTest.class, BindingTestHelper.SingletonTest.class);
            } else {
                DependencyV1.bind(BindingTestHelper.TestInterface.class, BindingTestHelper.PrototypeTest.class);
                DependencyV1.bind(BindingTestHelper.AbstractTest.class, BindingTestHelper.PrototypeTest.class);
            }

            BindingTestHelper.singletonInstance =
                    BindingTestHelper.prototypeInstance = 0;
        }
    }
}