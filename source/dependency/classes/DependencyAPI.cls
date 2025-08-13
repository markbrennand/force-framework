/**
 * @description
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../LICENSE target="_blank">MIT License</a>.
 * <br><br>
 * Class providing the Dependency Injection API implementation.
 * <br><br>
 * Dependencies can be injected into an application by their interface or abstract class.
 * <br><br>
 * Variable and member variable values can also be injected into a class using the variable's class and an action.
 * <br><br>
 * An optional action argument is supported to allow for the binding of the same interface or class with different
 * implementations.
 * <br><br>
 * By default, the implementation created when injected will be a singleton. If the binding is required to create
 * a new implementation for each use an application, the implementing class should implement the Prototype
 * interface.
 * <br><br>
 * The implementation of the API is hidden in the private Implementation class. The class is hidden so an application
 * cannot access the class to mis-use it.
 * <br><br>
 * All application access is restricted to the API instance variable INSTANCE. This ensures the application can only
 * ever call the methods of the API interface.
 * <br><br>
 * The outer class implements the API only to allow it to be mocked. Any calls to the API method implementations
 * in the outer class will throw an Exception.
 *
 * @author Mark Brennand
 */
public with sharing virtual class DependencyAPI implements API {

    /**
     * @description
     * Mapping from a binding Type to the Binding Check class to validate it.
     */
    @SuppressWarnings('PMD.PropertyNamingConventions')
    private static final Map<Type, List<DependencyV1.BindingCheck>> CHECKS {
        private get {
            if (CHECKS == null) {
                CHECKS = loadBindingChecks();
            }
            return CHECKS;
        }
        private set;
    }

    /**
     * @description
     * Active API instance.
     * <br><br>
     * The instance is test visible so it can be mocked.
     */
    @TestVisible
    @SuppressWarnings('PMD.PropertyNamingConventions')
    public static API API {
        public get {
            if (Test.isRunningTest() && API != null) { // API has been mocked.
                return API;
            } else {
                if (API == null) {
                    API = new Implementation();
                }
                return API;
            }
        }
        private set;
    }
    /**
     * @description
     * Interface defining the API provided by this class.
     * <br><br>
     * It is public as it is not intended for re-implementation outside the package.
     */
    public interface API {

        /**
         * @description
         * If the registry contains a binding for the given type, its implementation is returned.
         * <br><br>
         * Should no binding exist, an exception must be thrown.
         *
         * @param forType The type to be bound.
         *
         * @return The implementation of the given type.
         */
        Object inject(final Type forType);

        /**
         * @description
         * If the registry contains a binding for the given type and action, its implementation is returned.
         * <br><br>
         * Should no binding exist, an exception must be thrown.
         *
         * @param forType The type to be bound.
         * @param action The action specific to the binding to be bound.
         *
         * @return The implementation of the given type.
         */
        Object inject(final Type forType, final String action);

        /**
         * @description
         * Returns true if registry contains a binding for the given type and action, false if not.
         *
         * @param forType The type to be checked.
         *
         * @return True if binding exists, false if not.
         */
        Boolean isBound(final Type forType);

        /**
         * @description
         * Returns true if registry contains a binding for the given type and action, false if not.
         *
         * @param forType The type to be checked.
         * @param action The action specific to the binding to be checked.
         *
         * @return True if binding exists, false if not.
         */
        Boolean isBound(final Type forType, final String action);

        /**
         * @description
         * Adds a binding to the registry.
         *
         * @param forType The type to be bound. Must be either an interface or abstract class.
         * @param withImpl The implementation for the type and action. Must be a concrete class with a no-op constructor.
         */
        void bind(final Type forType, final Type withImpl);

        /**
         * @description
         * Adds a binding to the registry.
         *
         * @param forType The type to be bound. Must be either an interface or abstract class.
         * @param action The action used in combination with the type to uniquely identify the binding.
         * @param withImpl The implementation for the type and action. Must be a concrete class with a no-op constructor.
         */
        void bind(final Type forType, final String action, final Type withImpl);

        /**
         * @description
         * Forces the custom bindings to be reloaded.
         */
        void reload();
    }

    /**
     * @description
     * Class that creates instances of the implementation class for the binding.
     * <br><br>
     * By default, a singleton instance is created on the first call to the new instance method.
     * <br><br>
     * If the class  implements the Prototype interface then a new instance is created for each wiring of the binding.
     */
    private with sharing class Factory {
        private OptionalV1 instance = OptionalV1.empty();
        private final Type type;

        /**
         * @description
         * Constructs a factory which may be called to create an instance of the given class.
         *
         * @param type The type the factory is to construct.
         */
        public Factory(final Type type) {
            this.type = type;
        }

        /**
         * @description
         * Constructs an instance of the implementation class for the binding.
         *
         * @return Either the singleton instance or a new instance if the class being constructed implements Prototype.
         */
        public Object newInstance() {
            if (instance.isPresent()) {
                return instance.get() instanceof DependencyV1.Prototype
                        ? TypesV1.newInstance(type)
                        : instance.get();
            } else {
                instance = OptionalV1.of(TypesV1.newInstance(type));
                return instance.get();
            }
        }
    }

    /**
     * @description
     * Allow extension but not construction.
     * <br><br>
     * This is also required to support the Apex mocking classes. A private constructor cannot be mocked.
     */
    @SuppressWarnings('PMD.EmptyStatementBlock')
    protected DependencyAPI() {}

    /**
     * @description
     * Class providing the implementation of the API.
     */
    private class Implementation implements API {
        /**
         * @description
         * Registry containing bindings from interfaces and abstract classes to implementations.
         */
        private final Map<Key, Factory> registry = new Map<Key, Factory>();

        private Boolean customBindingsAdded = false;

        /**
         * @description
         * If the registry contains a binding for the given type, its implementation is returned.
         * <br><br>
         * Should no binding exist, an exception is thrown.
         *
         * @param forType The type to be bound.
         *
         * @return The implementation of the given type.
         */
        public Object inject(final Type forType) {
            addCustomBindings();

            final Key key = new Key(forType);
            if (!registry.containsKey(key)) {
                throw createException('Binding for', forType.getName(), OptionalV1.empty(), 'not found in registry');
            }

            return registry.get(key).newInstance();
        }

        /**
         * @description
         * If the registry contains a binding for the given type and action, its implementation is returned.
         * <br><br>
         * Should no binding exist, an exception is thrown.
         *
         * @param forType The type to be bound.
         * @param action The action specific to the binding to be bound.
         *
         * @return The implementation of the given type.
         */
        public Object inject(final Type forType, final String action) {
            addCustomBindings();

            final Key key = new ActionKey(forType, action);
            if (!registry.containsKey(key)) {
                throw createException('Binding for', forType.getName(), OptionalV1.of(action), 'not found in registry');
            }

            return registry.get(key).newInstance();
        }

        /**
         * @description
         * Returns true if registry contains a binding for the given type and action, false if not.
         *
         * @param forType The type to be checked.
         *
         * @return True if binding exists, false if not.
         */
        public Boolean isBound(final Type forType) {
            addCustomBindings();
            return registry.containsKey(new Key(forType));
        }

        /**
         * @description
         * Returns true if registry contains a binding for the given type and action, false if not.
         *
         * @param forType The type to be checked.
         * @param action The action specific to the binding to be checked.
         *
         * @return True if binding exists, false if not.
         */
        public Boolean isBound(final Type forType, final String action) {
            addCustomBindings();
            return registry.containsKey(new ActionKey(forType, action));
        }

        /**
         * @description
         * Adds a binding to the registry.
         *
         * @param forType The type to be bound. Must be either an interface or abstract class.
         * @param withImpl The implementation for the type and action. Must be a concrete class with a no-op constructor.
         */
        public void bind(final Type forType, final Type withImpl) {
            validateTypes(forType, OptionalV1.empty(), withImpl);
            registry.put(new Key(forType), new Factory(withImpl));
        }

        /**
         * @description
         * Adds a binding to the registry.
         *
         * @param forType The type to be bound. Must be either an interface or abstract class.
         * @param action The action used in combination with the type to uniquely identify the binding.
         * @param withImpl The implementation for the type and action. Must be a concrete class with a no-op constructor.
         */
        public void bind(final Type forType, final String action, final Type withImpl) {
            validateTypes(forType, OptionalV1.of(action), withImpl);
            registry.put(new ActionKey(forType, action), new Factory(withImpl));
        }

        /**
         * @description
         * Forces the custom bindings to be reloaded.
         */
        public void reload() {
            customBindingsAdded = false;
        }

        /**
         * @description
         * Adds the given custom bindings to the registry.
         *
         * @param bindings The custom bindings to add to the registry.
         */
        public void build(final List<Binding__c> bindings) {
            ArrayV1.over(bindings).sharing(this).forEach(new AddBinding());
        }

        /**
         * @description
         * Selects all the custom bindings and adds them to the registry.
         * <br><br>
         * This method need only be called on the first call to inject a binding.
         */
        private void addCustomBindings() {
            if (!customBindingsAdded) {
                // The Query API is injected into the QueryV1 class. Its use would create a circularity, so use the base
                // implementation.
                build((List<Binding__c>)
                    ((QueryV1.API) new QueryAPI.Factory().newInstance())
                            .type(Binding__c.SObjectType)
                            .security(AccessLevel.USER_MODE)
                            .returning(new Set<SObjectField> { Binding__c.Type__c, Binding__c.Action__c, Binding__c.Implementation__c })
                            .execute(OptionalV1.empty())
                            .orElse(new List<Binding__c>())
                );
                customBindingsAdded = true;
            }
        }

        /**
         * @description
         * Performs basic checks on the type and implementation being bound.
         * <br><br>
         * The type must be an interface or abstract class. The check is that it cannot be instantiated.
         * <br><br>
         * The implementation must be a concrete class with a no-op constructor. The check is that it can be instantiated.
         *
         * @param forType The type to be validated.
         * @param action The action. Optional.empty() if not set.
         * @param withImpl The implementation to be validated.
         */
        private void validateTypes(final Type forType, final OptionalV1 action, final Type withImpl) {
            checkInstantiation(forType, action, withImpl);

            if (CHECKS.containsKey(forType)) {
                for (DependencyV1.BindingCheck check : CHECKS.get(forType)) {
                    DependencyAPI.ValidationResultImpl result = (DependencyAPI.ValidationResultImpl) check.validate(forType, withImpl);
                    if (!result.isValid) {
                        throw new DependencyV1.APIException(result.errorMessage);
                    }
                }
            } else {
                throw createException('Class', forType.getName(), OptionalV1.empty(), 'has no registered bind checker');
            }
        }

        @SuppressWarnings('PMD.EmptyCatchBlock')
        private void checkInstantiation(final Type forType, final OptionalV1 action, final Type withImpl) {
            if (!action.isPresent()) {
                Boolean instantiable = false;
                try {
                    TypesV1.newInstance(forType);
                    instantiable = true;
                } catch (Exception e) {
                }

                if (instantiable) {
                    throw createException('Class', forType.getName(), OptionalV1.empty(),  'must not be instantiable');
                }
            }

            try {
                TypesV1.newInstance(withImpl);
            } catch(Exception e) {
                throw createException('Implementation', withImpl.getName(), OptionalV1.empty(), 'must be instantiable');
            }
        }
    }

    /**
     * @description
     * Checks the custom bindings to see if there are any duplicates.
     * <br><br>
     * A duplicate is;
     * <br>
     * - A type without an action that is bound to more than one implementation.
     * <br>
     * - A type with an action that is bound to more than one implementation.
     */
    public static void checkForDuplicates() {
        // The Query API is injected into the QueryV1 class. Its use would create a circularity, so use the base
        // implementation.
        ((QueryV1.API) new QueryAPI.Factory().newInstance()).type(Binding__c.SObjectType)
                .security(AccessLevel.USER_MODE)
                .returning(new Set<SObjectField> { Binding__c.Type__c, Binding__c.Action__c })
                .execute(OptionalV1.empty())
                .then(new DuplicateCheck());
    }

    /**
     * @description
     * Validates the given bindings.
     *
     * @param bindings The custom bindings to add to the registry.
     */
    public static void validate(final List<Binding__c> bindings) {
        ArrayV1.over(bindings).sharing(new Implementation()).forEach(new BindingValidator());
    }

    /**
     * @description
     * Builds a new validation result.
     *
     * @param isValid True if the validation was successful.
     * @param errorMessage Associated error if validation failed.
     *
     * @return The new validation result.
     */
    public static DependencyV1.ValidationResult newValidationResult(final Boolean isValid, final String errorMessage) {
        return new ValidationResultImpl(isValid, errorMessage);
    }

    /**
     * @description
     * Builds a Map from the Type set in a binding to a Binding Check that can be called to validate its
     * assignment.
     *
     * @return  The Map of Types to Bind Check.
     */
    private static Map<Type, List<DependencyV1.BindingCheck>> loadBindingChecks() {
        return (Map<Type, List<DependencyV1.BindingCheck>>)
                ArrayV1.over(BindingCheck__mdt.getAll().values())
                        .reduce(new AddBindingCheck(), new Map<Type, List<DependencyV1.BindingCheck>>());
    }

    /**
     * @description
     * Callback class to check for a duplicate binding.
     */
    private with sharing class DuplicateCheck implements OptionalV1.Function {
        private final Set<String> keys = new Set<String>();

        /**
         * @description
         * Checks whether any of the bindings are duplicates of current ones in the Binding__c objects.
         *
         * @param value The bindings to be checked.
         *
         * @return The bindings.
         */
        public OptionalV1 apply(OptionalV1 value) {
            if (value.isPresent()) {
                for (Binding__c binding : (List<Binding__c>) value.get()) {
                    if (binding.Action__c == null) {
                        checkType(binding);
                    } else {
                        checkTypeAndAction(binding);
                    }
                }
            }

            return value;
        }

        private void checkType(final Binding__c binding) {
            if (keys.contains(binding.Type__c)) {
                throw createException('Binding for', binding.Type__c, OptionalV1.empty(), 'already exists');
            }
            keys.add(binding.Type__c);
        }

        private void checkTypeAndAction(final Binding__c binding) {
            final String key = binding.Type__c + ':' + binding.Action__c;
            if (keys.contains(key)) {
                throw createException('Binding for', binding.Type__c, OptionalV1.of(binding.Action__c), 'already exists');
            }
            keys.add(key);
        }
    }

    /**
     * @description
     * Callback class to validate a Binding object.
     */
    private with sharing class BindingValidator extends ArrayV1.Callback {
        public override OptionalV1 function(final Object element, final OptionalV1 currentValue, final Integer index) {
            final Binding__c binding = (Binding__c) element;
            final API api = (API) shared().get();

            try {
                final Type type = TypesV1.load(binding.Type__c);
                final Type implementation = TypesV1.load(binding.Implementation__c);

                if (binding.Action__c == null) {
                    api.bind(type, implementation);
                } else {
                    api.bind(type, binding.Action__c, implementation);
                }
            } catch (Exception e) {
                binding.addError(e.getMessage());
            }

            return OptionalV1.empty();
        }
    }

    /**
     * @description
     * Callback class to add a Binding to the registry.
     */
    private with sharing class AddBinding extends ArrayV1.Callback {
        public override OptionalV1 function(final Object element, final OptionalV1 currentValue, final Integer index) {
            final Binding__c binding = (Binding__c) element;
            try {

                final API parent = (API) shared().get();
                final Type type = TypesV1.load(binding.Type__c);
                final Type implementation = TypesV1.load(binding.Implementation__c);

                if (binding.Action__c == null) {
                    parent.bind(type, implementation);
                } else {
                    parent.bind(type, binding.Action__c, implementation);
                }
            } catch (Exception e) {
                binding.addError(e.getMessage());
            }

            return OptionalV1.empty();
        }
    }

    /**
     * @description
     * Callback class to add a Binding Check from a Binding__mdt custom metadata record.
     */
    private with sharing class AddBindingCheck extends ArrayV1.Callback {
        final Boolean isTest = Test.isRunningTest();

        public override OptionalV1 function(final Object element, final OptionalV1 currentValue, final Integer index) {
            final BindingCheck__mdt check = (BindingCheck__mdt) element;
            final Map<Type, List<DependencyV1.BindingCheck>> checks = (Map<Type, List<DependencyV1.BindingCheck>>) currentValue.get();

            if (check.IsUnitTest__c == isTest) {
                AssertionV1.isNotNull(check.Type__C, 'Binding Check Metadata record ' + check.Label + ' has no Type defined');
                AssertionV1.isNotNull(check.BindingCheck__c, 'Binding Check Metadata record ' + check.Label + ' has no BindingCheck class');
                final Type forType = TypesV1.load(check.Type__c);
                final Object checker = TypesV1.newInstance(TypesV1.load(check.BindingCheck__c));

                if (! (checker instanceof DependencyV1.BindingCheck)) {
                    throw createException('Class', check.BindingCheck__c, OptionalV1.empty(), 'does not implement DependencyV1.BindingCheck');
                }

                if (!checks.containsKey(forType)) {
                    checks.put(forType, new List<DependencyV1.BindingCheck> { (DependencyV1.BindingCheck) checker });
                } else {
                    checks.get(forType).add((DependencyV1.BindingCheck) checker);
                }
            }

            return OptionalV1.of(checks);
        }
    }

    /**
     * @description
     * Class used as the basic key to the registry map.
     */
    private with sharing virtual class Key {
        protected final Type type;

        /**
         * @description
         * Constructs a key for the given type.
         *
         * @param type Type the key represents.
         */
        public Key(final Type type) {
            this.type = type;
        }

        /**
         * @description
         * Determines a hash code for the key.
         *
         * @return The hash code.
         */
        public Integer hashCode() {
            return type.hashCode();
        }

        /**
         * @description
         * Determines whether current object and given object are equal.
         * <br><br>
         * As ActionKey extends Key, when comparing keys ensure an ActionKey cannot be compared to a Key.
         *
         * @param other The object to compare with.
         *
         * @return True if objects are equal.
         */
        public virtual Boolean equals(final Object other) {
            return (other instanceof Key) && (! (other instanceof ActionKey)) && (type == ((Key) other).type);
        }
    }

    /**
     * @description
     * Class used as the basic key to the registry map.
     * <br><br>
     * To ensure a balanced Map, the action is not included in the hash code. This may need to be re-considered
     * if many actions are keyed for the same type.
     */
    @SuppressWarnings('PMD.OverrideBothEqualsAndHashcode')
    private with sharing class ActionKey extends Key {
        private final String action;

        /**
         * @description
         * Constructs a key for the given type and action.
         *
         * @param type Type the key represents.
         * @param action The action to be associated with the type.
         */
        public ActionKey(final Type type, final String action) {
            super(type);
            this.action = action;
        }
        /**
         * @description
         * Determines whether current object and given object are equal.
         * <br><br>
         * As ActionKey extends Key, when comparing keys ensure an ActionKey cannot be compared to a Key.
         *
         * @param other The object to compare with.
         *
         * @return True if objects are equal.
         */
        public override Boolean equals(final Object other) {
            return (other instanceof ActionKey)
                    && (action == ((ActionKey) other).action)
                    && (type == ((ActionKey) other).type);
        }
    }

    /**
     * @description
     * Class representing result of a binding validation check.
     */
    @TestVisible
    private with sharing class ValidationResultImpl implements DependencyV1.ValidationResult {

        @TestVisible
        private final Boolean isValid { private get; private set; }

        @TestVisible
        private final String errorMessage { private get; private set; }

        /**
         * @description
         * Constructs a validation result object which is used to inform the caller of the BindingCheck.validate
         * method of the result of the validation.
         *
         * @param isValid True if the validation passed. False if not.
         * @param errorMessage The error message to be recorded in the Exception thrown to record the failure.
         */
        private ValidationResultImpl(final Boolean isValid, final String errorMessage) {
            AssertionV1.isNotNull(isValid, 'argument: DependencyV1.ValidationResult.isValid may not be null');
            AssertionV1.isTrue(isValid || errorMessage != null, 'argument: DependencyAPI.ValidationResultImpl.errorMessage must be set');
            this.isValid = isValid;
            this.errorMessage = errorMessage;
        }
    }

    /**
     * @description
     * Builds an APIException with a common format.
     *
     * @param prefix Prefix from exception message.
     * @param typeName The name of the type the exception is for.
     * @param action The action the exception is for.
     * @param postfix Postfix for exception message.
     *
     * @return A new APIException with a formatted message.
     */
    private static DependencyV1.APIException createException(
            final String prefix,
            final String typeName,
            final OptionalV1 action,
            final String postfix
    ) {
        if (action.isPresent()) {
            return new DependencyV1.APIException(String.join(
                    new List<String>{
                            prefix,
                            ' ',
                            typeName,
                            ' with action ',
                            (String) action.get(),
                            ' ',
                            postfix
                    },
                    ''
            ));
        } else {
            return new DependencyV1.APIException(String.join(
                    new List<String>{
                            prefix,
                            ' ',
                            typeName,
                            ' ',
                            postfix
                    },
                    ''
            ));
        }
    }

    /**
     * @description
     * Method is solely for mocking use.
     *
     * @param forType ignored.
     *
     * @return ignored.
     */
    public Object inject(final Type forType) {
        throw new DependencyV1.APIException('Access denied');
    }

    /**
     * @description
     * Method is solely for mocking use.
     *
     * @param forType ignored.
     * @param action ignored.
     *
     * @return ignored.
     */
    public Object inject(final Type forType, final String action) {
        throw new DependencyV1.APIException('Access denied');
    }

    /**
     * @description
     * Method is solely for mocking use.
     *
     * @param forType ignored.
     *
     * @return ignored.
     */
    public Boolean isBound(final Type forType) {
        throw new DependencyV1.APIException('Access denied');
    }

    /**
     * @description
     * Method is solely for mocking use.
     *
     * @param forType ignored.
     * @param action ignored.
     *
     * @return ignored.
     */
    public Boolean isBound(final Type forType, final String action) {
        throw new DependencyV1.APIException('Access denied');
    }

    /**
    * @description
    * Method is solely for mocking use.
     *
     * @param forType ignored.
     * @param withImpl ignored.
    */
    public void bind(final Type forType, final Type withImpl) {
        throw new DependencyV1.APIException('Access denied');
    }

    /**
     * @description
     * Method is solely for mocking use.
     *
     * @param forType ignored.
     * @param action ignored.
     * @param withImpl ignored.
     */
    public void bind(final Type forType, final String action, final Type withImpl) {
        throw new DependencyV1.APIException('Access denied');
    }

    /**
     * @description
     * Method is solely for mocking use.
     */
    public void reload() {
        throw new DependencyV1.APIException('Access denied');
    }
}