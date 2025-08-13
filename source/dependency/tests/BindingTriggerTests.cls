/**
 * @description
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../LICENSE target="_blank">MIT License</a>.
 * <br><br>
 * Unit tests for the binding trigger.
 *
 * @author Mark Brennand
 */
@IsTest
@SuppressWarnings('PMD')
public with sharing class BindingTriggerTests {
    private final static String TESTING = 'dependency';

    @TestSetup
    private static void createUsers() {
        TestHelper.createUsers(TESTING, new Set<String> { 'ForceFwDependencyInjectionPermissions' });
    }

    private static Binding__c binding1;
    private static Binding__c binding2;
    private static Binding__c binding3;
    private static Binding__c binding4;

    @IsTest
    private static void testValidInserts() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            binding1 = new Binding__c(
                    Type__c = BindingTestHelper.TestInterface.class.getName(),
                    Implementation__c = BindingTestHelper.SingletonTest.class.getName()
            );

            binding2 = new Binding__c(
                    Type__c = BindingTestHelper.AbstractTest.class.getName(),
                    Implementation__c = BindingTestHelper.SingletonTest.class.getName()
            );

            binding3 = new Binding__c(
                    Type__c = BindingTestHelper.TestInterface.class.getName(),
                    Action__c = 'Test',
                    Implementation__c = BindingTestHelper.SingletonTest.class.getName()
            );

            binding4 = new Binding__c(
                    Type__c = BindingTestHelper.AbstractTest.class.getName(),
                    Action__c = 'Test',
                    Implementation__c = BindingTestHelper.SingletonTest.class.getName()
            );

            insert new List<Binding__c>{
                    binding1, binding2, binding3, binding4
            };
        }
    }

    @IsTest
    private static void testValidUpdates() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            testValidInserts();

            binding1.Type__c = BindingTestHelper.AbstractTest.class.getName();
            binding1.Action__c = 'Test';
            binding4.Action__c = 'NotTest';
            upsert new List<Binding__c>{
                    binding1, binding4
            };

            binding2.Type__c = BindingTestHelper.TestInterface.class.getName();
            binding2.Action__c = 'Test';
            binding3.Action__c = null;
            upsert new List<Binding__c>{
                    binding2, binding3
            };
        }
    }

    @IsTest
    private static void testInvalidInserts() {
        TestHelper.setNOW();
        testValidInserts();

        System.runAs(TestHelper.getUser(TESTING)) {
            try {
                insert new Binding__c(
                        Type__c = BindingTestHelper.TestInterface.class.getName(),
                        Implementation__c = BindingTestHelper.SingletonTest.class.getName()
                );
                Assert.fail('Binding creation should fail');
            } catch (DmlException de) {
                Assert.isTrue(
                        TestHelper.exceptionContains('Binding for BindingTestHelper.TestInterface already exists', de),
                        'Unexpected exception: ' + de
                );
            }

            try {
                insert new Binding__c(
                        Type__c = BindingTestHelper.AbstractTest.class.getName(),
                        Implementation__c = BindingTestHelper.SingletonTest.class.getName()
                );
                Assert.fail();
            } catch (DmlException de) {
                Assert.isTrue(
                        TestHelper.exceptionContains('Binding for BindingTestHelper.AbstractTest already exists', de),
                        'Unexpected exception: ' + de
                );
            }

            try {
                insert new Binding__c(
                        Type__c = BindingTestHelper.TestInterface.class.getName(),
                        Action__c = 'Test',
                        Implementation__c = BindingTestHelper.SingletonTest.class.getName()
                );
                Assert.fail();
            } catch (DmlException de) {
                Assert.isTrue(
                        TestHelper.exceptionContains('Binding for BindingTestHelper.TestInterface with action Test already exists', de),
                        'Unexpected exception: ' + de
                );
            }

            try {
                insert new Binding__c(
                        Type__c = BindingTestHelper.AbstractTest.class.getName(),
                        Action__c = 'Test',
                        Implementation__c = BindingTestHelper.SingletonTest.class.getName()
                );
                Assert.fail();
            } catch (DmlException de) {
                Assert.isTrue(
                        TestHelper.exceptionContains('Binding for BindingTestHelper.AbstractTest with action Test already exists', de),
                        'Unexpected exception: ' + de
                );
            }

            try {
                insert new Binding__c(
                        Type__c = BindingTestHelper.TestInterface.class.getName(),
                        Action__c = 'ValidationTest',
                        Implementation__c = User.class.getName()
                );
                Assert.fail();
            } catch (DmlException de) {
                Assert.isTrue(
                        TestHelper.exceptionContains('Class User does not implement TestInterface', de),
                        'Unexpected exception: ' + de
                );
            }

            try {
                insert new Binding__c(
                        Type__c = BindingTestHelper.AbstractTest.class.getName(),
                        Action__c = 'ValidationTest',
                        Implementation__c = User.class.getName()
                );
                Assert.fail();
            } catch (DmlException de) {
                Assert.isTrue(
                        TestHelper.exceptionContains('Class User does not extend AbstractTest', de),
                        'Unexpected exception: ' + de
                );
            }

            try {
                insert new Binding__c(
                        Type__c = User.class.getName(),
                        Action__c = 'ValidationTest',
                        Implementation__c = User.class.getName()
                );
                Assert.fail();
            } catch (DmlException de) {
                Assert.isTrue(
                        TestHelper.exceptionContains('Class User has no registered bind checker', de),
                        'Unexpected exception: ' + de
                );
            }

            try {
                insert new Binding__c(
                        Type__c = BindingTestHelper.TestInterface.class.getName(),
                        Action__c = 'ValidationTest',
                        Implementation__c = BindingTestHelper.AbstractTest.class.getName()
                );
                Assert.fail();
            } catch (DmlException de) {
                Assert.isTrue(
                        TestHelper.exceptionContains('Implementation BindingTestHelper.AbstractTest must be instantiable', de),
                        'Unexpected exception: ' + de
                );
            }
        }
    }

    @IsTest
    private static void testInvalidUpdates() {
        TestHelper.setNOW();
        testValidInserts();

        System.runAs(TestHelper.getUser(TESTING)) {
            try {
                binding1.Type__c = BindingTestHelper.AbstractTest.class.getName();
                upsert binding1;
                Assert.fail();
            } catch (DmlException de) {
                Assert.isTrue(
                        TestHelper.exceptionContains('Binding for BindingTestHelper.AbstractTest already exists', de),
                        'Unexpected exception: ' + de
                );
            }

            try {
                binding2.Type__c = BindingTestHelper.TestInterface.class.getName();
                binding2.Action__c = null;
                binding3.Action__c = null;
                upsert new List<Binding__c>{
                        binding2, binding3
                };
                Assert.fail();
            } catch (DmlException de) {
                Assert.isTrue(
                        TestHelper.exceptionContains('Binding for BindingTestHelper.TestInterface already exists', de),
                        'Unexpected exception: ' + de
                );
            }

            try {
                binding1.Action__c = 'Test';
                upsert binding1;
                Assert.fail();
            } catch (DmlException de) {
                Assert.isTrue(
                        TestHelper.exceptionContains('Binding for BindingTestHelper.AbstractTest with action Test already exists', de),
                        'Unexpected exception: ' + de
                );
            }
        }
    }

    @IsTest
    private static void testReload() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            insert new Binding__c(
                    Type__c = BindingTestHelper.TestInterface.class.getName(),
                    Implementation__c = BindingTestHelper.SingletonTest.class.getName()
            );

            Assert.isTrue(DependencyV1.inject(BindingTestHelper.TestInterface.class) instanceof BindingTestHelper.SingletonTest);

            DependencyV1.bind(BindingTestHelper.TestInterface.class, BindingTestHelper.SingletonCustomTest.class);
            Assert.isTrue(DependencyV1.inject(BindingTestHelper.TestInterface.class) instanceof BindingTestHelper.SingletonCustomTest);

            DependencyV1.reload();
            Assert.isTrue(DependencyV1.inject(BindingTestHelper.TestInterface.class) instanceof BindingTestHelper.SingletonTest);
        }
    }
}