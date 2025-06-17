/**
 * @description
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
public with sharing virtual class DependencyImpl implements DependencyV1.API {

    /**
     * @description
     * Mapping from a binding Type to the Binding Check class to validate it.
     */
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
    public static DependencyV1.API INSTANCE {
        public get {
            if (Test.isRunningTest() && INSTANCE != null) { // INSTANCE has been mocked.
                return INSTANCE;
            } else {
                if (INSTANCE == null) {
                    INSTANCE = new APIImpl();
                }
                return INSTANCE;
            }
        }
        private set;
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
            if (instance instanceof DependencyV1.Prototype) {
                return TypesV1.newInstance(type);
            } else if (instance != null) {
                return instance;
            } else {
                instance = TypesV1.newInstance(type);
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
    protected DependencyImpl() {}

    /**
     * @description
     * Class providing the implementation of the API.
     */
    private class APIImpl implements DependencyV1.API {
        /**
         * @description
         * Registry containing bindings from interfaces and abstract classes to implementations.
         */
        private final Map<Key, Factory> REGISTRY = new Map<Key, Factory>();

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
        public Object inject(final Type forType, final String action) {
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
        public Boolean isBound(final Type forType) {
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
        public Boolean isBound(final Type forType, final String action) {
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
        public void bind(final Type forType, final Type withImpl) {
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
        public void bind(final Type forType, final String action, final Type withImpl) {
            validateTypes(forType, action, withImpl);
            REGISTRY.put(new ActionKey(forType, action), new Factory(withImpl));
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
                    TypesV1.newInstance(forType);
                    instantiable = true;
                } catch (Exception e) {
                }

                if (instantiable) {
                    throw createException('Class', forType.getName(), 'must not be instantiable');
                }
            }

            try {
                TypesV1.newInstance(withImpl);
            } catch(Exception e) {
                throw createException('Implementation', withImpl.getName(), 'must be instantiable');
            }

            if (CHECKS.containsKey(forType)) {
                for (DependencyV1.BindingCheck check : CHECKS.get(forType)) {
                    DependencyV1.ValidationResult result = check.validate(forType, withImpl);
                    if (!result.isValid) {
                        throw new DependencyV1.APIException(result.errorMessage);
                    }
                }
            } else {
                throw createException('Class', forType.getName(), 'has no registered bind checker');
            }
        }


        /**
         * @description
         * Adds the given custom bindings to the registry.
         *
         * @param bindings The custom bindings to add to the registry.
         */
        public void build(List<Binding__c> bindings) {
            for (Binding__c binding : bindings) {
                try {
                    final Type type = TypesV1.load(binding.Type__c);
                    final Type implementation = TypesV1.load(binding.Implementation__c);

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
     * Validates the given bindings.
     *
     * @param bindings The custom bindings to add to the registry.
     */
    public static void validate(List<Binding__c> bindings) {
        final APIImpl validationImpl = new APIImpl();

        for (Binding__c binding : bindings) {
            try {
                final Type type = TypesV1.load(binding.Type__c);
                final Type implementation = TypesV1.load(binding.Implementation__c);

                if (binding.Action__c == null) {
                    validationImpl.bind(type, implementation);
                } else {
                    validationImpl.bind(type, binding.Action__c, implementation);
                }
            } catch (Exception e) {
                binding.addError(e.getMessage());
            }
        }
    }

    /**
     * @description
     * Builds a Map from the Type set in a binding to a Binding Check that can be called to validate its
     * assignment.
     *
     * @return  The Map of Types to Bind Check.
     */
    private static Map<Type, List<DependencyV1.BindingCheck>> loadBindingChecks() {
        final Boolean isTest = Test.isRunningTest();
        final Map<Type, List<DependencyV1.BindingCheck>> checks = new Map<Type, List<DependencyV1.BindingCheck>>();

        for (BindingCheck__mdt check : BindingCheck__mdt.getAll().values()) {
            if (check.IsUnitTest__c == isTest) {
                Assertion.isNotNull(check.Type__C, 'Binding Check Metadata record ' + check.Label + ' has no Type defined');
                Assertion.isNotNull(check.BindingCheck__c, 'Binding Check Metadata record ' + check.Label + ' has no BindingCheck class');
                final Type forType = TypesV1.load(check.Type__c);
                final Object checker = TypesV1.newInstance(TypesV1.load(check.BindingCheck__c));

                if (! (checker instanceof DependencyV1.BindingCheck)) {
                    throw createException('Class', check.BindingCheck__c, 'does not implement Dependency.BindingCheck');
                }

                if (!checks.containsKey(forType)) {
                    checks.put(forType, new List<DependencyV1.BindingCheck> { (DependencyV1.BindingCheck) checker });
                } else {
                    checks.get(forType).add((DependencyV1.BindingCheck) checker);
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
     * @return A new APIException with a formatted message.
     */
    private static DependencyV1.APIException createException(String prefix, String typeName, String postfix) {
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

    /**
     * @description
     * Builds an APIException with a common format.
     *
     * @param prefix Prefix from exception message.
     * @param typeName The name of the type the exception is for.
     * @param action The action the exception is for.
     * @param postfix Postfix for exception message.
     *
     * @return A new APIException with a formatted mesgsage.
     */
    private static DependencyV1.APIException createException(String prefix, String typeName, String action, String postfix) {
        return new DependencyV1.APIException(String.join(
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
     * Method is solely for mocking use.
     */
    public Object inject(final Type forType) {
        throw new DependencyV1.APIException('Access denied');
    }

    /**
     * @description
     * Method is solely for mocking use.
     */
    public Object inject(final Type forType, final String action) {
        throw new DependencyV1.APIException('Access denied');
    }

    /**
     * @description
     * Method is solely for mocking use.
     */
    public Boolean isBound(final Type forType) {
        throw new DependencyV1.APIException('Access denied');
    }

    /**
     * @description
     * Method is solely for mocking use.
     */
    public Boolean isBound(final Type forType, final String action) {
        throw new DependencyV1.APIException('Access denied');
    }

    /**
    * @description
    * Method is solely for mocking use.
    */
    public void bind(final Type forType, final Type withImpl) {
        throw new DependencyV1.APIException('Access denied');
    }

    /**
     * @description
     * Method is solely for mocking use.
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