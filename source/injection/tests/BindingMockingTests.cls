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
        Injection mockInjection = createMock();
        Injection.INSTANCE = mockInjection;

        Assert.isTrue(Injection.has(BindingTestHelper.TestInterface.class));
        Assert.isFalse(Injection.has(BindingTestHelper.AbstractTest.class));
        Assert.isTrue(Injection.has(BindingTestHelper.AbstractTest.class, 'Test'));
        Assert.isFalse(Injection.has(BindingTestHelper.AbstractTest.class, 'NotTest'));
        Assert.isFalse(Injection.has(BindingTestHelper.TestInterface.class, 'Test'));
        Assert.isTrue(Injection.wire(BindingTestHelper.TestInterface.class) instanceof BindingTestHelper.SingletonTest);

        try {
            Injection.wire(BindingTestHelper.AbstractTest.class);
            Assert.fail();
        } catch(Injection.APIException ae) {
            Assert.areEqual('Binding for BindingTestHelper.AbstractTest is not defined', ae.getMessage());
        }

        Assert.isTrue(Injection.wire(BindingTestHelper.AbstractTest.class, 'Test') instanceof BindingTestHelper.PrototypeTest);

        try {
            Injection.wire(BindingTestHelper.AbstractTest.class, 'NotTest');
            Assert.fail();
        } catch(Injection.APIException ae) {
            Assert.areEqual('Binding for BindingTestHelper.AbstractTest for action NotTest is not defined', ae.getMessage());
        }

        try {
            Injection.wire(BindingTestHelper.TestInterface.class, 'Test');
            Assert.fail();
        } catch(Injection.APIException ae) {
            Assert.areEqual('Binding for BindingTestHelper.TestInterface for action Test is not defined', ae.getMessage());
        }

        Mock.validate(mockInjection);
    }

    private static Injection createMock() {
        Injection mocked = (Injection) Mock.stub(Injection.class);

        Mock.stubMethod(mocked, 'isBound')
                .withArguments(new List<Object>{ BindingTestHelper.TestInterface.class })
                .expected(1)
                .returns(true);

        Mock.stubMethod(mocked, 'isBound')
                .withArguments(new List<Object>{ BindingTestHelper.TestInterface.class, 'Test' })
                .expected(1)
                .returns(false);

        Mock.stubMethod(mocked, 'isBound')
                .withArguments(new List<Object>{ BindingTestHelper.AbstractTest.class })
                .expected(1)
                .returns(false);

        Mock.stubMethod(mocked, 'isBound')
                .withArguments(new List<Object>{ BindingTestHelper.AbstractTest.class, 'Test' })
                .expected(1)
                .returns(true);

        Mock.stubMethod(mocked, 'isBound')
                .withArguments(new List<Object>{ BindingTestHelper.AbstractTest.class, 'NotTest' })
                .expected(1)
                .returns(false);

        Mock.stubMethod(mocked, 'wireType')
                .withArguments(new List<Object>{ BindingTestHelper.TestInterface.class })
                .expected(1)
                .returns(new BindingTestHelper.SingletonTest());

        Mock.stubMethod(mocked, 'wireType')
                .withArguments(new List<Object>{ BindingTestHelper.AbstractTest.class })
                .expected(1)
                .throws(new Injection.APIException('Binding for BindingTestHelper.AbstractTest is not defined'));

        Mock.stubMethod(mocked, 'wireType')
                .withArguments(new List<Object>{ BindingTestHelper.AbstractTest.class, 'Test' })
                .expected(1)
                .returns(new BindingTestHelper.PrototypeTest());

        Mock.stubMethod(mocked, 'wireType')
                .withArguments(new List<Object>{ BindingTestHelper.AbstractTest.class, 'NotTest' })
                .expected(1)
                .throws(new Injection.APIException('Binding for BindingTestHelper.AbstractTest for action NotTest is not defined'));

        Mock.stubMethod(mocked, 'wireType')
                .withArguments(new List<Object>{ BindingTestHelper.TestInterface.class, 'Test' })
                .expected(1)
                .throws(new Injection.APIException('Binding for BindingTestHelper.TestInterface for action Test is not defined'));

        return mocked;
    }
}