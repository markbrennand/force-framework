[back](../../README.md)
# Mocker

Many Apex unit tests are more like integration tests than unit tests. How many times do the unit tests you've 
written use DML and SOQL on custom objects? Strictly speaking, such a unit test is an integration test as it
relies on the database to pass. A good unit test should use dependencies, such as the database, that are
abstracted. In that way it can exercise purely the functionality of the class under test. The abstracted
dependencies should be mocked to provide the expected results for the test.

See the reference [Apex docs](SfApexDocs/mockerv1.html) for the API. It is suggested that you keep a page open
with the Apex docs loaded for your reference whilst reading this page.

If you wish to try the example unit test using Mocker in an org. Deploy the code in the
[example](https://github.com/markbrennand/force-frameworks/tree/gh-pages/example/mocker) directory to  your org if the
org has the Force Framework code deployed. If your org has the Force Framework package deployed, deploy the code in
the [example.pkg](https://github.com/markbrennand/force-frameworks/tree/gh-pages/example.pkg/mocker) directory.

For an example of a complete suite of unit tests written using _Mocker_ that test their features in isolation, see
[Asynhcronous Unit Tests](https://github.com/markbrennand/force-frameworks/tree/gh-pages/source/asynchronous/tests)

### Mocker Creation

To mock a class or interface, first call the _Mocker.of_ method.

The argument to the method can be either the _Type_ to be mocked, or a _Mocker.Factory_ instance.

To create the mocked instance of the clsss or interface, call the _mock_ method on the _Mocker_ returned
by the _of_ call.

If _of_ is called with the _Type_ argument then a mocked instance of that _Type_ will be created.

If _of_ is called with a _Factory_ argument, then the _Factory.stub_ method is called. The implementation of
this method must create a stub for the class to be mocked by calling the _Test.createStub_ method and
setting the _stubProvider_ to the argument passed to the _stub_ method. Why is this necessary? It's because
of namespace boundaries. If you are using the Force Framework package, then it will not be possible to pass
any of the _Types_ in your local namespace to _Mocker.of_ unless they are global. Instead, you can pass a public
_Factory_ implementation which creates the stub for the class to be mocked. This works because the _Factory_
interface is global and so accessible both in your local namespace and also the package's.

See the difference between the _Mocker.of_ methods in the example unit tests. The _Source Example_ shows how
to use _Mocker_ when working in an org with the source code deployed. The _Package Example_ shows the same tests
when using an org with the package deployed.

When using an org with the source code deployed, the _MockerTestAPI_ interface is in the same namespace
as the _Mocker_ class and can be passed to the _of_ method.

[Source Example](https://github.com/markbrennand/force-frameworks/tree/gh-pages/example/mocker/tests/MockerAPITests.cls)

When using an org with the package deployed, the _MockerTestAPI_ interface is in a different namespace
to the _Mocker_ class, and unless global, cannot be passed to the _Mocker.of_ method. To prevent having
to make the API interface global, the unit test uses the _MockerFactory_ class to create the stub in
its own namespace.

[Package Example](https://github.com/markbrennand/force-frameworks/tree/gh-pages/example.pkg/mocker/tests/MockerAPITests.cls)