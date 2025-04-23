/**
 * @description
 * Unit tests to check registry can be mocked.
 *
 * @author Mark Brennand
 */
@IsTest
public with sharing class MockingTest {

    @IsTest
    static void testMockedRegistry() {
        Registry.INSTANCE = (Registry) Test.createStub(Registry.class, new MockRegistry());
        Assert.isTrue(Registry.has(TestData.TestInterface.class));
        Assert.isFalse(Registry.has(TestData.AbstractTest.class));
        Assert.isTrue(Registry.has(TestData.AbstractTest.class, 'Test'));
        Assert.isFalse(Registry.has(TestData.AbstractTest.class, 'NotTest'));
        Assert.isFalse(Registry.has(TestData.TestInterface.class, 'Test'));
        Assert.isTrue(Registry.wire(TestData.TestInterface.class) instanceof TestData.SingletonTest);

        try {
            Assert.isTrue(Registry.wire(TestData.AbstractTest.class) instanceof TestData.SingletonTest);
        } catch(Registry.APIException ae) {
            Assert.areEqual('Binding for "TestData.AbstractTest" is not defined', ae.getMessage());
        }

        Assert.isTrue(Registry.wire(TestData.AbstractTest.class, 'Test') instanceof TestData.PrototypeTest);

        try {
            Assert.isTrue(Registry.wire(TestData.AbstractTest.class, 'NotTest') instanceof TestData.PrototypeTest);
        } catch(Registry.APIException ae) {
            Assert.areEqual('Binding for "TestData.AbstractTest" for action "NotTest" is not defined', ae.getMessage());
        }

        try {
            Assert.isTrue(Registry.wire(TestData.TestInterface.class, 'Test') instanceof TestData.PrototypeTest);
        } catch(Registry.APIException ae) {
            Assert.areEqual('Binding for "TestData.TestInterface" for action "Test" is not defined', ae.getMessage());
        }
    }

    private with sharing class MockRegistry implements StubProvider {
        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName, Type returnType, List<Type> paramTypes, List<String> paramNames, List<Object> args) {
            if (stubbedMethodName == 'isBound') {
                return handleBound(args);
            } else if (stubbedMethodName == 'wireType') {
                return handleWire(args);
            }

            throw new Registry.APIException('Unexpected method "' + stubbedMethodName + '" called');
        }

        private Boolean handleBound(List<Object> args) {
            if (args.size() == 1) {
                return args[0] == TestData.TestInterface.class;
            } else {
                return args[0] == TestData.AbstractTest.class && args[1] == 'Test';
            }
        }

        private Object handleWire(List<Object> args) {
            if (args.size() == 1) {
                if (args[0] == TestData.TestInterface.class) {
                    return new TestData.SingletonTest();
                } else {
                    throw new Registry.APIException(
                            'Binding for "'
                            + args[0]
                            + '" is not defined'
                    );
                }

            } else if (args[1] == 'Test') {
                return new TestData.PrototypeTest();
            } else {
                throw new Registry.APIException(
                        'Binding for "' + args[0]
                        + '" for action "'
                        + args[1]
                        + '" is not defined'
                );
            }
        }
    }
}