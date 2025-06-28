/**
 * MIT License
 *
 * Copyright (c) 2025 Mark Brennand
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */
/**
 * @description
 * Unit tests for the binding trigger.
 *
 * @author Mark Brennand
 */

@IsTest
public with sharing class BindingTriggerTests {
    @TestSetup
    private static void setup() {
        BindingTestHelper.createUsers();
    }

    private static Binding__c binding1;
    private static Binding__c binding2;
    private static Binding__c binding3;
    private static Binding__c binding4;

    @IsTest
    static void testValidInserts() {
        System.runAs(BindingTestHelper.getUser()) {
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
    static void testValidUpdates() {
        System.runAs(BindingTestHelper.getUser()) {
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
    static void testInvalidInserts() {
        testValidInserts();

        System.runAs(BindingTestHelper.getUser()) {
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
    static void testInvalidUpdates() {
        testValidInserts();

        System.runAs(BindingTestHelper.getUser()) {
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
        System.runAs(BindingTestHelper.getUser()) {
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