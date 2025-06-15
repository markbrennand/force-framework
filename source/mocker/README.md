[back](../../README.md)
# Mocker
Many Apex unit tests are more like integration tests than unit tests. How many times do the unit tests you've 
written use DML and SOQL on custom objects? Strictly speaking, such a unit test is an integration test as it
relies on the database to pass. A good unit test should use dependencies, such as the database, that are
abstracted. In that way it can exercise purely the functionality of the class under test. The abstracted
dependencies should be mocked to provide the expected results for the test.

See the reference [Apex docs](SfApexDocs/mockerv1.html) for the API. It is suggested that you keep a page open
with the Apex docs loaded for your reference whilst reading this page.

If you wish to try the _Mocker_ example codehttps://markbrennand.github.io/force-framework/source/mocker/, see [Geting Started](../../GETTINGSTARTED.md).

For an example of a complete suite of unit tests written using _MockerV1_ that test their features in isolation, see
[Asynhcronous Unit Tests](https://github.com/markbrennand/force-frameworks/tree/gh-pages/source/asynchronous/tests)

### Mocker Creation
To mock a class or interface, first call the _MockerV1.of_ method.

The argument to the method can be either the _Type_ to be mocked, or a _MockerV1.Factory_ instance.

To create the mocked instance of the clsss or interface, call the _mock_ method on the _MockerV1_ returned
by the _of_ call.

If _of_ is called with the _Type_ argument then a mocked instance of that _Type_ will be created.

If _of_ is called with a _Factory_ argument, then the _Factory.stub_ method is called. The implementation of
this method must create a stub for the class to be mocked by calling the _Test.createStub_ method and
setting the _stubProvider_ to the argument passed to the _stub_ method. Why is this necessary? It's because
of namespace boundaries. If you are using the Force Framework package, then it will not be possible to pass
any of the _Types_ in your local namespace to _MockerV1.of_ unless they are global. Instead, you can pass a public
_Factory_ implementation which creates the stub for the class to be mocked. This works because the _Factory_
interface is global and so accessible both in your local namespace and also the package's.

See the difference between the _MockerV1.of_ methods in the example unit tests. The _Source Example_ shows how
to use _MockerV1_ when working in an org with the source code deployed. The _Package Example_ shows the same tests
when using an org with the package deployed.

When using an org with the source code deployed, the _MockerTestAPI_ interface is in the same namespace
as the _MockerV1_ class and can be passed to the _of_ method.

[Source Example](https://github.com/markbrennand/force-frameworks/tree/gh-pages/example/mocker/tests/MockerAPITests.cls)

When using an org with the package deployed, the _MockerTestAPI_ interface is in a different namespace
to the _Mocker_ class, and unless global, cannot be passed to the _MockerV1.of_ method. To prevent having
to make the API interface global, the unit test uses the _MockerFactory_ class to create the stub in
its own namespace.

[Package Example](https://github.com/markbrennand/force-frameworks/tree/gh-pages/example.pkg/mocker/tests/MockerAPITests.cls)

### Mocking Methods
After creating the _MockerV1_, you can start adding the method arguments, your mocked object is expecting. Take the
interface from the example code.
```
public interface MockerTestAPI {
    Datetime getCurrentTime();
    void setCurrentTime(Datetime currentTime);
    String getOrganizationId();
    List<Account> addAccounts(List<Account> accounts);
}
```

Inspecting the interface, you will see there are three distinct method arguments. No arguments, _Datetime_, and
_List<Account>_. We can mock these methods as follows.
```
mocker
    .whenNoArguments()
        .forMethod('getCurrentTime')
            .returns(Datetime.now())
        .forMethod('getOrganization')
            .returns (new Organization(Id = MockerV1.fakeId(Organization.SObjectType)))
    .whenArgument(Datetime.now())
        .forMethod('setCurrentTime')
    .whenArgument(new List<Account> { new Account(Name = 'Bill'), new Account(Name = 'Ted') })
        .forMethod('addAccounts')
```

The arguments passed to the mocked method when called from a unit test, must exactly match those set as the expected
arguments in the _whenArgument(s)_ call. If the arguments don't match, any methods linked to those arguments will not
have their call count incremented or any of the additional logic associated with the method performed.

The _returns_ method defines the return value from the mocked method.

The mocked method can be made to throw an exception instead.
```
.whenArgument(Datetime.now())
    .forMethod('setCurrentTime')
        .throws(new MockerV1.APIException('Example exception')
```

We can set the number of times the mocked method is expected to be called when the unit test is run. Add the
_called_ method after _forMethod_ to set the number of times the method should be called.
```
.whenArgument(Datetime.now())
    .forMethod('setCurrentTime')
        .called(1)
```

At the end of the unit test call _MockerV1.validate_ to check that all the mocked methods have been called the
expected number of times. If the method has not had the expected number of calls set, it may be called any number of
times, including zero.

### Argument Matching
By default, all argument matching, except for _SObjects_ and _Exceptions_, is literal. From the previous example,
_whenArgument(Datetime.now())_ would not be matched unless the class using the mocked method passed exactly
the same _Datetime_ value as when the argument was added to the mocked object. This is highly unlikely and
argument comparators can be used to get round this issue.

#### Exception Argument Matching
_MockerV1_ includes a default argument comparator for the _Exception_ type. The argument comparator checks
that the _Type_ of  the _Exception_ and its message matches that specified in the expected argument for the mocked
method. This  means that the stack trace is not checked. A literal comparison on two _Exceptions_ would expect
the  stack trace to match too.

#### SObject Matching
The default argument comparator for _SObject_ checks that the argument passed to the mocked method is of the same object
type as the expected argument for the mocked method. And that the expected argument has field values which are
a sub-set of the argument passed to the mocked method. This matching logic is also applied to arguments which are
_Lists_ and _Sets_ of _SObjects_.

Take the following example.

Account1 ( Name = 'Bill', BillingCountry = 'UK' )
Account2 ( Name = 'Ted', BillingCountry = 'UK' )

Take the following _MockerV1_.
```
.whenArgument(new List<Account> { new Account(BillingCountry ='UK'), new Account(BillingCountry = 'UK') })
    .forMethod('addAccounts')
```

As the expected argument contains only _BillingCountry_, both Account1 and Account2 would match if passed as the _List_
of _Accounts_ to the mocked method.

Now consider the following _MockerV1_.
```
.whenArgument(new List<Account> { new Account(Name='Bill', BillingCountry = 'UK'), new Account(Name = 'Ted', BillingCountry = 'US') }))
    .forMethod('addAccounts')
```

The expected argument has _Accounts_ with _Name_ and _BillingCountry_ set. If the _List_ of _Accounts_ passed to the
mocked method  was Account1 and Account2, Account2 would not match as it has a _BillingCountry_ of US and the expected
argument for the second _List_ entry has a _BillingCountry_ of US.

#### Custom Argument Matching
Returning to the _Datetime_ argument issue. We can address the problem by adding  a custom argument comparator for the
argument. Any custom argument comparator will be called before the default  argument comparators, so if you wanted to
add your own _Exception_ or _SObject_ argument comparator, you can.

The first thing you need to do is write your own argument comparator implementation for the argument. Here's the
one used in the example code.

```
private with sharing class DatetimeComparator implements Comparator<Object> {
    public Integer compare(Object param1, Object param2) {
        return (param1 instanceof Datetime && param2 instanceof Datetime) ? 0 : -1;
    }
}
```

Note that the argument comparator is simply checking that the argument passed to the mocked method and its
expected argument are of the same _Type_. The value of the argument is ignored.

The _MockerV1_ argument definition becomes.
```
.whenArgument(Datetime.now())
    .forMethod('setCurrentTime')
        .withComparators(new List<Comparator<Object>> { new DatetimeComparator() })
            .called(1)
```

### Conditional Return Values
There may be times when you want your mocked object to return a value from a method based on the arguments
passed to the mocked method. _MockerV1_ supports this with the _MockerV1.Modifier_ interface. If you set the
_returns_ argument of a _forMethod_ definition, the modifier's _process_ method is called, with the arguments
passed to the mocked method.

The following from the example code shows how a fake object id can be added to a _List_ of _Account_ objects using a
_Modifier_.
```
.whenArgument(new List<Account> { new Account(Name = 'Bill') })
    .forMethod('addAccounts')
        .called(1)
        .returns(new AccountModifier())

private with sharing class AccountModifier implements MockerV1.Modifier {
        public Object process(List<Object> arguments) {
            List<Account> returnList = new List<Account>();
            for (Account acc : (List<Account>) arguments[0]) {
                Account copy = acc.clone();
                copy.Id = MockerV1.fakeId(Account.SObjectType);
                returnList.add(copy);
            }

            return returnList;
        }
    }
```
### Call Chaining
The _MockerV1_ class is designed to allow the mocking of an object to be defined as a single
statement. The _MockerV1_ used to test the API when used by a service in the example code
shows this.
```
MockerTestAPI mockedAPI = (MockerTestAPI) MockerV1.of(MockerTestAPI.class)
    .whenArgument(new List<Account> { new Account(Name = 'Bill') })
        .forMethod('addAccounts')
            .called(1)
            .returns(new AccountModifier())
    .whenArgument(new List<Account> { new Account(BillingCountry = 'UK'), new Account(BillingCountry = 'UK') })
        .forMethod('addAccounts')
            .called(2)
            .returns(new AccountModifier())
        .whenNoArguments()
            .forMethod('getCurrentTime')
                .called(5)
                .returns(Datetime.now())
    .mock();
```