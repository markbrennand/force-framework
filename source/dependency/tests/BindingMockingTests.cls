/**
 * @description
 * Unit tests to check registry can be mocked.
 *
 * @author Mark Brennand
 */
@IsTest
public with sharing class BindingMockingTests {
    @TestSetup
    private static void setup() {
        BindingTestHelper.createUsers();
    }

    @IsTest
    static void testMocking() {
        System.runAs(BindingTestHelper.getUser()) {
            DependencyImpl mockInjection = createMock();
            DependencyImpl.INSTANCE = mockInjection;

            Assert.isTrue(Dependency.isBound(BindingTestHelper.TestInterface.class));
            Assert.isFalse(Dependency.isBound(BindingTestHelper.AbstractTest.class));
            Assert.isTrue(Dependency.isBound(BindingTestHelper.AbstractTest.class, 'Test'));
            Assert.isFalse(Dependency.isBound(BindingTestHelper.AbstractTest.class, 'NotTest'));
            Assert.isFalse(Dependency.isBound(BindingTestHelper.TestInterface.class, 'Test'));
            Assert.isTrue(Dependency.inject(BindingTestHelper.TestInterface.class) instanceof BindingTestHelper.SingletonTest);

            try {
                Dependency.inject(BindingTestHelper.AbstractTest.class);
                Assert.fail();
            } catch (Dependency.APIException ae) {
                Assert.areEqual('Binding for BindingTestHelper.AbstractTest is not defined', ae.getMessage());
            }

            Assert.isTrue(Dependency.inject(BindingTestHelper.AbstractTest.class, 'Test') instanceof BindingTestHelper.PrototypeTest);

            try {
                Dependency.inject(BindingTestHelper.AbstractTest.class, 'NotTest');
                Assert.fail();
            } catch (Dependency.APIException ae) {
                Assert.areEqual('Binding for BindingTestHelper.AbstractTest for action NotTest is not defined', ae.getMessage());
            }

            try {
                Dependency.inject(BindingTestHelper.TestInterface.class, 'Test');
                Assert.fail();
            } catch (Dependency.APIException ae) {
                Assert.areEqual('Binding for BindingTestHelper.TestInterface for action Test is not defined', ae.getMessage());
            }

            Mocker.validate();
        }
    }

    private static DependencyImpl createMock() {
        Mocker mocked = Mocker.of(DependencyImpl.class);

        mocked
            .whenArgument(BindingTestHelper.TestInterface.class)
                .forMethod('isBound').called(1).returns(  true)
                .forMethod('inject').called(1).returns(new BindingTestHelper.SingletonTest())
            .whenArguments(BindingTestHelper.TestInterface.class, 'Test')
                .forMethod('isBound').called(1).returns(false)
                .forMethod('inject').called(1).throws(new Dependency.APIException('Binding for BindingTestHelper.TestInterface for action Test is not defined'))
            .whenArgument(BindingTestHelper.AbstractTest.class)
                .forMethod('isBound').called(1).returns(false)
                .forMethod('inject').called(1).throws(new Dependency.APIException('Binding for BindingTestHelper.AbstractTest is not defined'))
            .whenArguments(BindingTestHelper.AbstractTest.class, 'Test')
                .forMethod('isBound').called(1).returns(true)
                .forMethod('inject').called(1).returns(new BindingTestHelper.PrototypeTest())
            .whenArguments(BindingTestHelper.AbstractTest.class, 'NotTest')
                .forMethod('isBound').called(1).returns(false)
                .forMethod('inject').called(1).throws(new Dependency.APIException('Binding for BindingTestHelper.AbstractTest for action NotTest is not defined'));

        return (DependencyImpl) mocked.mock();
    }
}