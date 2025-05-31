/**
 * @description
 * Class providing dependency injection.
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
 * For a detailed description of the dependency injection provided by this class, copy the url below into a browser.
 * <br><br>
 * https://github.com/markbrennand/force-frameworks/blob/main/source/dependency/README.md
 * <br><br>
 * Examples
 * <br>
 * <code>
 * // Inject a variable into your application.
 * Map<String, Integer> configuration = (Map<String, Integer>) Dependency.inject(Map<String, Integer>.class, 'Configuration');
 *
 * // Inject an interface implementation into your application.
 * PersistenceDAO = (PersistenceDAO) Dependency.inject(PersistenceDAO.class);
 * </code>
 *
 * @author Mark Brennand
 */
global with sharing virtual class Dependency {

    /**
     * @description
     * Interface to be implemented to check a binding in the registry.
     * <br><br>
     * Each checker must be defined in a record in the Binding Check custom metadata.
     */
    global interface BindingCheck {

        /**
         * @description
         * Given a type to be bound, a class implementing this method must check that the given implementation class
         * can be bound to it.
         * <br><br>
         * If the for type is an interface then an implementation of this method must check that the implementation
         * class implements the interface.
         * <br><br>
         * If the for type is an abstract class then an implementation of this method must check that the implementation
         * class extends the abstract class.
         * <br><br>
         * If the for type is a class then an implementation of this method must check that the implementation
         * class is of the same class or a super class of it.
         *
         * @param forType The type to be bound.
         * @param withImpl The implementation to bind to the type.
         *
         * @return The result of the validation.
         */
        ValidationResult validate(Type forType, Type withImpl);
    }

    /**
     * @description
     * Class representing result of a binding validation check.
     */
    global with sharing class ValidationResult {
        public final Boolean isValid { public get; private set; }
        public final String errorMessage { public get; private set; }

        /**
         * @description
         * Constructs a validation result object which is used to inform the caller of the BindingCheck.validate
         * method of the result of the validation.
         *
         * @param isValid True if the validation passed. False if not.
         * @param errorMessage The error message to be recorded in the Exception thrown to record the failure.
         */
        global ValidationResult(final Boolean isValid, final String errorMessage) {
            Assertion.isNotNull(isValid, 'argument: Dependency.ValidationResult.isValid may not be null');
            Assertion.isTrue(isValid || errorMessage != null, 'argument: Dependency.ValidationResult.errorMessage must be set');
            this.isValid = isValid;
            this.errorMessage = errorMessage;
        }
    }

    /**
     * @description
     * Mapping from a binding Type to the Binding Check class to validate it.
     */
    private static final Map<Type, List<BindingCheck>> CHECKS {
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
     * Registry containing bindings from interfaces and abstract classes to implementations.
     */
    private final Map<Key, Factory> REGISTRY = new Map<Key, Factory>();

    private Boolean customBindingsAdded = false;

    /**
     * @description
     * Exception thrown when a dependency injection operation fails.
     */
    global with sharing class APIException extends Exception {}

    /**
     * @description
     * A class implementing this interface will have a new instance of itself created each time it is in injected into
     * an application.
     */
    global interface Prototype {}

    /**
     * @description
     * Class that creates instances of the implementation class for the binding.
     * <br><br>
     * By default, a singleton instance is created on the first call to the new instance method.
     * <br><br>
     * If the class  implements the Prototype interface then a new instance is created for each wiring of the binding.
     */
    private with sharing class Factory {
        private final Type type;
        private Object instance;

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
            if (instance instanceof Prototype) {
                return Types.newInstance(type);
            } else if (instance != null) {
                return instance;
            } else {
                instance = Types.newInstance(type);
                return instance;
            }
        }
    }

    /**
     * @description
     * Allow extension but not construction.
     * <br><br>
     * This is also required to support the Apex mocking classes. A private constructor cannot be mocked.
     */
    protected Dependency() {}

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
    protected virtual Object apiInject(final Type forType) {
        addCustomBindings();

        final Key key = new Key(forType);
        if (!REGISTRY.containsKey(key)) {
            throw createException('Binding for', forType.getName(), 'not found in registry');
        }

        return REGISTRY.get(key).newInstance();
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
    protected virtual Object apiInject(final Type forType, final String action) {
        addCustomBindings();

        final Key key = new ActionKey(forType, action);
        if (!REGISTRY.containsKey(key)) {
            throw createException('Binding for', forType.getName(), action, 'not found in registry');
        }

        return REGISTRY.get(key).newInstance();
    }

    /**
     * @description
     * Returns true if registry contains a binding for the given type and action, false if not.
     *
     * @param forType The type to be checked.
     *
     * @return True if binding exists, false if not.
     */
    protected virtual Boolean apiIsBound(final Type forType) {
        addCustomBindings();
        return REGISTRY.containsKey(new Key(forType));
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
    protected virtual Boolean apiIsBound(final Type forType, final String action) {
        addCustomBindings();
        return REGISTRY.containsKey(new ActionKey(forType, action));
    }

    /**
     * @description
     * Adds a binding to the registry.
     *
     * @param forType The type to be bound. Must be either an interface or abstract class.
     * @param withImpl The implementation for the type and action. Must be a concrete class with a no-op constructor.
     */
    protected virtual void apiBind(final Type forType, final Type withImpl) {
        validateTypes(forType, null, withImpl);
        REGISTRY.put(new Key(forType), new Factory(withImpl));
    }

    /**
     * @description
     * Adds a binding to the registry.
     *
     * @param forType The type to be bound. Must be either an interface or abstract class.
     * @param action The action used in combination with the type to uniquely identify the binding.
     * @param withImpl The implementation for the type and action. Must be a concrete class with a no-op constructor.
     */
    protected virtual void apiBind(final Type forType, final String action, final Type withImpl) {
        validateTypes(forType, action, withImpl);
        REGISTRY.put(new ActionKey(forType, action), new Factory(withImpl));
    }

    /**
     * @description
     * Forces the custom bindings to be reloaded.
     */
    protected virtual void apiReload() {
        customBindingsAdded = false;
    }

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
    global static Object inject(final Type forType) {
        return INSTANCE.apiInject(forType);
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
    global static Object inject(final Type forType, final String action) {
        return INSTANCE.apiInject(forType, action);
    }

    /**
     * @description
     * Returns true if registry contains a binding for the given type and action, false if not.
     *
     * @param forType The type to be checked.
     *
     * @return True if binding exists, false if not.
     */
    global static Boolean isBound(final Type forType) {
        return INSTANCE.apiIsBound(forType);
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
    global static Boolean isBound(final Type forType, final String action) {
        return INSTANCE.apiIsBound(forType, action);
    }

    /**
    * @description
    * Adds a binding to the registry.
    * <br><br>
    * This method can be called when creating a default registry for an application.
    *
    * @param forType The type to be bound. Must be either an interface or abstract class.
    * @param withImpl The implementation for the type. Must be a concrete class with a no-op constructor.
    */
    global static void bind(final Type forType, final Type withImpl) {
        INSTANCE.apiBind(forType, withImpl);
    }

    /**
     * @description
     * Adds a binding to the registry.
     * <br><br>
     * This method can be called when creating a default registry for an application.
     *
     * @param forType The type to be bound. Must be either an interface or abstract class.
     * @param action The action used in combination with the type to uniquely identify the binding.
     * @param withImpl The implementation for the type and action. Must be a concrete class with a no-op constructor.
     */
    global static void bind(final Type forType, final String action, final Type withImpl) {
        INSTANCE.apiBind(forType, action, withImpl);
    }

    /**
     * @description
     * Forces the custom bindings to be reloaded.
     * <br><br>
     * When running Apex jobs they can be chained by Salesforce. When using the registry, this method must be called
     * for each job execution, to force any changes made to the custom bindings to be included in the registry.
     */
    global static void reload() {
        INSTANCE.apiReload();
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
        final List<Binding__c> bindings = [SELECT Type__c, Action__c FROM Binding__c WITH USER_MODE];
        final Set<String> keys = new Set<String>();

        for (Binding__c binding : bindings) {
            if (binding.Action__c == null) {
                if (keys.contains(binding.Type__c)) {
                    throw createException('Binding for', binding.Type__c, 'already exists');
                }
                keys.add(binding.Type__c);
            } else {
                final String key = binding.Type__c + ':' + binding.Action__c;
                if (keys.contains(key)) {
                    throw createException('Binding for', binding.Type__c, binding.Action__c, 'already exists');
                }
                keys.add(key);
            }
        }
    }

    /**
     * @description
     * Adds the given custom bindings to the registry.
     *
     * @param bindings The custom bindings to add to the registry.
     */
    public static void build(List<Binding__c> bindings) {
        for (Binding__c binding : bindings) {
            try {
                final Type type = Types.load(binding.Type__c);
                final Type implementation = Types.load(binding.Implementation__c);

                if (binding.Action__c == null) {
                    bind(type, implementation);
                } else {
                    bind(type, binding.Action__c, implementation);
                }
            } catch (Exception e) {
                binding.addError(e.getMessage());
            }
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
     * @param action The action or null if none.
     * @param withImpl The implementation to be validated.
     */
    private void validateTypes(final Type forType, final String action, final Type withImpl) {
        if (action == null) {
            Boolean instantiable = false;
            try {
                Types.newInstance(forType);
                instantiable = true;
            } catch (Exception e) {
            }

            if (instantiable) {
                throw createException('Class', forType.getName(), 'must not be instantiable');
            }
        }

        try {
            Types.newInstance(withImpl);
        } catch(Exception e) {
            throw createException('Implementation', withImpl.getName(), 'must be instantiable');
        }

        if (CHECKS.containsKey(forType)) {
            for (BindingCheck check : CHECKS.get(forType)) {
                ValidationResult result = check.validate(forType, withImpl);
                if (!result.isValid) {
                    throw new APIException(result.errorMessage);
                }
            }
        } else {
            throw createException('Class', forType.getName(), 'has no registered bind checker');
        }
    }

    /**
     * @description
     * Selects all the custom bindings and adds them to the registry.
     * <br><br>
     * This method need only be called on the first call to inject a binding.
     */
    private void addCustomBindings() {
        if (!customBindingsAdded) {
            build([SELECT Type__c, Action__c, Implementation__c FROM Binding__c WITH USER_MODE]);
            customBindingsAdded = true;
        }
    }

    /**
     * @description
     * Builds a Map from the Type set in a binding to a Binding Check that can be called to validate its
     * assignment.
     *
     * @return  The Map of Types to Bind Check.
     */
    private static Map<Type, List<BindingCheck>> loadBindingChecks() {
        final Boolean isTest = Test.isRunningTest();
        final Map<Type, List<BindingCheck>> checks = new Map<Type, List<BindingCheck>>();

        for (BindingCheck__mdt check : BindingCheck__mdt.getAll().values()) {
            if (check.IsUnitTest__c == isTest) {
                final Type forType = Types.load(check.Type__c);
                final Object checker = Types.newInstance(Types.load(check.Checker__c));

                if (! (checker instanceof BindingCheck)) {
                    throw createException('Class', check.Checker__c, 'does not implement BindingCheck');
                }

                if (!checks.containsKey(forType)) {
                    checks.put(forType, new List<BindingCheck> { (BindingCheck) checker });
                } else {
                    checks.get(forType).add((BindingCheck) checker);
                }
            }
        }

        return checks;
    }

    /**
     * @description
     * Class used as the basic key to the registry map.
     */
    private with sharing virtual class Key {
        protected final Type type;

        public Key(final Type type) {
            this.type = type;
        }

        public Integer hashCode() {
            return type.hashCode();
        }

        // As ActionKey extends Key, when comparing keys ensure an ActionKey cannot be compared to a Key.
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
    private with sharing class ActionKey extends Key {
        private String action;

        public ActionKey(final Type type, final String action) {
            super(type);
            this.action = action;
        }

        public override Boolean equals(final Object other) {
            return (other instanceof ActionKey)
                    && (action == ((ActionKey) other).action)
                    && (type == ((ActionKey) other).type);
        }
    }

    /**
     * @description
     * Builds an APIException with a common format.
     *
     * @param prefix Prefix from exception message.
     * @param typeName The name of the type the exception is for.
     * @param postfix Postfix for exception mesgsage.
     *
     * @return A new APIException with a formatted mesgsage.
     */
    private static APIException createException(String prefix, String typeName, String postfix) {
        return new APIException(String.join(
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

    /**
     * @description
     * Builds an APIException with a common format.
     *
     * @param prefix Prefix from exception message.
     * @param typeName The name of the type the exception is for.
     * @param action The action the exception is for.
     * @param postfix Postfix for exception mesgsage.
     *
     * @return A new APIException with a formatted mesgsage.
     */
    private static APIException createException(String prefix, String typeName, String action, String postfix) {
        return new APIException(String.join(
                new List<String>{
                        prefix,
                        ' ',
                        typeName,
                        ' with action ',
                        action,
                        ' ',
                        postfix
                },
                ''
        ));
    }

    /**
     * @description
     * Active API instance.
     * <br><br>
     * The instance is test visible so it can be mocked.
     */
    @TestVisible
    private static Dependency INSTANCE {
        private get {
            if (INSTANCE == null) {
                INSTANCE = new Dependency();
            }
            return INSTANCE;
        }
        private set;
    }
}
