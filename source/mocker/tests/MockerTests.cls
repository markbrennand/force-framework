/**
 * @description
 * @author Mark Brennand
 */
@IsTest
public with sharing class MockerTests {

    @IsTest
    private static void testThrows() {
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

    @IsTest
    private static void testReturns() {
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

        } catch (Assertion.AssertionException ae) {}
    }

    @IsTest
    private static void testUnboundedCalls() {
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

    @IsTest
    private static void testBoundedCalls() {
        MockerV1 mocked = (MockerV1) MockerV1.of(MockerV1.class)
                .whenNoArguments()
                    .forMethod('mock')
                        .called(2)
                        .returns(123)
                .mock();

        Assert.areEqual(123, mocked.mock());
        try {
            MockerV1.validate();
        } catch(Assertion.AssertionException ae) {}

        Assert.areEqual(123, mocked.mock());
        MockerV1.validate();

        Assert.areEqual(123, mocked.mock());
        try {
            MockerV1.validate();
        } catch(Assertion.AssertionException ae) {}
    }

    @IsTest
    private static void testSObjectMatching() {
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
        } catch(Assertion.AssertionException ae) {}

        mocked = (MockerV1) MockerV1.of(MockerV1.class)
                .whenArgument(new List<Account> { a1, a3})
                    .forMethod('whenArgument')
                .mock();

        mocked.whenArgument(new List<Account> { a1, a3 });
        mocked.whenArgument(new List<Account> { a2, a3 });
        try {
            mocked.whenArgument(new List<Account> { a1 });
            Assert.fail();
        } catch(Assertion.AssertionException ae) {}

        mocked = (MockerV1) MockerV1.of(MockerV1.class)
                .whenArgument(new List<Account> { a2, a3})
                    .forMethod('whenArgument')
                .mock();

        mocked.whenArgument(new List<Account> { a2, a3 });
        try {
            mocked.whenArgument(new List<Account> { a1, a3 });
            Assert.fail();
        } catch(Assertion.AssertionException ae) {}
    }

    @IsTest
    private static void testAnyMatching() {
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
        } catch(Assertion.AssertionException ae) {}

        mocked = (MockerV1) MockerV1.of(MockerV1.class)
                .whenArgument(MockerV1.anyNonNull(Object.class))
                    .forMethod('whenArgument')
                .mock();

        mocked.whenArgument(a1);

        try {
            mocked.whenArgument(null);
            Assert.fail();
        } catch(Assertion.AssertionException ae) {}
    }

    @IsTest
    private static void testChaining() {
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

    @IsTest
    private static void testFactory() {
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

    @IsTest
    private static void testComparator() {
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

        } catch(Assertion.AssertionException ae) {}
    }

    @IsTest
    private static void testFakeId() {
        Assert.isTrue(MockerV1.fakeId(User.SObjectType).endsWith('001'));
        Assert.isTrue(MockerV1.fakeId(Account.SObjectType).endsWith('001'));
        Assert.isTrue(MockerV1.fakeId(Account.SObjectType).endsWith('002'));
        Assert.isTrue(MockerV1.fakeId(User.SObjectType).endsWith('002'));
        Assert.isTrue(MockerV1.fakeId(Account.SObjectType).endsWith('003'));
    }

    private with sharing class TestModifier implements MockerV1.Modifier {
        public Object process(List<Object> arguments) {
            return 456;
        }
    }

    private with sharing class TestComparator implements Comparator<Object> {
        public Integer compare(Object param1, Object param2) {
            return ((Account) param1).Name == ((Account) param2).Name ? 0 : -1;
        }
    }

    private with sharing class TestFactory implements MockerV1.Factory {
        public Object stub(StubProvider provider) {
            return Test.createStub(MockerV1.class, provider);
        }
    }
}