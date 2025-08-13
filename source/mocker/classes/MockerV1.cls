/**
 * @description
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../LICENSE target="_blank">MIT License</a>.
 * <br><br>
 * Classes providing the Mocker API.
 * <br><br>
 * Rather than defining fixed lists of functions and arguments to be mocked, this solution defines the arguments
 * first and then list all the methods that expect those arguments from the class or interface being mocked.
 * <br><br>
 * Arguments are checked for matches using comparators. A default set of comparators are provided. Custom comparators
 * may be added for arguments to be matched.
 * <br><br>
 * The default comparator for a custom object or collection of custom objects requires that only the fields set in the
 * object to be matched are set identically in the custom object(s) passed to the mocked method call.
 * <br><br>
 * The Modifier interface may be used to return a value from a mocked method based on the arguments to the call.
 * For example, this could be used to add a fake Id to custom objects being inserted.
 * <br><br>
 * See <a href=../../source/mocker/README.md target="_blank">README</a> for full details of the Mocker API.
 *
 * @author Mark Brennand
 */
@SuppressWarnings('PMD.AvoidGlobalModifier')
global with sharing virtual class MockerV1 extends MockerV1.Chainable {

    /**
     * @description
     * Map from the objects that have been mocked to their arguments list.
     */
    private final static Map<Object, List<Arguments>> STUBBED_OBJECTS = new Map<Object, List<Arguments>>();

    /**
     * @description
     * The stub handler called for all mocked objects.
     */
    private final static Matcher MATCHER = new Matcher();

    /**
     * @description
     * Interface allowing a user of the Mocker.of method to be called back to create the stubbed object.
     * <br><br>
     * As stubbed objects cannot be created by the Mocker if they are in a different namespace, this interface
     * can be used to create the stubbed object in the caller's namespace.
     */
    global interface Factory {

        /**
         * @description
         * Crates an instance of a stubbed object.
         *
         * The implementation will be responsible for deciding the class of the object to stub.
         *
         * @param provider The provider to use for the new stubbed object.
         *
         * @return The stubbed object.
         */
        Object stub(StubProvider provider);
    }

    /**
     * @description
     * An implementation of the Modifier interface can be added as argument to Method.returns to make changes to the
     * method arguments when a match for the arguments is found and the registered method is called.
     * <br><br>
     * An example use case for this would be to add an Id to objects inserted through a call to a mocked method.
     *
     */
    global interface Modifier {

        /**
         * @description
         * Called to make changes to the return value using the arguments passed into the Method.
         *
         * @param arguments The arguments passed to the Method.
         *
         * @return The return value.
         */
        Object process(final List<Object> arguments);
    }

    /**
     * @description
     * Map containing the next Id number to use for each object type.
     */
    private final static Map<String, Integer> IDS = new Map<String, Integer>();

    /**
     * @description
     * The mocked object created by this instance of the Mocker.
     */
    private final Object mockedObject;

    /**
     * @description
     * Argument setting class.
     * <br><br>
     * It is designed to be callable from both the Mocker, Arguments and Method classes. This is so all three can
     * perform chaining of calls.
     */
    global with sharing virtual class Chainable {
        protected MockerV1 parent;

        /**
         * @description
         * Sets the parent Mocker object.
         *
         * @param parent The owning Mocker.
         */
        private void setParent(final MockerV1 parent) {
            AssertionV1.isNotNull(parent, 'argument: Mocker.WhenArguments.setParent.parent');

            this.parent = parent;
        }

        /**
         * @description
         * Creates an argument grouping which has no values.
         * <br><br>
         * This would represent a method with no arguments.
         *
         * @return The object instance so it can be chained.
         */
        global MockerV1.Arguments whenNoArguments() {
            return whenListOfArguments(new List<Object>());
        }

        /**
         * @description
         * Creates an argument grouping which has a single argument.
         * <br><br>
         * This would represent a mocked method which has one parameter.
         *
         * @param argument The expected parameter value.
         *
         * @return The object instance so it can be chained.
         */
        global MockerV1.Arguments whenArgument(final Object argument) {
            return whenListOfArguments(new List<Object> { argument });
        }

        /**
         * @description
         * Creates an argument grouping which has two arguments.
         * <br><br>
         * This would represent a mocked method which has two parameters.
         *
         * @param argument1 The expected value of the first parameter.
         * @param argument2 The expected value of the second parameter.
         *
         * @return The object instance so it can be chained.
         */
        global MockerV1.Arguments whenArguments(final Object argument1, final Object argument2) {
            return whenListOfArguments(new List<Object> { argument1, argument2  });
        }

        /**
         * @description
         * Creates an argument grouping which has three arguments.
         * <br><br>
         * This would represent a mocked method which has three parameters.
         *
         * @param argument1 The expected value of the first parameter.
         * @param argument2 The expected value of the second parameter.
         * @param argument3 The expected value of the third parameter.
         *
         * @return The object instance so it can be chained.
         */
        global MockerV1.Arguments whenArguments(final Object argument1, final Object argument2, final Object argument3) {
            return whenListOfArguments(new List<Object> { argument1, argument2, argument3  });
        }

        /**
         * @description
         * Creates an argument grouping which has four arguments.
         * <br><br>
         * This would represent a mocked method which has four parameters.
         *
         * @param argument1 The expected value of the first parameter.
         * @param argument2 The expected value of the second parameter.
         * @param argument3 The expected value of the third parameter.
         * @param argument4 The expected value of the fourth parameter.
         *
         * @return The object instance so it can be chained.
         */
        @SuppressWarnings('PMD.ExcessiveParameterList')
        global MockerV1.Arguments whenArguments(
                final Object argument1,
                final Object argument2,
                final Object argument3,
                final Object argument4
        ) {
            return whenListOfArguments(new List<Object> { argument1, argument2, argument3, argument4  });
        }

        /**
         * @description
         * Creates an argument grouping which has five arguments.
         * <br><br>
         * This would represent a mocked method which has five parameters.
         *
         * @param argument1 The expected value of the first parameter.
         * @param argument2 The expected value of the second parameter.
         * @param argument3 The expected value of the third parameter.
         * @param argument4 The expected value of the fourth parameter.
         * @param argument5 The expected value of the fifth parameter.
         *
         * @return The object instance so it can be chained.
         */
        @SuppressWarnings('PMD.ExcessiveParameterList')
        global MockerV1.Arguments whenArguments(
                final Object argument1,
                final Object argument2,
                final Object argument3,
                final Object argument4,
                final Object argument5
        ) {
            return whenListOfArguments(new List<Object> { argument1, argument2, argument3, argument4, argument5  });
        }

        /**
         * @description
         * Creates an argument grouping which has the given arguments.
         *
         * @param expectedArguments The arguments to be matched.
         *
         * @return The object instance so it can be chained.
         */
        global MockerV1.Arguments whenListOfArguments(final List<Object> expectedArguments) {
            AssertionV1.isNotNull(expectedArguments, 'argument: Mocker.WhenArguments.whenListOfArguments.expectedArguments');

            return new Arguments(parent, expectedArguments);
        }

        /**
         * @description
         * Gets the mocked object for the class being mocked.
         *
         * @return The mocked object.
         */
        global Object mock(){
            return parent.mockedObject;
        }
    }

    /**
     * @description
     * Creates an instance of this class.
     * <br><br>
     * The method is protected so the class can be mocked in the unit tests. It is not public, to prevent re-use
     * outside this class.
     *
     * @param mockedObject The mocked object.
     */
    protected MockerV1(final Object mockedObject) {
        AssertionV1.isNotNull(mockedObject, 'argument: Mocker.mockedObject');

        setParent(this);
        this.mockedObject = mockedObject;
    }

    /**
     * @description
     * Creates a new Mocker that may be used to define a mocking scenario.
     *
     * @param forType The class to be mocked.
     *
     * @return A Mocker which may be used to define a mocking scenario.
     */
    global static MockerV1 of(final Type forType) {
        AssertionV1.isNotNull(forType, 'argument: Mocker.of.forType');

        final MockerV1 mocked = new MockerV1(Test.createStub(forType, MATCHER));
        return mocked;
    }

    /**
     * @description
     * Creates a new Mocker that may be used to define a mocking scenario.
     * <br><br>
     * The Factory argument will be called to create the stubbed object.
     *
     * @param factory Factory that will create the stubbed object.
     *
     * @return A Mocker which may be used to define a mocking scenario.
     */
    global static MockerV1 of(final Factory factory) {
        AssertionV1.isNotNull(factory, 'argument: Mocker.of.factory');

        final MockerV1 mocked = new MockerV1(factory.stub(MATCHER));
        return mocked;
    }

    /**
     * @description
     * Validates that all the methods in the mocked objects have been called the required number of times.
     * <br><br>
     * If a method has not been called the correct number of times, an Assertion.AssertionException is thrown.
     * <br><br>
     * If the method has not set a called count value, it is not validated.
     */
    global static void validate() {
        for (Object mocked : STUBBED_OBJECTS.keySet()) {
            for (Arguments arguments : STUBBED_OBJECTS.get(mocked)) {
                for (Method method : arguments.methods) {
                    method.validate();
                }
            }
        }
    }

    /**
     * @description
     * Returns an argument which can be used in a whenArgument call to represent a method parameter which must be
     * of the given Type but whose value is not checked.
     * <br><br>
     * The parameter may be null if the types match.
     *
     * @param type The Type the argument is for.
     *
     * @return The argument.
     */
    global static Object any(final Type type) {
        return new AnyValue(type, true);
    }

    /**
     * @description
     * Returns an argument which can be used in a whenArgument call to represent a method parameter which must be
     * of the given Type but whose value is not checked.
     * <br><br>
     * The parameter must be non null if the types match.
     *
     * @param type The Type the argument is for.
     *
     * @return The argument.
     */
    global static Object anyNonNull(final Type type) {
        return new AnyValue(type, false);
    }

    /**
     * @description
     * Generates a fake id for the given object type.
     *
     * @param objectType The object type to have a fake Id generated for.
     *
     * @return The fake id.
     */
    global static String fakeId(final SObjectType objectType) {
        final String prefix = objectType.getDescribe().keyPrefix;

        if (!IDS.containsKey(prefix)) {
            IDS.put(prefix, 0);
        }

        final Integer nextId = (IDS.get(prefix) + 1);
        IDS.put(prefix, nextId);

        final String id = String.valueOf(nextId);
        final Integer length = id.length();

        return String.join(
                new List<String> {
                        prefix,
                        '0'.repeat(15 - length),
                        id
                },
                ''
        );
    }

    /**
     * @description
     * Class that calls the methods of the mocked classes.
     */
    private with sharing class Matcher implements StubProvider {

        /**
         * @description
         * Method responsible for calling the methods assigned to mocked object.
         * <br><br>
         * The arguments are checked against all the registered arguments for the mocked objects.
         * <br><br>
         * If a match is found, the methods registered for the arguments are checked. If a method is found with
         * a name matching the stubbedMethodName, the method is called.
         *
         * @param stubbedObject The mocked object.
         * @param stubbedMethodName The method being called.
         * @param returnType The method's return type.
         * @param paramTypes The types of the method's arguments.
         * @param paramNames The names of the method's arguments.
         * @param arguments The method's arguments.
         *
         * @return A method specific result.
         */
        @SuppressWarnings('PMD.ExcessiveParameterList')
        public Object handleMethodCall(
                final Object stubbedObject,
                final String stubbedMethodName,
                final Type returnType,
                final List<Type> paramTypes,
                final List<String> paramNames,
                final List<Object> arguments
        ) {
            AssertionV1.isNotNull(stubbedObject, 'argument: Mocker.MockMatcher.handleMethodCall.stubbedObject');
            AssertionV1.isNotNull(stubbedMethodName, 'argument: Mocker.MockMatcher.handleMethodCall.stubbedMethodName');
            AssertionV1.isNotNull(paramTypes, 'argument: Mocker.MockMatcher.handleMethodCall.paramTypes');
            AssertionV1.isNotNull(paramNames, 'argument: Mocker.MockMatcher.handleMethodCall.paramNames');
            AssertionV1.isNotNull(arguments, 'argument: Mocker.MockMatcher.handleMethodCall.arguments');

            final List<Arguments> allArguments = STUBBED_OBJECTS.get(stubbedObject);
            AssertionV1.isNotNull(allArguments, 'The are no arguments assigned to the stub ' + stubbedObject);

            for (Arguments argument : allArguments) {
                if (argument.matches(arguments, paramTypes)) {
                    for (Method method : argument.methods) {
                        if (method.isMatch(stubbedMethodName)) {
                            return method.call(arguments);
                        }
                    }
                }
            }

            AssertionV1.fail(
                    'Method ' + stubbedObject.toString().split(':')[0].split('__sfdc')[0] + '.' + stubbedMethodName +
                    + ' not found for arguments '
                    + arguments
            );

            return null;
        }
    }

    /**
     * @description
     * Method definition associated with an Argument.
     */
    global with sharing class Method extends MockerV1.Chainable {
        private final Arguments arguments;
        private final String methodName;
        private OptionalV1 expectedCount = OptionalV1.empty();
        private Integer actualCount = 0;
        private OptionalV1 returnValue = OptionalV1.empty();
        private OptionalV1 throws = OptionalV1.empty();

        /**
         * @description
         * Constructs aa new method associated with an argument definition.
         *
         * @param arguments The parent Arguments.
         * @param methodName The name of the mocked method.
         */
        private Method(final Arguments arguments, final String methodName) {
            AssertionV1.isNotNull(arguments, 'argument: Mocker.Method.arguments');
            AssertionV1.isNotNull(methodName, 'argument: Mocker.Method.methodName');

            setParent(arguments.parent);
            this.arguments = arguments;
            this.methodName = methodName;
        }

        /**
         * @description
         * Sets the number of times the mocked object is expected to be called.
         * <br><br>
         * The check is performed when the Mocker.validate method is called.
         *
         * @param expectedCount The number of times the method is expected to be called.
         *
         * @return The object instance so it can be chained.
         */
        global MockerV1.Method called(final Integer expectedCount) {
            AssertionV1.isNotNull(expectedCount, 'argument: Mocker.Method.called.expectedCount');

            this.expectedCount = OptionalV1.ofNullable(expectedCount);
            return this;
        }

        /**
         * @description
         * Sets the return value from the method if the arguments are matched and it is called.
         * <br><br>
         * The return value may be set to an instance of Modifier to return a value based on the arguments passed
         * to the mocked method call.
         *
         * @param returnValue The value to be returned if the arguments are matched and this method is called.
         *
         * @return The object instance so it can be chained.
         */
        global MockerV1.Method returns(final Object returnValue) {
            AssertionV1.isTrue(!this.returnValue.isPresent(), 'Return value can only be set once');
            this.returnValue = OptionalV1.of(returnValue);
            return this;
        }

        /**
         * @description
         * Sets the Exception to be thrown from the method if the arguments are matched and it is called.
         *
         * @param throws The Exception to throw if the arguments are matched and this method is called.
         *
         * @return The object instance so it can be chained.
         */
        global MockerV1.Method throws(final Exception throws) {
            AssertionV1.isNotNull(throws, 'argument: Mocker.Method.whichThrows.throws');
            AssertionV1.isTrue(!this.throws.isPresent(), 'Exception to throw can only be set once');

            this.throws = OptionalV1.of(throws);
            return this;
        }

        /**
         * @description
         * Registers a new method for the parent's arguments.
         * <br><br>
         * The method will be called when the arguments are matched.
         *
         * @param methodName The name of the method expected.
         *
         * @return The mew method instance so it can be chained.
         */
        global MockerV1.Method forMethod(final String methodName) {
            return arguments.forMethod(methodName);
        }

        /**
         * @description
         * Checks whether the method name in this object matches the method name in the argument.
         * <br><br>
         * If the arguments match, the methods for the arguments are iterated. Each method is checked against
         * the method name of the method being called in the mocked object.
         *
         * @param methodName The name of the method being called.
         *
         * @return True if the method names match.
         */
        private Boolean isMatch(final String methodName) {
            AssertionV1.isNotNull(methodName, 'argument: Mocker.Method.isMatch.methodName');

            return this.methodName == methodName;
        }

        /**
         * @description
         * Called to take the action defined for the method.
         * <br><br>
         * The arguments and method name must match from the mocked method call. If an Exception has been set
         * for the method, it is thrown. Otherwise, the return value set for the method is returned.
         * <br><br>
         * The call count is incremented to track that the method has been called.
         *
         * @param arguments The arguments passed to the mocked method.
         *
         * @return The return value or an Exception.
         */
        private Object call(final List<Object> arguments) {
            actualCount++;

            if (throws.isPresent()) {
                throw (Exception) throws.get();
            } else if (returnValue.isPresent()) {
                final Object result = returnValue.get();
                if (result instanceof Modifier) {
                    return ((Modifier) result).process(arguments);
                } else {
                    return result;
                }
            } else {
                return null;
            }
        }

        /**
         * @description
         * Called to check that the method has been called the correct number of times.
         */
        private void validate() {
            if (expectedCount.isPresent()) {
                AssertionV1.areEqual(
                        (Integer) expectedCount.get(),
                        actualCount,
                        'Incorrect number of calls to ' + parent.mockedObject.toString().split(':')[0].split('__sfdc')[0] + '.' + methodName
                );
            }
        }
    }


    /**
     * @description
     * Class representing a list of arguments for which mocked methods are to be registered.
     */
    global with sharing class Arguments extends MockerV1.Chainable {
        private final List<Object> expectedArguments;
        private final List<Method> methods = new List<Method>();
        private List<Comparator<Object>> comparators = new List<Comparator<Object>>();

        /**
         * @description
         * Constructs an instance of the Arguments class.
         * <br><br>
         * The class represents the grouping of argument values for which a sequence of methods can be registered.
         *
         * @param parent The owning class.
         * @param expectedArguments The arguments that are expected.
         */
        private Arguments(final MockerV1 parent, final List<Object> expectedArguments) {
            AssertionV1.isNotNull(parent, 'argument: Mocker.Arguments.parent');
            AssertionV1.isNotNull(expectedArguments, 'argument: Mocker.Arguments.expectedArguments');

            setParent(parent);
            this.expectedArguments = expectedArguments;

            if (STUBBED_OBJECTS.containsKey(parent.mockedObject)) {
                STUBBED_OBJECTS.get(parent.mockedObject).add(this);
            } else {
                STUBBED_OBJECTS.put(parent.mockedObject, new List<Arguments> { this });
            }
        }

        /**
         * @description
         * Adds comparators to the default comparatros used when checking the arguments for equivalence.
         * <br><br>
         * Any additional comparators will be called before the default ones.
         *
         * @param comparators The additional comparators to be used when checking the expected arguments for equivalence.
         *
         * @return The object instance so it can be chained.
         */
        global MockerV1.Arguments withComparators(final List<Comparator<Object>> comparators) {
            this.comparators = comparators;
            return this;
        }

        /**
         * @description
         * Registers a new method for the expected arguments.
         * <br><br>
         * The method will be called when the arguments are matched.
         *
         * @param methodName The name of the method expected.
         *
         * @return The method instance so it can be chained.
         */
        global MockerV1.Method forMethod(final String methodName) {
            Method method = new Method(this, methodName);
            methods.add(method);
            return method;
        }

        /**
         * @description
         * Checks whether the arguments passed to a mocked class's method match the expected arguments.
         *
         * @param actualArguments The arguments to be checked.
         * @param actualTypes The types of the arguments to be checked.
         *
         * @return True if the arguments match the expected arguments, or false if not.
         */
        private Boolean matches(final List<Object> actualArguments, final List<Type> actualTypes) {
            AssertionV1.isNotNull(actualArguments, 'argument: Mocker.Arguments.matches.actualArguments');

            if (expectedArguments.size() != actualArguments.size()) {
                return false;
            }

            for (Integer i = 0; i < expectedArguments.size(); i++) {
                if (expectedArguments[i] instanceof AnyValue && (actualTypes[i] == ((AnyValue) expectedArguments[i]).type)) {
                    if (((AnyValue) expectedArguments[i]).allowNull || actualArguments[i] != null) {
                        continue;
                    }
                }

                if (!ComparisonHelper.compare(comparators, expectedArguments[i], actualArguments[i])) {
                    return false;
                }
            }

            return true;
        }
    }

    /**
     * @description
     * Class representing an argument to be matched by Type only.
     */
    private with sharing class AnyValue {
        private final Type type { private get; private set; }
        private final Boolean allowNull { private get; private set; }

        /**
         * @description
         * Constructs an instance representing an  argument for the given type.
         *
         * @param type The type to be matched.
         * @param allowNull Can the argument for the type be null.
         */
        public AnyValue(final Type type, final Boolean allowNull) {
            this.type = type;
            this.allowNull = allowNull;
        }
    }
}