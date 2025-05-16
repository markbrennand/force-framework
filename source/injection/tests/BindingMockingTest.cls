/**
 * @description
 * Unit tests to check registry can be mocked.
 *
 * @author Mark Brennand
 */
@IsTest
public with sharing class BindingMockingTest {

    @IsTest
    static void testMockedRegistry() {
        Injection.INSTANCE = (Injection) Test.createStub(Injection.class, new MockRegistry());
        Assert.isTrue(Injection.has(BindingTestHelper.TestInterface.class));
        Assert.isFalse(Injection.has(BindingTestHelper.AbstractTest.class));
        Assert.isTrue(Injection.has(BindingTestHelper.AbstractTest.class, 'Test'));
        Assert.isFalse(Injection.has(BindingTestHelper.AbstractTest.class, 'NotTest'));
        Assert.isFalse(Injection.has(BindingTestHelper.TestInterface.class, 'Test'));
        Assert.isTrue(Injection.wire(BindingTestHelper.TestInterface.class) instanceof BindingTestHelper.SingletonTest);

        try {
            Assert.isTrue(Injection.wire(BindingTestHelper.AbstractTest.class) instanceof BindingTestHelper.SingletonTest);
        } catch(Injection.APIException ae) {
            Assert.areEqual('Binding for BindingTestHelper.AbstractTest is not defined', ae.getMessage());
        }

        Assert.isTrue(Injection.wire(BindingTestHelper.AbstractTest.class, 'Test') instanceof BindingTestHelper.PrototypeTest);

        try {
            Assert.isTrue(Injection.wire(BindingTestHelper.AbstractTest.class, 'NotTest') instanceof BindingTestHelper.PrototypeTest);
        } catch(Injection.APIException ae) {
            Assert.areEqual('Binding for BindingTestHelper.AbstractTest for action NotTest is not defined', ae.getMessage());
        }

        try {
            Assert.isTrue(Injection.wire(BindingTestHelper.TestInterface.class, 'Test') instanceof BindingTestHelper.PrototypeTest);
        } catch(Injection.APIException ae) {
            Assert.areEqual('Binding for BindingTestHelper.TestInterface for action Test is not defined', ae.getMessage());
        }
    }

    private with sharing class MockRegistry implements StubProvider {
        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName, Type returnType, List<Type> paramTypes, List<String> paramNames, List<Object> args) {
            if (stubbedMethodName == 'isBound') {
                return handleBound(args);
            } else if (stubbedMethodName == 'wireType') {
                return handleWire(args);
            }

            throw new Injection.APIException('Unexpected method ' + stubbedMethodName + ' called');
        }

        private Boolean handleBound(List<Object> args) {
            if (args.size() == 1) {
                return args[0] == BindingTestHelper.TestInterface.class;
            } else {
                return args[0] == BindingTestHelper.AbstractTest.class && args[1] == 'Test';
            }
        }

        private Object handleWire(List<Object> args) {
            if (args.size() == 1) {
                if (args[0] == BindingTestHelper.TestInterface.class) {
                    return new BindingTestHelper.SingletonTest();
                } else {
                    throw new Injection.APIException(
                            'Binding for '
                                    + args[0]
                                    + ' is not defined'
                    );
                }

            } else if (args[1] == 'Test') {
                return new BindingTestHelper.PrototypeTest();
            } else {
                throw new Injection.APIException(
                        'Binding for ' + args[0]
                                + ' for action '
                                + args[1]
                                + ' is not defined'
                );
            }
        }
    }
}