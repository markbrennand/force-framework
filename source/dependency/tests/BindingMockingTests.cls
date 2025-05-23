/**
 * @description
 * Unit tests to check registry can be mocked.
 *
 * @author Mark Brennand
 */
@IsTest
public with sharing class BindingMockingTests {

    @IsTest
    static void testMockedAPI() {
        Dependency mockInjection = createMock();
        Dependency.INSTANCE = mockInjection;

        Assert.isTrue(Dependency.isBound(BindingTestHelper.TestInterface.class));
        Assert.isFalse(Dependency.isBound(BindingTestHelper.AbstractTest.class));
        Assert.isTrue(Dependency.isBound(BindingTestHelper.AbstractTest.class, 'Test'));
        Assert.isFalse(Dependency.isBound(BindingTestHelper.AbstractTest.class, 'NotTest'));
        Assert.isFalse(Dependency.isBound(BindingTestHelper.TestInterface.class, 'Test'));
        Assert.isTrue(Dependency.inject(BindingTestHelper.TestInterface.class) instanceof BindingTestHelper.SingletonTest);

        try {
            Dependency.inject(BindingTestHelper.AbstractTest.class);
            Assert.fail();
        } catch(Dependency.APIException ae) {
            Assert.areEqual('Binding for BindingTestHelper.AbstractTest is not defined', ae.getMessage());
        }

        Assert.isTrue(Dependency.inject(BindingTestHelper.AbstractTest.class, 'Test') instanceof BindingTestHelper.PrototypeTest);

        try {
            Dependency.inject(BindingTestHelper.AbstractTest.class, 'NotTest');
            Assert.fail();
        } catch(Dependency.APIException ae) {
            Assert.areEqual('Binding for BindingTestHelper.AbstractTest for action NotTest is not defined', ae.getMessage());
        }

        try {
            Dependency.inject(BindingTestHelper.TestInterface.class, 'Test');
            Assert.fail();
        } catch(Dependency.APIException ae) {
            Assert.areEqual('Binding for BindingTestHelper.TestInterface for action Test is not defined', ae.getMessage());
        }

        Mocker.validate();
    }

    private static Dependency createMock() {
        Mocker mocked = Mocker.of(Dependency.class);

        mocked
            .whenArgument(BindingTestHelper.TestInterface.class)
                .expectMethod('apiIsBound').called(1).returns(  true)
                .expectMethod('apiInject').called(1).returns(new BindingTestHelper.SingletonTest())
            .whenArguments(BindingTestHelper.TestInterface.class, 'Test')
                .expectMethod('apiIsBound').called(1).returns(false)
                .expectMethod('apiInject').called(1).throws(new Dependency.APIException('Binding for BindingTestHelper.TestInterface for action Test is not defined'))
            .whenArgument(BindingTestHelper.AbstractTest.class)
                .expectMethod('apiIsBound').called(1).returns(false)
                .expectMethod('apiInject').called(1).throws(new Dependency.APIException('Binding for BindingTestHelper.AbstractTest is not defined'))
            .whenArguments(BindingTestHelper.AbstractTest.class, 'Test')
                .expectMethod('apiIsBound').called(1).returns(true)
                .expectMethod('apiInject').called(1).returns(new BindingTestHelper.PrototypeTest())
            .whenArguments(BindingTestHelper.AbstractTest.class, 'NotTest')
                .expectMethod('apiIsBound').called(1).returns(false)
                .expectMethod('apiInject').called(1).throws(new Dependency.APIException('Binding for BindingTestHelper.AbstractTest for action NotTest is not defined'));

        return (Dependency) mocked.getMockedObject();
    }
}