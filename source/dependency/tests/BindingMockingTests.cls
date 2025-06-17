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

            Assert.isTrue(DependencyV1.isBound(BindingTestHelper.TestInterface.class));
            Assert.isFalse(DependencyV1.isBound(BindingTestHelper.AbstractTest.class));
            Assert.isTrue(DependencyV1.isBound(BindingTestHelper.AbstractTest.class, 'Test'));
            Assert.isFalse(DependencyV1.isBound(BindingTestHelper.AbstractTest.class, 'NotTest'));
            Assert.isFalse(DependencyV1.isBound(BindingTestHelper.TestInterface.class, 'Test'));
            Assert.isTrue(DependencyV1.inject(BindingTestHelper.TestInterface.class) instanceof BindingTestHelper.SingletonTest);

            try {
                DependencyV1.inject(BindingTestHelper.AbstractTest.class);
                Assert.fail();
            } catch (DependencyV1.APIException ae) {
                Assert.areEqual('Binding for BindingTestHelper.AbstractTest is not defined', ae.getMessage());
            }

            Assert.isTrue(DependencyV1.inject(BindingTestHelper.AbstractTest.class, 'Test') instanceof BindingTestHelper.PrototypeTest);

            try {
                DependencyV1.inject(BindingTestHelper.AbstractTest.class, 'NotTest');
                Assert.fail();
            } catch (DependencyV1.APIException ae) {
                Assert.areEqual('Binding for BindingTestHelper.AbstractTest for action NotTest is not defined', ae.getMessage());
            }

            try {
                DependencyV1.inject(BindingTestHelper.TestInterface.class, 'Test');
                Assert.fail();
            } catch (DependencyV1.APIException ae) {
                Assert.areEqual('Binding for BindingTestHelper.TestInterface for action Test is not defined', ae.getMessage());
            }

            MockerV1.validate();
        }
    }

    private static DependencyImpl createMock() {
        MockerV1 mocked = MockerV1.of(DependencyImpl.class);

        mocked
            .whenArgument(BindingTestHelper.TestInterface.class)
                .forMethod('isBound')
                    .called(1)
                    .returns(  true)
                .forMethod('inject')
                    .called(1)
                    .returns(new BindingTestHelper.SingletonTest())
            .whenArguments(BindingTestHelper.TestInterface.class, 'Test')
                .forMethod('isBound')
                    .called(1)
                    .returns(false)
                .forMethod('inject')
                    .called(1)
                    .throws(new DependencyV1.APIException('Binding for BindingTestHelper.TestInterface for action Test is not defined'))
            .whenArgument(BindingTestHelper.AbstractTest.class)
                .forMethod('isBound')
                    .called(1)
                    .returns(false)
                .forMethod('inject')
                    .called(1)
                    .throws(new DependencyV1.APIException('Binding for BindingTestHelper.AbstractTest is not defined'))
            .whenArguments(BindingTestHelper.AbstractTest.class, 'Test')
                .forMethod('isBound')
                    .called(1)
                    .returns(true)
                .forMethod('inject')
                    .called(1)
                .returns(new BindingTestHelper.PrototypeTest())
            .whenArguments(BindingTestHelper.AbstractTest.class, 'NotTest')
                .forMethod('isBound')
                    .called(1)
                    .returns(false)
                .forMethod('inject')
                    .called(1)
                    .throws(new DependencyV1.APIException('Binding for BindingTestHelper.AbstractTest for action NotTest is not defined'));

        return (DependencyImpl) mocked.mock();
    }
}