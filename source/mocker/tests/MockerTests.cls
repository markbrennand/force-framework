/**
 * @description
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../LICENSE target="_blank">MIT License</a>.
 * <br><br>
 * Unit tests for MockerV1 class.
 *
 * @author Mark Brennand
 */
@IsTest
public with sharing class MockerTests {
    private final static String TESTING = 'mocker';

    @TestSetup
    private static void createUsers() {
        TestHelper.createUsers(TESTING, new Set<String>());
    }

    @IsTest
    private static void testThrows() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            try {
                MockerV1 mocked = (MockerV1) MockerV1.of(MockerV1.class)
                        .whenNoArguments()
                        .forMethod('mock')
                        .throws(new DMLException('Test'))
                        .mock();

                mocked.mock();
                Assert.fail();
            } catch (DMLException de) {
                Assert.areEqual('Test', de.getMessage());
            }
        }
    }

    @IsTest
    @SuppressWarnings('PMD.EmptyCatchBlock')
    private static void testReturns() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            MockerV1 mocked = (MockerV1) MockerV1.of(MockerV1.class)
                    .whenNoArguments()
                    .forMethod('mock')
                    .returns(123)
                    .mock();

            Assert.areEqual(123, mocked.mock());
            MockerV1.validate();

            mocked = (MockerV1) MockerV1.of(MockerV1.class)
                    .whenNoArguments()
                    .forMethod('mock')
                    .returns(new TestModifier())
                    .mock();

            Assert.areEqual(456, mocked.mock());
            MockerV1.validate();

            try {
                MockerV1.of(MockerV1.class)
                        .whenNoArguments()
                        .forMethod('mock')
                        .returns(123)
                        .returns(new TestModifier())
                        .mock();

                Assert.fail();

            } catch (AssertionV1.AssertionException ae) {
            }
        }
    }

    @IsTest
    private static void testUnboundedCalls() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            MockerV1 mocked = (MockerV1) MockerV1.of(MockerV1.class)
                    .whenNoArguments()
                    .forMethod('mock')
                    .returns(123)
                    .mock();

            Assert.areEqual(123, mocked.mock());
            Assert.areEqual(123, mocked.mock());
            Assert.areEqual(123, mocked.mock());
            MockerV1.validate();
        }
    }

    @IsTest
    @SuppressWarnings('PMD.EmptyCatchBlock')
    private static void testBoundedCalls() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            MockerV1 mocked = (MockerV1) MockerV1.of(MockerV1.class)
                    .whenNoArguments()
                    .forMethod('mock')
                    .called(2)
                    .returns(123)
                    .mock();

            Assert.areEqual(123, mocked.mock());
            try {
                MockerV1.validate();
            } catch (AssertionV1.AssertionException ae) {
            }

            Assert.areEqual(123, mocked.mock());
            MockerV1.validate();

            Assert.areEqual(123, mocked.mock());
            try {
                MockerV1.validate();
            } catch (AssertionV1.AssertionException ae) {
            }
        }
    }

    @IsTest
    @SuppressWarnings('PMD.EmptyCatchBlock')
    private static void testSObjectMatching() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            Account a1 = new Account(Id = MockerV1.fakeId(Account.SObjectType), Name='Bill');
            Account a2 = new Account(Id = a1.Id, Name='Bill', AccountNumber = '123');
            Account a3 = new Account(Id = a1.Id, Name='Ted');

            MockerV1 mocked = (MockerV1) MockerV1.of(MockerV1.class)
                    .whenArgument(a1)
                    .forMethod('whenArgument')
                    .mock();

            mocked.whenArgument(a1);
            mocked.whenArgument(a2);
            try {
                mocked.whenArgument(a3);
                Assert.fail();
            } catch(AssertionV1.AssertionException ae) {}

            mocked = (MockerV1) MockerV1.of(MockerV1.class)
                    .whenArgument(new List<Account> { a1, a3})
                    .forMethod('whenArgument')
                    .mock();

            mocked.whenArgument(new List<Account> { a1, a3 });
            mocked.whenArgument(new List<Account> { a2, a3 });
            try {
                mocked.whenArgument(new List<Account> { a1 });
                Assert.fail();
            } catch(AssertionV1.AssertionException ae) {}

            mocked = (MockerV1) MockerV1.of(MockerV1.class)
                    .whenArgument(new List<Account> { a2, a3})
                    .forMethod('whenArgument')
                    .mock();

            mocked.whenArgument(new List<Account> { a2, a3 });
            try {
                mocked.whenArgument(new List<Account> { a1, a3 });
                Assert.fail();
            } catch(AssertionV1.AssertionException ae) {}
        }
    }

    @IsTest
    @SuppressWarnings('PMD.EmptyCatchBlock')
    private static void testAnyMatching() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            Account a1 = new Account(Id = MockerV1.fakeId(Account.SObjectType), Name='Bill');
            Account a2 = new Account(Id = a1.Id, Name='Bill', AccountNumber = '123');
            Account a3 = new Account(Id = a1.Id, Name='Ted');

            MockerV1 mocked = (MockerV1) MockerV1.of(MockerV1.class)
                    .whenArgument(MockerV1.any(Object.class))
                    .forMethod('whenArgument')
                    .mock();

            mocked.whenArgument(a1);
            mocked.whenArgument(a2);
            mocked.whenArgument(a3);
            mocked.whenArgument(null);

            mocked = (MockerV1) MockerV1.of(MockerV1.class)
                    .whenArguments(MockerV1.any(Object.class), a3)
                    .forMethod('whenArguments')
                    .mock();

            mocked.whenArguments(a1, a3);
            mocked.whenArguments(a2, a3);
            mocked.whenArguments(a3, a3);

            try {
                mocked.whenArgument(new List<Account> { a1, a2 });
                Assert.fail();
            } catch(AssertionV1.AssertionException ae) {}

            mocked = (MockerV1) MockerV1.of(MockerV1.class)
                    .whenArgument(MockerV1.anyNonNull(Object.class))
                    .forMethod('whenArgument')
                    .mock();

            mocked.whenArgument(a1);

            try {
                mocked.whenArgument(null);
                Assert.fail();
            } catch(AssertionV1.AssertionException ae) {}
        }
    }

    @IsTest
    private static void testChaining() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            Account a1 = new Account(Id = MockerV1.fakeId(Account.SObjectType), Name='Bill');
            Account a2 = new Account(Id = a1.Id, Name='Ted', AccountNumber = '123');

            MockerV1 mocked = (MockerV1) MockerV1.of(MockerV1.class)
                    .whenArgument(a1)
                    .forMethod('whenArgument').called(1)
                    .forMethod('whenArguments').called(0)
                    .whenArgument(a2)
                    .forMethod('whenArgument').called(1)
                    .whenNoArguments()
                    .forMethod('mock').called(2).returns(123)
                    .whenArguments(1, 2)
                    .whenArguments(1, 2, 3)
                    .whenArguments(1, 2, 3, 4)
                    .whenArguments(1, 2, 3, 4, 5)
                    .mock();

            mocked.whenArgument(a1);
            mocked.whenArgument(a2);
            Assert.areEqual(123, mocked.mock());
            Assert.areEqual(123, mocked.mock());

            MockerV1.validate();
        }
    }

    @IsTest
    private static void testFactory() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            Account a1 = new Account(Id = MockerV1.fakeId(Account.SObjectType), Name='Bill');
            Account a2 = new Account(Id = a1.Id, Name='Ted', AccountNumber = '123');

            MockerV1 mocked = (MockerV1) MockerV1.of(new TestFactory())
                    .whenArgument(a1)
                    .forMethod('whenArgument')
                    .called(1)
                    .forMethod('whenArguments')
                    .called(0)
                    .whenArgument(a2)
                    .forMethod('whenArgument').called(1)
                    .whenNoArguments()
                    .forMethod('mock')
                    .called(2)
                    .returns(123)
                    .whenArguments(1, 2)
                    .whenArguments(1, 2, 3)
                    .whenArguments(1, 2, 3, 4)
                    .whenArguments(1, 2, 3, 4, 5)
                    .mock();

            mocked.whenArgument(a1);
            mocked.whenArgument(a2);
            Assert.areEqual(123, mocked.mock());
            Assert.areEqual(123, mocked.mock());

            MockerV1.validate();
        }
    }

    @IsTest
    @SuppressWarnings('PMD.EmptyCatchBlock,PMD.ApexUnitTestClassShouldHaveAsserts')
    private static void testComparator() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            Account a1 = new Account(Id = MockerV1.fakeId(Account.SObjectType), Name = 'Bill');

            MockerV1 mocked = (MockerV1) MockerV1.of(MockerV1.class)
                    .whenArgument(a1)
                    .withComparators(new List<Comparator<Object>> { new TestComparator() })
                    .forMethod('whenArgument')
                    .called(1)
                    .mock();

            mocked.whenArgument(new Account(Name = 'Bill'));

            try {
                mocked = (MockerV1) MockerV1.of(MockerV1.class)
                        .whenArgument(a1)
                        .forMethod('whenArgument')
                        .called(1)
                        .mock();

                mocked.whenArgument(new Account(Name = 'Bill'));

            } catch(AssertionV1.AssertionException ae) {}
        }
    }

    @IsTest
    private static void testFakeId() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            Assert.isTrue(MockerV1.fakeId(User.SObjectType).endsWith('001'));
            Assert.isTrue(MockerV1.fakeId(Account.SObjectType).endsWith('001'));
            Assert.isTrue(MockerV1.fakeId(Account.SObjectType).endsWith('002'));
            Assert.isTrue(MockerV1.fakeId(User.SObjectType).endsWith('002'));
            Assert.isTrue(MockerV1.fakeId(Account.SObjectType).endsWith('003'));
        }
    }

    @SuppressWarnings('PMD.ApexDoc')
    private with sharing class TestModifier implements MockerV1.Modifier {
        public Object process(List<Object> arguments) {
            return 456;
        }
    }

    @SuppressWarnings('PMD.ApexDoc')
    private with sharing class TestComparator implements Comparator<Object> {
        public Integer compare(Object param1, Object param2) {
            return ((Account) param1).Name == ((Account) param2).Name ? 0 : -1;
        }
    }

    @SuppressWarnings('PMD.ApexDoc')
    private with sharing class TestFactory implements MockerV1.Factory {
        public Object stub(StubProvider provider) {
            return Test.createStub(MockerV1.class, provider);
        }
    }
}