/**
 * @description
 * @author Mark Brennand
 */
@IsTest
public with sharing class MockerUnitTests {

    @IsTest
    private static void testThrows() {
        try {
            Mocker mocked = (Mocker) Mocker.of(Mocker.class)
                .whenNoArguments()
                    .expectMethod('mock').throws(new DMLException('Test'))
                .mock();

            mocked.mock();
            Assert.fail();
        } catch(DMLException de) {
            Assert.areEqual('Test', de.getMessage());
        }
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
        Account a1 = new Account(Id = TestHelper.nextId(Account.SObjectType), Name='Bill');
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
        Account a1 = new Account(Id = TestHelper.nextId(Account.SObjectType), Name='Bill');
        Account a2 = new Account(Id = a1.Id, Name='Ted', AccountNumber = '123');

        Mocker mocked = (Mocker) Mocker.of(Mocker.class)
                .whenArgument(a1)
                    .expectMethod('whenArgument').called(1)
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
}