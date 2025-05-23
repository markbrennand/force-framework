/**
 * @description
 * @author Mark Brennand
 */
@IsTest
public with sharing class MockerUnitTests {

    @IsTest
    private static void testThrows() {
        try {
            Mocker mocked = Mocker.of(Mocker.class);
            mocked.whenNoArguments().expectMethod('getMockedObject').throws(new DMLException('Test'));
            ((Mocker) mocked.getMockedObject()).getMockedObject();
            Assert.fail();
        } catch(DMLException de) {
            Assert.areEqual('Test', de.getMessage());
        }
    }

    @IsTest
    private static void testUnboundedCalls() {
        Mocker mocked = Mocker.of(Mocker.class);
        mocked.whenNoArguments().expectMethod('getMockedObject').returns(123);

        Assert.areEqual(123, ((Mocker) mocked.getMockedObject()).getMockedObject());
        Assert.areEqual(123, ((Mocker) mocked.getMockedObject()).getMockedObject());
        Assert.areEqual(123, ((Mocker) mocked.getMockedObject()).getMockedObject());
        Mocker.validate();
    }

    @IsTest
    private static void testBoundedCalls() {
        Mocker mocked = Mocker.of(Mocker.class);
        mocked
                .whenNoArguments()
                    .expectMethod('getMockedObject').called(2).returns(123);

        Assert.areEqual(123, ((Mocker) mocked.getMockedObject()).getMockedObject());
        try {
            Mocker.validate();
        } catch(Assertion.AssertionException ae) {}

        Assert.areEqual(123, ((Mocker) mocked.getMockedObject()).getMockedObject());
        Mocker.validate();

        Assert.areEqual(123, ((Mocker) mocked.getMockedObject()).getMockedObject());
        try {
            Mocker.validate();
        } catch(Assertion.AssertionException ae) {}
    }

    @IsTest
    private static void testSObjectMatching() {
        Account a1 = new Account(Id = TestHelper.nextId(Account.SObjectType), Name='Bill');
        Account a2 = new Account(Id = a1.Id, Name='Bill', AccountNumber = '123');
        Account a3 = new Account(Id = a1.Id, Name='Ted');

        Mocker mocked = Mocker.of(Mocker.class);
        mocked
                .whenArgument(a1)
                .expectMethod('whenArgument');

        ((Mocker) mocked.getMockedObject()).whenArgument(a1);
        ((Mocker) mocked.getMockedObject()).whenArgument(a2);
        try {
            ((Mocker) mocked.getMockedObject()).whenArgument(a3);
            Assert.fail();
        } catch(Assertion.AssertionException ae) {}

        mocked = Mocker.of(Mocker.class);
        mocked
                .whenArgument(new List<Account> { a1, a3})
                .expectMethod('whenArgument');

        ((Mocker) mocked.getMockedObject()).whenArgument(new List<Account> { a1, a3 });
        ((Mocker) mocked.getMockedObject()).whenArgument(new List<Account> { a2, a3 });
        try {
            ((Mocker) mocked.getMockedObject()).whenArgument(new List<Account> { a1 });
            Assert.fail();
        } catch(Assertion.AssertionException ae) {}

        mocked = Mocker.of(Mocker.class);
        mocked
                .whenArgument(new List<Account> { a2, a3})
                .expectMethod('whenArgument');

        ((Mocker) mocked.getMockedObject()).whenArgument(new List<Account> { a2, a3 });
        try {
            ((Mocker) mocked.getMockedObject()).whenArgument(new List<Account> { a1, a3 });
            Assert.fail();
        } catch(Assertion.AssertionException ae) {}
    }

    @IsTest
    private static void testChaining() {
        Account a1 = new Account(Id = TestHelper.nextId(Account.SObjectType), Name='Bill');
        Account a2 = new Account(Id = a1.Id, Name='Ted', AccountNumber = '123');

        Mocker mocked = Mocker.of(Mocker.class);
        mocked
                .whenArgument(a1)
                    .expectMethod('whenArgument').called(1)
                .whenArgument(a2)
                    .expectMethod('whenArgument').called(1)
                .whenNoArguments()
                    .expectMethod('getMockedObject').called(2).returns(123);

        ((Mocker) mocked.getMockedObject()).whenArgument(a1);
        ((Mocker) mocked.getMockedObject()).whenArgument(a2);
        Assert.areEqual(123, ((Mocker) mocked.getMockedObject()).getMockedObject());
        Assert.areEqual(123, ((Mocker) mocked.getMockedObject()).getMockedObject());

        Mocker.validate();
    }
}