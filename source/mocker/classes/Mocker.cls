/**
 * @description
 * Classes providing an arguments based mocking solution.
 *
 * Rather than defining fixed lists of functions and arguments to be mocked, this solution defines the arguments
 * first and then list all the methods that expect those arguments from the class or interface being mocked.
 *
 * @author Mark Brennand
 */
public with sharing virtual class Mocker extends WhenArguments {
    private final static Map<Object, List<Arguments>> STUBBED_OBJECTS = new Map<Object, List<Arguments>>();
    private final static MockMatcher MATCHER = new MockMatcher();

    private final Object mockedObject;

    protected Mocker(final Object mockedObject) {
        Assertion.isNotNull(mockedObject, 'argument: Mocker.mockedObject');

        setParent(this);
        this.mockedObject = mockedObject;
    }

    public Object getMockedObject() {
        return mockedObject;
    }

    public static Mocker of(final Type forType) {
        Assertion.isNotNull(forType, 'argument: Mocker.mock.forType');

        final Mocker mock = new Mocker(Test.createStub(forType, MATCHER));
        return mock;
    }

    public static void validate() {
        for (Object mocked : STUBBED_OBJECTS.keySet()) {
            for (Arguments arguments : STUBBED_OBJECTS.get(mocked)) {
                for (Method method : arguments.methods) {
                    method.validate();
                }
            }
        }
    }

    private with sharing class MockMatcher implements StubProvider {

        public Object handleMethodCall(
                final Object stubbedObject,
                final String stubbedMethodName,
                final Type returnType,
                final List<Type> paramTypes,
                final List<String> paramNames,
                final List<Object> arguments
        ) {
            Assertion.isNotNull(stubbedObject, 'argument: Mocker.MockMatcher.handleMethodCall.stubbedObject');
            Assertion.isNotNull(stubbedMethodName, 'argument: Mocker.MockMatcher.handleMethodCall.stubbedMethodName');
            Assertion.isNotNull(paramTypes, 'argument: Mocker.MockMatcher.handleMethodCall.paramTypes');
            Assertion.isNotNull(paramNames, 'argument: Mocker.MockMatcher.handleMethodCall.paramNames');
            Assertion.isNotNull(arguments, 'argument: Mocker.MockMatcher.handleMethodCall.arguments');

            final List<Arguments> allArguments = STUBBED_OBJECTS.get(stubbedObject);
            Assertion.isNotNull(arguments, 'The are no arguments assigned to the stub ' + stubbedObject);

            for (Arguments argument : allArguments) {
                if (argument.matches(arguments)) {
                    for (Method method : argument.methods) {
                        if (method.isMatch(stubbedMethodName)) {
                            return method.call();
                        }
                    }
                }
            }

            Assertion.fail(
                    'Method '
                    + stubbedMethodName
                    + ' not found for arguments '
                    + arguments
                    + ' for the stub ' + stubbedObject
            );

            return null;
        }
    }

    public with sharing class Arguments extends WhenArguments {
        final List<Object> expectedArguments;
        final List<Method> methods = new List<Method>();

        private Arguments(final Mocker parent, final List<Object> expectedArguments) {
            Assertion.isNotNull(parent, 'argument: Mocker.Arguments.parent');
            Assertion.isNotNull(expectedArguments, 'argument: Mocker.Arguments.expectedArguments');

            setParent(parent);
            this.expectedArguments = expectedArguments;

            if (STUBBED_OBJECTS.containsKey(parent.mockedObject)) {
                STUBBED_OBJECTS.get(parent.mockedObject).add(this);
            } else {
                STUBBED_OBJECTS.put(parent.mockedObject, new List<Arguments> { this });
            }
        }

        public Method expectMethod(final String methodName) {
            Method method = new Method(this, methodName);
            methods.add(method);
            return method;
        }

        private Boolean matches(final List<Object> actualArguments) {
            Assertion.isNotNull(actualArguments, 'argument: Mocker.Arguments.matches.actualArguments');

            if (expectedArguments.size() != actualArguments.size()) {
                return false;
            }

            for (Integer i = 0; i < expectedArguments.size(); i++) {
                final Boolean actualIsListSObject = actualArguments[i] instanceof List<SObject>;
                final Boolean actualIsSObject = actualArguments[i] instanceof SObject;

                if (expectedArguments[i] instanceof List<SObject>) {
                    if (actualIsListSObject) {
                        return compareSObjects((List<SObject>) expectedArguments[i], (List<SObject>) actualArguments[i]);
                    } else {
                        return false;
                    }
                } else if (expectedArguments[i] instanceof SObject) {
                    if (!actualIsListSObject && actualIsSObject) {
                        return compareSObjects((SObject) expectedArguments[i], (SObject) actualArguments[i]);
                    } else {
                        return false;
                    }
                } else if (expectedArguments[i] != actualArguments[i]) {
                    return false;
                }
            }

            return true;
        }
    }

    public with sharing class Method extends WhenArguments {
        private final Arguments arguments;
        private final String methodName;
        private Integer expectedCount;
        private Integer actualCount = 0;
        private Object returnValue;
        private Exception throws;

        private Method(final Arguments arguments, final String methodName) {
            Assertion.isNotNull(arguments, 'argument: Mocker.Method.arguments');
            Assertion.isNotNull(methodName, 'argument: Mocker.Method.methodName');

            setParent(arguments.parent);
            this.arguments = arguments;
            this.methodName = methodName;
        }

        public Method called(final Integer expectedCount) {
            Assertion.isNotNull(expectedCount, 'argument: Mocker.Method.called.expectedCount');

            this.expectedCount = expectedCount;
            return this;
        }

        public Method returns(final Object returnValue) {
            this.returnValue = returnValue;
            return this;
        }

        public Method throws(final Exception throws) {
            Assertion.isNotNull(throws, 'argument: Mocker.Method.whichThrows.throws');

            this.throws = throws;
            return this;
        }

        public Method expectMethod(final String methodName) {
            return arguments.expectMethod(methodName);
        }

        public Boolean isMatch(final String methodName) {
            Assertion.isNotNull(methodName, 'argument: Mocker.Method.isMatch.methodName');

            return this.methodName == methodName;
        }

        private Object call() {
            actualCount++;

            if (this.throws != null) {
                throw throws;
            }

            return returnValue;
        }

        private void validate() {
            if (expectedCount != null) {
                Assertion.areEqual(
                        expectedCount,
                        actualCount,
                        'Incorrect number of calls to ' + parent.mockedObject.toString().split(':')[0].split('__sfdc')[0] + '.' + methodName
                );
            }
        }
    }

    private with sharing virtual class WhenArguments {
        protected Mocker parent;

        private void setParent(final Mocker parent) {
            Assertion.isNotNull(parent, 'argument: Mocker.WhenArguments.setParent.parent');

            this.parent = parent;
        }

        public Arguments whenNoArguments() {
            return whenListOfArguments(new List<Object>());
        }

        public Arguments whenArgument(final Object argument) {
            return whenListOfArguments(new List<Object> { argument });
        }

        public Arguments whenArguments(final Object argument1, final Object argument2) {
            return whenListOfArguments(new List<Object> { argument1, argument2  });
        }

        public Arguments whenArguments(final Object argument1, final Object argument2, final Object argument3) {
            return whenListOfArguments(new List<Object> { argument1, argument2, argument3  });
        }

        public Arguments whenArguments(final Object argument1, final Object argument2, final Object argument3, final Object argument4) {
            return whenListOfArguments(new List<Object> { argument1, argument2, argument3, argument4  });
        }

        public Arguments whenArguments(final Object argument1, final Object argument2, final Object argument3, final Object argument4, final Object argument5) {
            return whenListOfArguments(new List<Object> { argument1, argument2, argument3, argument4, argument5  });
        }

        public Arguments whenListOfArguments(final List<Object> expectedArguments) {
            Assertion.isNotNull(expectedArguments, 'argument: Mocker.WhenArguments.whenListOfArguments.expectedArguments');

            return new Arguments(parent, expectedArguments);
        }
    }

    private static Boolean compareSObjects(final SObject expectedSObject, final SObject actualSObject) {
        // Fields of actualSObject must match all of those in expectedSObject.
        // Fields not defined in expectedSObject may be defined in actualSObject.
        final Map<String, Object> values1 = expectedSObject.getPopulatedFieldsAsMap();
        final Map<String, Object> values2 = actualSObject.getPopulatedFieldsAsMap();

        for (String field : values1.keySet()) {
            if (values1.get(field) != values2.get(field)) {
                return false;
            }
        }

        return true;
    }

    private static Boolean compareSObjects(final List<SObject> expectedSObjects, final List<SObject> actualSObjects) {
        if (expectedSObjects.size() != actualSObjects.size()) {
            return false;
        }

        for (Integer i = 0; i < expectedSObjects.size(); i++) {
            if (!compareSObjects(expectedSObjects[i], actualSObjects[i])) {
                return false;
            }
        }

        return true;
    }
}