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

        Mock.validate(mockInjection);
    }

    private static Dependency createMock() {
        Dependency mocked = (Dependency) Mock.stub(Dependency.class);

        Mock.stubMethod(mocked, 'apiIsBound')
                .withArguments(new List<Object>{ BindingTestHelper.TestInterface.class })
                .expected(1)
                .returns(true);

        Mock.stubMethod(mocked, 'apiIsBound')
                .withArguments(new List<Object>{ BindingTestHelper.TestInterface.class, 'Test' })
                .expected(1)
                .returns(false);

        Mock.stubMethod(mocked, 'apiIsBound')
                .withArguments(new List<Object>{ BindingTestHelper.AbstractTest.class })
                .expected(1)
                .returns(false);

        Mock.stubMethod(mocked, 'apiIsBound')
                .withArguments(new List<Object>{ BindingTestHelper.AbstractTest.class, 'Test' })
                .expected(1)
                .returns(true);

        Mock.stubMethod(mocked, 'apiIsBound')
                .withArguments(new List<Object>{ BindingTestHelper.AbstractTest.class, 'NotTest' })
                .expected(1)
                .returns(false);

        Mock.stubMethod(mocked, 'apiInject')
                .withArguments(new List<Object>{ BindingTestHelper.TestInterface.class })
                .expected(1)
                .returns(new BindingTestHelper.SingletonTest());

        Mock.stubMethod(mocked, 'apiInject')
                .withArguments(new List<Object>{ BindingTestHelper.AbstractTest.class })
                .expected(1)
                .throws(new Dependency.APIException('Binding for BindingTestHelper.AbstractTest is not defined'));

        Mock.stubMethod(mocked, 'apiInject')
                .withArguments(new List<Object>{ BindingTestHelper.AbstractTest.class, 'Test' })
                .expected(1)
                .returns(new BindingTestHelper.PrototypeTest());

        Mock.stubMethod(mocked, 'apiInject')
                .withArguments(new List<Object>{ BindingTestHelper.AbstractTest.class, 'NotTest' })
                .expected(1)
                .throws(new Dependency.APIException('Binding for BindingTestHelper.AbstractTest for action NotTest is not defined'));

        Mock.stubMethod(mocked, 'apiInject')
                .withArguments(new List<Object>{ BindingTestHelper.TestInterface.class, 'Test' })
                .expected(1)
                .throws(new Dependency.APIException('Binding for BindingTestHelper.TestInterface for action Test is not defined'));

        return mocked;
    }
}