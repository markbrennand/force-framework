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
        MockerTestAPI mockedAPI = (MockerTestApi) Mocker.of(MockerTestAPI.class)

                // The method being mocked has no arguments.
                .whenNoArguments()

                    // Its name is getCurrentTime.
                    .expectMethod('getCurrentTime')

                        // It will be called once.
                        .called(1)

                        // And will return the current time when called.
                        .returns(Datetime.now())

                // Build the mock for the class.
                .mock();

        Assert.isTrue(Datetime.now() >= mockedAPI.getCurrentTime());

        // Check that the mocked method has been called the correct number of times.
        Mocker.validate();
    }

    /**
    * @description
    * This test shows how a method can be mocked to throw an Exception when it is called.
    */
    @IsTest
    private static void testExceptionThrown() {
        Exception exc = new DmlException('Test');

        MockerTestAPI mockedAPI = (MockerTestApi) Mocker.of(MockerTestAPI.class)

                // The method being mocked has no arguments.
                .whenNoArguments()

                    // Its name is getCurrentTime.
                    .expectMethod('getCurrentTime')

                        // It will be called once.
                        .called(1)

                        // And will throw an Exception when called.
                        .throws(exc)

                // Build the mock for the class.
                .mock();

        try {
            mockedAPI.getCurrentTime();
            Assert.fail();
        } catch(DmlException de) {
            Assert.areEqual(exc, de);
        }

        // Check that the mocked method has been called the correct number of times.
        Mocker.validate();
    }

    @IsTest
    private static void testTwoMethodsWithSameArguments() {
        MockerTestAPI mockedAPI = (MockerTestApi) Mocker.of(MockerTestAPI.class)

                // The methods being mocked have no arguments.
                .whenNoArguments()

                    // The first method is getCurrentTime.
                    .expectMethod('getCurrentTime')

                        // It will be called once.
                        .called(1)

                        // And will return the current time when called.
                        .returns(Datetime.now())

                    // The first method is getOrganizationId
                    .expectMethod('getOrganizationId')

                        // It will be called once.
                        .called(1)

                        // And will return a mocked Id for the Organization when called.
                        .returns(Mocker.fakeId(Organization.SObjectType))

                // Build the mock for the class.
                .mock();


        Assert.isTrue(Datetime.now() >= mockedAPI.getCurrentTime());
        Assert.isTrue(mockedAPI.getOrganizationId().endsWith('01'));

        // Check that the mocked method has been called the correct number of times.
        Mocker.validate();
    }

    /**
    * @description
    * This test shows how a Comparator can be used to validate that the arguments passed to the mocked method
    * match the arguments registered in the mock.
    */
    @IsTest
    private static void testUserDefinedComparator() {
        Exception exc = new DmlException('Test');

        MockerTestAPI mockedAPI = (MockerTestApi) Mocker.of(MockerTestAPI.class)

                // The method being mocked takes an Exception as argument.
                .whenArgument(exc)

                    // Add a Comparator that will match any exception of type DMLException.
                    // The default Comparator for Exception would check that the type of Exception and its message
                    // match those in the argument passed to a mocked method. The default Comparator would fail
                    // to match the Exception passed as argument to the call as their message differs.
                    .withComparators(new List<Comparator<Object>> { new ExceptionComparator() })

                    // The method to match is processError.
                    .expectMethod('processError')

                        // It will be called once.
                        .called(1)

                // Build the mock for the class.
                .mock();

        mockedAPI.processError(new DMLException('Another Test'));

        // Check that the mocked method has been called the correct number of times.
        Mocker.validate();
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

        MockerTestAPI mockedAPI = (MockerTestApi) Mocker.of(MockerTestAPI.class)

                // The method being mocked takes a List of Accounts as argument.
                // In this case only Accounts matching a Name of Bill will be matched in the arguments to the method.
                // Partial SObject matching only checks the fields in the List of Arguments against those in the
                // arguments to the method call. The AccountNumber and BillingCountry fields will be ignored.
                .whenArgument(new List<Account> {
                        new Account(Name = 'Bill')
                })

                    // The method to match is addAccounts.
                    .expectMethod('addAccounts')

                    // It will be called once.
                    .called(1)

                    // And it will return a result determined from a Modifier.
                    .returns(new AccountModifier())

                // Build the mock for the class.
                .mock();

        List<Account> result = mockedAPI.addAccounts(new List<Account> { a1 });
        Assert.areEqual(1, result.size());

        // The Modifier will have added a fake Id to the matching Account.
        Assert.isNotNull(result[0].Id);

        // Check that the mocked method has been called the correct number of times.
        Mocker.validate();
    }

    private class ExceptionComparator implements Comparator<Object> {
        public Integer compare(Object param1, Object param2) {
            return (param1 instanceof DmlException && param2 instanceof DmlException) ? 0 : -1;
        }
    }

    private class AccountModifier implements Mocker.Modifier {
        public Object process(List<Object> arguments) {
            List<Account> returnList = new List<Account>();
            for (Account acc : (List<Account>) arguments[0]) {
                Account copy = acc.clone();
                copy.Id = Mocker.fakeId(Account.SObjectType);
                returnList.add(copy);
            }

            return returnList;
        }
    }
}