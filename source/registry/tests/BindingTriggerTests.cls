/**
 * @description
 * Unit tests for the binding trigger.
 *
 * @author Mark Brennand
 */

@IsTest
public with sharing class BindingTriggerTests {
    private static Binding__c binding1;
    private static Binding__c binding2;
    private static Binding__c binding3;
    private static Binding__c binding4;

    @IsTest
    static void testValidInserts() {
        binding1 = new Binding__c(
                Type__c = TestData.TestInterface.class.getName(),
                Implementation__c = TestData.SingletonTest.class.getName()
        );

        binding2 = new Binding__c(
                Type__c = TestData.AbstractTest.class.getName(),
                Implementation__c = TestData.SingletonTest.class.getName()
        );

        binding3 = new Binding__c(
                Type__c = TestData.TestInterface.class.getName(),
                Action__c = 'Test',
                Implementation__c = TestData.SingletonTest.class.getName()
        );

        binding4 = new Binding__c(
                Type__c = TestData.AbstractTest.class.getName(),
                Action__c = 'Test',
                Implementation__c = TestData.SingletonTest.class.getName()
        );

        insert new List<Binding__c> { binding1, binding2, binding3, binding4 };
    }

    @IsTest
    static void testValidUpdates() {
        testValidInserts();

        binding1.Type__c = TestData.AbstractTest.class.getName();
        binding1.Action__c = 'Test';
        binding4.Action__c = 'NotTest';
        upsert new List<Binding__c> { binding1, binding4 };

        binding2.Type__c = TestData.TestInterface.class.getName();
        binding2.Action__c = 'Test';
        binding3.Action__c = null;
        upsert new List<Binding__c> { binding2, binding3 };
    }

    @IsTest
    static void testInvalidInserts() {
        testValidInserts();

        try {
            insert new Binding__c(
                    Type__c = TestData.TestInterface.class.getName(),
                    Implementation__c = TestData.SingletonTest.class.getName()
            );
            Assert.fail();
        } catch(DmlException de) {
            Assert.isTrue(de.getMessage().contains('Binding for "TestData.TestInterface" already exists'));
        }

        try {
            insert new Binding__c(
                    Type__c = TestData.AbstractTest.class.getName(),
                    Implementation__c = TestData.SingletonTest.class.getName()
            );
            Assert.fail();
        } catch(DmlException de) {
            Assert.isTrue(de.getMessage().contains('Binding for "TestData.AbstractTest" already exists'));
        }

        try {
            insert new Binding__c(
                    Type__c = TestData.TestInterface.class.getName(),
                    Action__c = 'Test',
                    Implementation__c = TestData.SingletonTest.class.getName()
            );
            Assert.fail();
        } catch(DmlException de) {
            Assert.isTrue(de.getMessage().contains('Binding for "TestData.TestInterface" with action "Test" already exists'));
        }

        try {
            insert new Binding__c(
                    Type__c = TestData.AbstractTest.class.getName(),
                    Action__c = 'Test',
                    Implementation__c = TestData.SingletonTest.class.getName()
            );
            Assert.fail();
        } catch(DmlException de) {
            Assert.isTrue(de.getMessage().contains('Binding for "TestData.AbstractTest" with action "Test" already exists'));
        }

        try {
            insert new Binding__c(
                    Type__c = TestData.TestInterface.class.getName(),
                    Action__c = 'ValidationTest',
                    Implementation__c = User.class.getName()
            );
            Assert.fail();
        } catch(DmlException de) {
            Assert.isTrue(de.getMessage().contains('Type "User" does not implement "TestInterface"'));
        }

        try {
            insert new Binding__c(
                    Type__c = TestData.AbstractTest.class.getName(),
                    Action__c = 'ValidationTest',
                    Implementation__c = User.class.getName()
            );
            Assert.fail();
        } catch(DmlException de) {
            Assert.isTrue(de.getMessage().contains('Type "User" does not extend "AbstractTest"'));
        }

        try {
            insert new Binding__c(
                    Type__c = User.class.getName(),
                    Action__c = 'ValidationTest',
                    Implementation__c = User.class.getName()
            );
            Assert.fail();
        } catch(DmlException de) {
            Assert.isTrue(de.getMessage().contains('Type "User" must not be instantiable'));
        }

        try {
            insert new Binding__c(
                    Type__c = TestData.TestInterface.class.getName(),
                    Action__c = 'ValidationTest',
                    Implementation__c = TestData.AbstractTest.class.getName()
            );
            Assert.fail();
        } catch(DmlException de) {
            Assert.isTrue(de.getMessage().contains('Implementation "TestData.AbstractTest" must be instantiable'));
        }
    }

    @IsTest
    static void testInvalidUpdates() {
        testValidInserts();

        try {
            binding1.Type__c = TestData.AbstractTest.class.getName();
            upsert binding1;
            Assert.fail();
        } catch(DmlException de) {
            Assert.isTrue(de.getMessage().contains('Binding for "TestData.AbstractTest" already exists'));
        }

        try {
            binding2.Type__c = TestData.TestInterface.class.getName();
            binding2.Action__c = null;
            binding3.Action__c = null;
            upsert new List<Binding__c>{
                    binding2, binding3
            };
            Assert.fail();
        } catch(DmlException de) {
            Assert.isTrue(de.getMessage().contains('Binding for "TestData.TestInterface" already exists'));
        }

        try {
            binding1.Action__c = 'Test';
            upsert binding1;
            Assert.fail();
        } catch(DmlException de) {
            Assert.isTrue(de.getMessage().contains('Binding for "TestData.AbstractTest" with action "Test" already exists'));
        }
    }
}