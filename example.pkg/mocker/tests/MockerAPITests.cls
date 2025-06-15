/**
 * @description
 * Example of how mocking can be used to test an interface without having to code the interface.
 *
 * @author Mark Brennand
 */
@IsTest
public with sharing class MockerAPITests {

    /**
     * @description
     * This test shows the simple mocking of a method in a class or interface.
     */
    @IsTest
    private static void testGetCurrentTime() {

        // Create a mocked API for the getCurrentTime method that will return the current date and time when called.
        // The method must be called once.
        MockerTestAPI mockedAPI = (MockerTestAPI) forcefw.MockerV1.of(new MockerFactory())
                .whenNoArguments()
                    .forMethod('getCurrentTime')
                        .called(1)
                        .returns(Datetime.now())
                .mock();

        Assert.isTrue(Datetime.now() >= mockedAPI.getCurrentTime());

        // Check that the mocked method has been called the correct number of times.
        forcefw.MockerV1.validate();
    }

    /**
    * @description
    * This test shows how a method can be mocked to throw an Exception when it is called.
    */
    @IsTest
    private static void testExceptionThrown() {
        Exception exc = new DmlException('Test');

        // Create a mocked API for the getCurrentTime method that throws an Exception when called.
        // The method must be called once.
        MockerTestAPI mockedAPI = (MockerTestAPI) forcefw.MockerV1.of(new MockerFactory())
                .whenNoArguments()
                    .forMethod('getCurrentTime')
                        .called(1)
                        .throws(exc)
                .mock();

        try {
            mockedAPI.getCurrentTime();
            Assert.fail();
        } catch(DmlException de) {
            Assert.areEqual(exc, de);
        }

        // Check that the mocked method has been called the correct number of times.
        forcefw.MockerV1.validate();
    }

    /**
     * @description
     * This test shows how the same arguments can be used to mock two methods.
     */
    @IsTest
    private static void testTwoMethodsWithSameArguments() {

        // Create a mocked API for the getCurrentTime and getOrganizationId methods.
        // Both methods should be called once.
        MockerTestAPI mockedAPI = (MockerTestAPI) forcefw.MockerV1.of(new MockerFactory())
                .whenNoArguments()
                    .forMethod('getCurrentTime')
                        .called(1)
                        .returns(Datetime.now())
                    .forMethod('getOrganizationId')
                        .called(1)
                        .returns(forcefw.MockerV1.fakeId(Organization.SObjectType))
                .mock();


        Assert.isTrue(Datetime.now() >= mockedAPI.getCurrentTime());
        Assert.isTrue(mockedAPI.getOrganizationId().endsWith('01'));

        // Check that the mocked method has been called the correct number of times.
        forcefw.MockerV1.validate();
    }

    /**
    * @description
    * This test shows how a Comparator can be used to validate that the arguments passed to the mocked method
    * match the arguments registered in the mock.
    */
    @IsTest
    private static void testUserDefinedComparator() {
        Exception exc = new DmlException('Test');

        // Create a mocked API for the setCurrentTime method.
        // A Datetime comparator is registered for the argument which checks that only the Type of the arguments match.
        // The method must be called once.
        MockerTestAPI mockedAPI = (MockerTestAPI) forcefw.MockerV1.of(new MockerFactory())
                .whenArgument(Datetime.now())
                    .withComparators(new List<Comparator<Object>> { new DatetimeComparator() })
                        .forMethod('setCurrentTime')
                            .called(1)
                .mock();

        // Pass a date which cannot match that of the argument set for the mocked method.
        mockedAPI.setCurrentTime(Datetime.now().addDays(1));

        // Check that the mocked method has been called the correct number of times.
        forcefw.MockerV1.validate();
    }

    /**
     * @description
     * This test shows how to use a Mocker.Modifier to change the return value from a mocked method based on the
     * arguments passed to the method.
     */
    @IsTest
    private static void testModifier() {
        Account a1 = new Account(Name = 'Bill', AccountNumber = '1', BillingCountry = 'UK');

        // Create a mocked API for the addAccounts method.
        // Set the return value to a Modifier which will create a fake object Id for the Account objects passed to the method.
        // The method must be called once.
        MockerTestAPI mockedAPI = (MockerTestAPI) forcefw.MockerV1.of(new MockerFactory())
                .whenArgument(new List<Account> { new Account(Name = 'Bill') })
                    .forMethod('addAccounts')
                        .called(1)
                        .returns(new AccountModifier())
            .mock();

        List<Account> result = mockedAPI.addAccounts(new List<Account> { a1 });
        Assert.areEqual(1, result.size());

        // The Modifier will have added a fake Id to the matching Account.
        Assert.isNotNull(result[0].Id);

        // Check that the mocked method has been called the correct number of times.
        forcefw.MockerV1.validate();
    }

    /**
     * @description
     * This test shows exhibits partial matching on SObject content and how a Modifier can be used to
     * return a result based on the arguments passed to the mocked method.
     */
    @IsTest
    private static void testSObjectPartialMatching() {
        Account a1 = new Account(Name = 'Bill', AccountNumber = '1', BillingCountry = 'UK');
        Account a2 = new Account(Name = 'Ted', AccountNumber = '2', BillingCountry = 'UK');

        // Create a mocked API for the addAccounts method.
        // Set the arguments to match only Accounts with a Name of Bill. The partial matching of the SObjects
        // in the whenArguments call will result in other fields of the actual arguments passed to the method
        // not being included when matching the arguments.
        // The method must be called once.
        MockerTestAPI mockedAPI = (MockerTestAPI) forcefw.MockerV1.of(new MockerFactory())
                .whenArgument(new List<Account> { new Account(Name = 'Bill') })
                    .forMethod('addAccounts')
                        .called(1)
                        .returns(new AccountModifier())
                .mock();

        List<Account> result = mockedAPI.addAccounts(new List<Account> { a1 });
        Assert.areEqual(1, result.size());
        Assert.isNotNull(result[0].Id);

        // Check that the mocked method has been called the correct number of times.
        forcefw.MockerV1.validate();

        // Create a mocked API for the addAccounts method.
        // Set the arguments to match Accounts with a BillingCountry of UK. The partial matching of the SObjects
        // in the whenArguments call will result in other fields of the actual arguments passed to the method
        // not being included when matching the arguments.
        // The method must be called once.
        mockedAPI = (MockerTestAPI) forcefw.MockerV1.of(new MockerFactory())
                .whenArgument(new List<Account> {
                        new Account(BillingCountry = 'UK'),
                        new Account(BillingCountry = 'UK')
                })
                    .forMethod('addAccounts')
                        .called(1)
                        .returns(new AccountModifier())
                .mock();

        result = mockedAPI.addAccounts(new List<Account> { a1, a2 });
        Assert.areEqual(2, result.size());
        Assert.isNotNull(result[0].Id);
        Assert.isNotNull(result[1].Id);

        // Check that the mocked method has been called the correct number of times.
        forcefw.MockerV1.validate();
    }

    /**
     * @description
     * Test showing the mocked API can be used by a service class as if it were the live implementation.
     */
    @IsTest
    private static void testWhenUsedByService() {
        Account a1 = new Account(Name = 'Bill', AccountNumber = '1', BillingCountry = 'UK');
        Account a2 = new Account(Name = 'Ted', AccountNumber = '2', BillingCountry = 'UK');

        // Create a mocked API for the addAccounts method.
        MockerTestAPI mockedAPI = (MockerTestAPI) forcefw.MockerV1.of(new MockerFactory())
                .whenArgument(new List<Account> { new Account(Name = 'Bill') })
                    .forMethod('addAccounts')
                        .called(1)
                        .returns(new AccountModifier())
                .whenArgument(new List<Account> {
                        new Account(BillingCountry = 'UK'),
                        new Account(BillingCountry = 'UK')
                })
                    .forMethod('addAccounts')
                        .called(2)
                        .returns(new AccountModifier())
                .whenNoArguments()
                    .forMethod('getCurrentTime')
                        .called(5)
                        .returns(Datetime.now())
                .mock();

        ExampleService service = new ExampleService(mockedAPI);
        List<Account> result = service.addAccounts(new List<Account> { a1 });
        Assert.areEqual(1, result.size());
        Assert.isNotNull(result[0].Id);

        result = service.addAccounts(new List<Account> { a1, a2 });
        Assert.areEqual(2, result.size());
        Assert.isNotNull(result[0].Id);
        Assert.isNotNull(result[1].Id);

        result = service.addAccounts(new List<Account> { a1, a2 });
        Assert.areEqual(2, result.size());
        Assert.isNotNull(result[0].Id);
        Assert.isNotNull(result[1].Id);

        // Check that the mocked method has been called the correct number of times.
        forcefw.MockerV1.validate();
    }

    private with sharing class DatetimeComparator implements Comparator<Object> {
        public Integer compare(Object param1, Object param2) {
            return (param1 instanceof Datetime && param2 instanceof Datetime) ? 0 : -1;
        }
    }

    private with sharing class AccountModifier implements forcefw.MockerV1.Modifier {
        public Object process(List<Object> arguments) {
            List<Account> returnList = new List<Account>();
            for (Account acc : (List<Account>) arguments[0]) {
                Account copy = acc.clone();
                copy.Id = forcefw.MockerV1.fakeId(Account.SObjectType);
                returnList.add(copy);
            }

            return returnList;
        }
    }

    private with sharing class ExampleService {
        private final MockerTestAPI api;

        public ExampleService(MockerTestAPI api) {
            this.api = api;
        }

        public List<Account> addAccounts(List<Account> accounts) {
            for (Account account : accounts) {
                account.AccountSource = String.valueOf(api.getCurrentTime());
            }
            return api.addAccounts(accounts);
        }
    }

    public with sharing class MockerFactory implements forcefw.MockerV1.Factory {
        public Object stub(final StubProvider provider) {
            return Test.createStub(MockerTestAPI.class, provider);
        }
    }
}