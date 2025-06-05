/**
 * @description
 * @author Mark Brennand
 */
@IsTest
public with sharing class MockerTests {

    @IsTest
    private static void testThrows() {
        try {
            Mocker mocked = (Mocker) Mocker.of(Mocker.class)
                    .whenNoArguments()
                    .expectMethod('mock').throws(new DMLException('Test'))
                    .mock();

            mocked.mock();
            Assert.fail();
        } catch (DMLException de) {
            Assert.areEqual('Test', de.getMessage());
        }
    }

    @IsTest
    private static void testReturns() {
        Mocker mocked = (Mocker) Mocker.of(Mocker.class)
                .whenNoArguments()
                .expectMethod('mock').returns(123)
                .mock();

        Assert.areEqual(123, mocked.mock());
        Mocker.validate();

        mocked = (Mocker) Mocker.of(Mocker.class)
                .whenNoArguments()
                .expectMethod('mock').returns(new TestModifier())
                .mock();

        Assert.areEqual(456, mocked.mock());
        Mocker.validate();

        try {
            Mocker.of(Mocker.class)
                    .whenNoArguments()
                    .expectMethod('mock').returns(123).returns(new TestModifier())
                    .mock();

            Assert.fail();

        } catch (Assertion.AssertionException ae) {}
    }

    @IsTest
    private static void testUnboundedCalls() {
        Mocker mocked = (Mocker) Mocker.of(Mocker.class)
                .whenNoArguments()
                    .expectMethod('mock').returns(123)
                .mock();

        Assert.areEqual(123, mocked.mock());
        Assert.areEqual(123, mocked.mock());
        Assert.areEqual(123, mocked.mock());
        Mocker.validate();
    }

    @IsTest
    private static void testBoundedCalls() {
        Mocker mocked = (Mocker) Mocker.of(Mocker.class)
                .whenNoArguments()
                    .expectMethod('mock').called(2).returns(123)
                .mock();

        Assert.areEqual(123, mocked.mock());
        try {
            Mocker.validate();
        } catch(Assertion.AssertionException ae) {}

        Assert.areEqual(123, mocked.mock());
        Mocker.validate();

        Assert.areEqual(123, mocked.mock());
        try {
            Mocker.validate();
        } catch(Assertion.AssertionException ae) {}
    }

    @IsTest
    private static void testSObjectMatching() {
        Account a1 = new Account(Id = Mocker.fakeId(Account.SObjectType), Name='Bill');
        Account a2 = new Account(Id = a1.Id, Name='Bill', AccountNumber = '123');
        Account a3 = new Account(Id = a1.Id, Name='Ted');

        Mocker mocked = (Mocker) Mocker.of(Mocker.class)
                .whenArgument(a1)
                    .expectMethod('whenArgument')
                .mock();

        mocked.whenArgument(a1);
        mocked.whenArgument(a2);
        try {
            mocked.whenArgument(a3);
            Assert.fail();
        } catch(Assertion.AssertionException ae) {}

        mocked = (Mocker) Mocker.of(Mocker.class)
                .whenArgument(new List<Account> { a1, a3})
                    .expectMethod('whenArgument')
                .mock();

        mocked.whenArgument(new List<Account> { a1, a3 });
        mocked.whenArgument(new List<Account> { a2, a3 });
        try {
            mocked.whenArgument(new List<Account> { a1 });
            Assert.fail();
        } catch(Assertion.AssertionException ae) {}

        mocked = (Mocker) Mocker.of(Mocker.class)
                .whenArgument(new List<Account> { a2, a3})
                    .expectMethod('whenArgument')
                .mock();

        mocked.whenArgument(new List<Account> { a2, a3 });
        try {
            mocked.whenArgument(new List<Account> { a1, a3 });
            Assert.fail();
        } catch(Assertion.AssertionException ae) {}
    }

    @IsTest
    private static void testChaining() {
        Account a1 = new Account(Id = Mocker.fakeId(Account.SObjectType), Name='Bill');
        Account a2 = new Account(Id = a1.Id, Name='Ted', AccountNumber = '123');

        Mocker mocked = (Mocker) Mocker.of(Mocker.class)
                .whenArgument(a1)
                    .expectMethod('whenArgument').called(1)
                    .expectMethod('whenArguments').called(0)
                .whenArgument(a2)
                    .expectMethod('whenArgument').called(1)
                .whenNoArguments()
                    .expectMethod('mock').called(2).returns(123)
                .whenArguments(1, 2)
                .whenArguments(1, 2, 3)
                .whenArguments(1, 2, 3, 4)
                .whenArguments(1, 2, 3, 4, 5)
                .mock();

        mocked.whenArgument(a1);
        mocked.whenArgument(a2);
        Assert.areEqual(123, mocked.mock());
        Assert.areEqual(123, mocked.mock());

        Mocker.validate();
    }

    @IsTest
    private static void testFactory() {
        Account a1 = new Account(Id = Mocker.fakeId(Account.SObjectType), Name='Bill');
        Account a2 = new Account(Id = a1.Id, Name='Ted', AccountNumber = '123');

        Mocker mocked = (Mocker) Mocker.of(new TestFactory())
                .whenArgument(a1)
                .expectMethod('whenArgument').called(1)
                .expectMethod('whenArguments').called(0)
                .whenArgument(a2)
                .expectMethod('whenArgument').called(1)
                .whenNoArguments()
                .expectMethod('mock').called(2).returns(123)
                .whenArguments(1, 2)
                .whenArguments(1, 2, 3)
                .whenArguments(1, 2, 3, 4)
                .whenArguments(1, 2, 3, 4, 5)
                .mock();

        mocked.whenArgument(a1);
        mocked.whenArgument(a2);
        Assert.areEqual(123, mocked.mock());
        Assert.areEqual(123, mocked.mock());

        Mocker.validate();
    }

    @IsTest
    private static void testComparator() {
        Account a1 = new Account(Id = Mocker.fakeId(Account.SObjectType), Name = 'Bill');

        Mocker mocked = (Mocker) Mocker.of(Mocker.class)
                .whenArgument(a1)
                .withComparators(new List<Comparator<Object>> { new TestComparator() })
                .expectMethod('whenArgument').called(1)
                .mock();

        mocked.whenArgument(new Account(Name = 'Bill'));

        try {
            mocked = (Mocker) Mocker.of(Mocker.class)
                    .whenArgument(a1)
                    .expectMethod('whenArgument').called(1)
                    .mock();

            mocked.whenArgument(new Account(Name = 'Bill'));

        } catch(Assertion.AssertionException ae) {}
    }

    @IsTest
    private static void testFakeId() {
        Assert.isTrue(Mocker.fakeId(User.SObjectType).endsWith('001'));
        Assert.isTrue(Mocker.fakeId(Account.SObjectType).endsWith('001'));
        Assert.isTrue(Mocker.fakeId(Account.SObjectType).endsWith('002'));
        Assert.isTrue(Mocker.fakeId(User.SObjectType).endsWith('002'));
        Assert.isTrue(Mocker.fakeId(Account.SObjectType).endsWith('003'));
    }

    private with sharing class TestModifier implements Mocker.Modifier {
        public Object process(List<Object> arguments) {
            return 456;
        }
    }

    private with sharing class TestComparator implements Comparator<Object> {
        public Integer compare(Object param1, Object param2) {
            return ((Account) param1).Name == ((Account) param2).Name ? 0 : -1;
        }
    }

    private with sharing class TestFactory implements Mocker.Factory {
        public Object stub(StubProvider provider) {
            return Test.createStub(Mocker.class, provider);
        }
    }
}