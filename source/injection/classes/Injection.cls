/**
 * @description
 * Class providing dependency injection.
 *
 * Dependencies can be wired into an application by their interface or abstract class.
 *
 * An optional action argument is supported to allow for the binding of the same interface or class with different
 * implementations.
 *
 * By default, the implementation created when injected will be a singleton. If the binding is required to create
 * a new implementation for each use an application, the implementing class should implement the Prototype interface.
 *
 * @author Mark Brennand
 */
global with sharing virtual class Injection {

    /**
     * @description
     * Interface to be implemented to check a binding in the registry.
     *
     * Each checker must be defined in a record in the Binding Check custom metadata.
     */
    global interface BindingCheck {

        /**
         * @description
         * Given a type to be bound, a class implementing this method must check that the given implementation class
         * can be bound to it.
         *
         * If the for type is an interface then an implementation of this method must check that the implementation
         * class implements the interface.
         *
         * If the for type is an abstract class then an implementation of this method must check that the implementation
         * class extends the abstract class.
         *
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
        global final Boolean isValid { public get; private set; }
        global final String errorMessage { public get; private set; }

        global ValidationResult(final Boolean isValid, final String errorMessage) {
            Assert.isNotNull(isValid, 'isValid may not be null');
            Assert.isTrue(isValid || errorMessage != null, 'Error must be set');
            this.isValid = isValid;
            this.errorMessage = errorMessage;
        }
    }

    /**
     * @description
     * Active API instance.
     *
     * The instance is test visible so it can be mocked.
     */
    @TestVisible
    private static Injection INSTANCE {
        private get {
            if (INSTANCE == null) {
                INSTANCE = new Injection();
            }
            return INSTANCE;
        }
        private set;
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
     * Exception thrown when a registry operation fails.
     */
    global with sharing class APIException extends Exception {}

    /**
     * @description
     * A class implementing this interface will have a new instance of itself created each time it is wired into an
     * application.
     */
    global interface Prototype {}

    /**
     * @description
     * Class that creates instances of the implementation class for the binding.
     *
     * By default, a singleton instance is created on the first call to the new instance method. If the class
     * implements the Prototype interface then a new instance is created for each wiring of the binding.
     */
    private with sharing class Factory {
        private final Type type;
        private Object instance;

        public Factory(final Type type) {
            this.type = type;
        }

        /**
         * @description
         * Constructs an instance of the implementation class for the bindiong.
         *
         * @return Either the singleton instance or a new instance if the class being constructed implements Prototype.
         */
        public Object newInstance() {
            if (instance instanceof Prototype) {
                return TypeHelper.newInstance(type);
            } else if (instance != null) {
                return instance;
            } else {
                instance = TypeHelper.newInstance(type);
                return instance;
            }
        }
    }

    /**
     * @description
     * Allow extension but not construction.
     *
     * This is also required to support the Apex mocking classes. A private constructor cannot be mocked.
     */
    protected Injection() {}

    /**
     * @description
     * If the registry contains a binding for the given type, its implementation is returned.
     *
     * Should no binding exist, an exception is thrown.
     *
     * @param forType The type to be bound.
     *
     * @return The implementation of the given type.
     */
    protected virtual Object wireType(final Type forType) {
        addCustomBindings();

        final Key key = new Key(forType);
        if (!REGISTRY.containsKey(key)) {
            throw createException('Binding for', forType.getName(), 'not found in registry');
        }

        return REGISTRY.get(key).newInstance();
    }

    /**
     * @description
     * If the registry contains a binding for the given type, its implementation is returned.
     *
     * Should no binding exist, an exception is thrown.
     *
     * @param forType The type to be bound.
     *
     * @return The implementation of the given type.
     *
     * @example
     * // Binds the implementation bound to MyInterface into an application.
     * MyInterface example = (MyInterface) Registry.wire(MyInterface.class);
     */
    global static Object wire(final Type forType) {
        return INSTANCE.wireType(forType);
    }

    /**
     * @description
     * If the registry contains a binding for the given type and action, its implementation is returned.
     *
     * Should no binding exist, an exception is thrown.
     *
     * @param forType The type to be bound.
     * @param action The action specific to the binding to be bound.
     *
     * @return The implementation of the given type.
     */
    protected virtual Object wireType(final Type forType, final String action) {
        addCustomBindings();

        final Key key = new ActionKey(forType, action);
        if (!REGISTRY.containsKey(key)) {
            throw createException('Binding for', forType.getName(), action, 'not found in registry');
        }

        return REGISTRY.get(key).newInstance();
    }

    /**
     * @description
     * If the registry contains a binding for the given type and action, its implementation is returned.
     *
     * Should no binding exist, an exception is thrown.
     *
     * @param forType The type to be bound.
     * @param action The action specific to the binding to be bound.
     *
     * @return The implementation of the given type.
     *
     * @example
     * // Binds the implementation bound to MyInterface into an application for action MyAction.
     * MyInterface example = (MyInterface) Registry.wire(MyInterface.class, 'MyAction');
     */
    global static Object wire(final Type forType, final String action) {
        return INSTANCE.wireType(forType, action);
    }

    /**
     * @description
     * Returns true if registry contains a binding for the given type and action, false if not.
     *
     * @param forType The type to be checked.
     *
     * @return True if binding exists, false if not.
     */
    protected virtual Boolean isBound(final Type forType) {
        addCustomBindings();
        return REGISTRY.containsKey(new Key(forType));
    }

    /**
     * @description
     * Returns true if registry contains a binding for the given type and action, false if not.
     *
     * @param forType The type to be checked.
     *
     * @return True if binding exists, false if not.
     *
     * @example
     * // Determine if binding for MyInterface exists in registry.
     * Boolean exists = Registry.has(MyInterface.class);
     */
    global static Boolean has(final Type forType) {
        return INSTANCE.isBound(forType);
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
    protected virtual Boolean isBound(final Type forType, final String action) {
        addCustomBindings();
        return REGISTRY.containsKey(new ActionKey(forType, action));
    }

    /**
     * @description
     * Returns true if registry contains a binding for the given type and action, false if not.
     *
     * @param forType The type to be checked.
     * @param action The action specific to the binding to be checked.
     *
     * @return True if binding exists, false if not.
     *
     * @example
     * // Determine if binding for MyInterface with action MyAction exists in registry.
     * Boolean exists = Registry.has(MyInterface.class, 'MyAction');
     */
    global static Boolean has(final Type forType, final String action) {
        return INSTANCE.isBound(forType, action);
    }

    /**
     * @description
     * Adds a binding to the registry.
     *
     * @param forType The type to be bound. Must be either an interface or abstract class.
     * @param withImpl The implementation for the type and action. Must be a concrete class with a no-op constructor.
     */
    protected virtual void bind(final Type forType, final Type withImpl) {
        validateTypes(forType, null, withImpl);
        REGISTRY.put(new Key(forType), new Factory(withImpl));
    }

    /**
    * @description
    * Adds a binding to the registry.
    *
    * This method can be called when creating a default registry for an application.
    *
    * @param forType The type to be bound. Must be either an interface or abstract class.
    * @param withImpl The implementation for the type. Must be a concrete class with a no-op constructor.
    *
    * @example
    * // Add a binding to MyImplementation from interface MyInterface.
    * Registgry.add(MyInterface,class, MyImplementation.class);
    */
    global static void add(final Type forType, final Type withImpl) {
        INSTANCE.bind(forType, withImpl);
    }

    /**
     * @description
     * Adds a binding to the registry.
     *
     * @param forType The type to be bound. Must be either an interface or abstract class.
     * @param action The action used in combination with the type to uniquely identify the binding.
     * @param withImpl The implementation for the type and action. Must be a concrete class with a no-op constructor.
     */
    protected virtual void bind(final Type forType, final String action, final Type withImpl) {
        validateTypes(forType, action, withImpl);
        REGISTRY.put(new ActionKey(forType, action), new Factory(withImpl));
    }

    /**
     * @description
     * Adds a binding to the registry.
     *
     * This method can be called when creating a default registry for an application.
     *
     * @param forType The type to be bound. Must be either an interface or abstract class.
     * @param action The action used in combination with the type to uniquely identify the binding.
     * @param withImpl The implementation for the type and action. Must be a concrete class with a no-op constructor.
     *
     * @example
     * // Add a binding to MyImplementation from interface MyInterface for action Test.
     * Registgry.add(MyInterface,class, 'Test', MyImplementation.class);
     */
    global static void add(final Type forType, final String action, final Type withImpl) {
        INSTANCE.bind(forType, action, withImpl);
    }

    /**
     * @description
     * Checks the custom bindings to see if there are any duplicates.
     *
     * A duplicate is;
     * - A type without an action that is bound to more than one implementation.
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
        try {
            for (Binding__c binding : bindings) {
                final Type type = TypeHelper.loadType(binding.Type__c);
                final Type implementation = TypeHelper.loadType(binding.Implementation__c);

                if (binding.Action__c == null) {
                    add(type, implementation);
                } else {
                    add(type, binding.Action__c, implementation);
                }
            }
        } catch(Exception e) {
            throw new APIException(e.getMessage(), e);
        }
    }

    /**
     * @description
     * Performs basic checks on the type and implementation being bound.
     *
     * The type must be an interface or abstract class. The check is that it cannot be instantiated.
     *
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
                System.debug(forType);
                TypeHelper.newInstance(forType);
                instantiable = true;
            } catch (Exception e) {
            }

            if (instantiable) {
                throw createException('Type', forType.getName(), 'must not be instantiable');
            }
        }

        try {
            TypeHelper.newInstance(withImpl);
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
            throw createException('Type', forType.getName(), 'has no registered bind checker');
        }
    }

    /**
     * @description
     * Selects all the custom bindings and adds them to the registry.
     *
     * This method need only be called on the first call to wire a binding.
     */
    private void addCustomBindings() {
        if (!customBindingsAdded) {
            build([SELECT Type__c, Action__c, Implementation__c FROM Binding__c WITH USER_MODE]);
            customBindingsAdded = true;
        }
    }

    /**
     * @description
     * Builds a Map from the Type set in a binding to a Binding Check that can be called to validat its
     * assignment.
     *
     * @return  The Map of Types to Bind Check.
     */
    private static Map<Type, List<BindingCheck>> loadBindingChecks() {
        final Boolean isTest = Test.isRunningTest();
        final Map<Type, List<BindingCheck>> checks = new Map<Type, List<BindingCheck>>();

        for (BindingCheck__mdt check : BindingCheck__mdt.getAll().values()) {
            if (check.IsUnitTest__c == isTest) {
                final Type forType = TypeHelper.loadType(check.Type__c);
                final Object checker = TypeHelper.newInstance(TypeHelper.loadType(check.Checker__c));

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
     *
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
                        ' "',
                        typeName,
                        '" ',
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
                        ' "',
                        typeName,
                        '"',
                        ' with action "',
                        action,
                        '" ',
                        postfix
                },
                ''
        ));
    }
}
