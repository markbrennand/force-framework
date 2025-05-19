/**
 * @description
 * Class providing mocking of class methods.
 *
 * This class is not intended for use outside the framework.
 *
 * @author Mark Brennand
 */
public with sharing class Mock {
    final static MockStubProvider PROVIDER = new MockStubProvider();
    final static Map<Object, List<Method>> METHODS = new Map<Object, List<Method>>();

    public static Object stub(final Type stubbedClass) {
        return Test.createStub(stubbedClass, PROVIDER);
    }

    public static void validate(final Object stub) {
        if (METHODS.containsKey(stub)) {
            for (Method method : METHODS.get(stub)) {
                method.validate();
            }
        }
    }

    public static Method stubMethod(final Object stub, final String methodName) {
        Method method = new Method(methodName);
        if (METHODS.containsKey(stub)) {
            METHODS.get(stub).add(method);
        } else {
            METHODS.put(stub, new List<Method> { method });
        }

        return method;
    }

    public with sharing class Method {
        private final String methodName;
        private List<Object> arguments = new List<Object>();
        private Object returns;
        private Exception failureException;
        private Integer expectedCalls;
        private Integer timesCalled = 0;

        public Method(final String methodName) {
            this.methodName = methodName;
        }

        public Method withArguments(final List<Object> arguments) {
            this.arguments = arguments;
            return this;
        }

        public Method returns(final Object returning) {
            this.returns = returning;
            return this;
        }

        public Method expected(Integer expectedCalls) {
            this.expectedCalls = expectedCalls;
            return this;
        }

        public Method throws(final Exception failureException) {
            this.failureException = failureException;
            return this;
        }

        public Boolean matches(final String methodName, final List<Object> arguments) {
            if (methodName != this.methodName) {
                return false;
            }

            if (arguments.size() != this.arguments.size()) {
                return false;
            }

            for (Integer i = 0; i < arguments.size(); i++) {
                if (arguments[i] != this.arguments[i]) {
                    return false;
                }
            }

            return true;
        }

        public Object call() {
            timesCalled++;
            if (failureException != null) {
                throw failureException;
            } else {
                return returns;
            }
        }

        public void validate() {
            if (this.expectedCalls != null) {
                Assert.areEqual(
                        this.expectedCalls,
                        timesCalled, 'Stubbed method ' + methodName + ' was not called the expected number of times'
                );
            }
        }
    }

    private with sharing class MockStubProvider implements StubProvider {

        public Object handleMethodCall(
                final Object stubbedObject,
                final String stubbedMethodName,
                final Type returnType,
                final List<Type> paramTypes,
                final List<String> paramNames,
                final List<Object> args
        ) {
            System.debug(stubbedMethodName + '(' + args + ')');
            Assert.isTrue(
                    METHODS.containsKey(stubbedObject),
                    'Method ' + stubbedMethodName + ' has not been stubbed in object ' + stubbedObject
            );

            for (Method method : METHODS.get(stubbedObject)) {
                if (method.matches(stubbedMethodName, args)) {
                    return method.call();
                }
            }

            Assert.fail('Match for method ' + stubbedMethodName + ' and arguments not found in ' + stubbedObject);
            return null;
        }
    }
}