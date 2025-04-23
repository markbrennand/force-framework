/**
 * @description
 * A registry supporting the binding of an implementation of an interface or abstract class for use in an application.
 *
 * An optional action argument is supported to allow for the binding of the same interface or class with different
 * implementations.
 *
 * By default, the implementation created when bound will be a singleton. If the binding is required to create
 * a new implementation for each use an application, the implementing class should implement the Prototype interface.
 *
 * @author Mark Brennand
 */
global with sharing virtual class Registry {

    /**
     * @description
     * Registry containing bindings from interfaces and abstract classes to implementations.
     */
    private final Map<Key, Factory> REGISTRY = new Map<Key, Factory>();

    /**
     * @description
     * Active API instance.
     *
     * The instance is test visible so it can be mocked.
     */
    @TestVisible
    private static Registry INSTANCE {
        private get {
            if (INSTANCE == null) {
                INSTANCE = new Registry();
            }
            return INSTANCE;
        }
        private set;
    }

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

    private with sharing class Factory {
        private final Type type;
        private Object instance;

        public Factory(final Type type) {
            this.type = type;
        }

        public Object newInstance() {
            if (instance instanceof Prototype) {
                return type.newInstance();
            } else if (instance != null) {
                return instance;
            } else {
                instance = type.newInstance();
                return instance;
            }
        }
    }

    protected Registry() {}

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
    protected Object wireType(final Type forType) {
        addCustomBindings();

        final Key key = new Key(forType);
        if (!REGISTRY.containsKey(key)) {
            throw new APIException(
                    'Binding for "'
                    + forType.getName()
                    +'" not found in registry'
            );
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
    protected Object wireType(final Type forType, final String action) {
        addCustomBindings();

        final Key key = new Key(forType, action);
        if (!REGISTRY.containsKey(key)) {
            throw new APIException(
                    'Binding for "'
                    + forType.getName()
                    + '" for action "'
                    + action
                    + '" not found in registry'
            );
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
    public Boolean isBound(final Type forType) {
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
    public Boolean isBound(final Type forType, final String action) {
        addCustomBindings();
        return REGISTRY.containsKey(new Key(forType, action));
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

    protected virtual void bind(final Type forType, final Type withImpl) {
        validateTypes(forType, withImpl);
        REGISTRY.put(new Key(forType), new Factory(withImpl));
    }

    global static void add(final Type forType, final Type withImpl) {
        INSTANCE.bind(forType, withImpl);
    }

    private void bind(final Type forType, final String action, final Type withImpl) {
        validateTypes(forType, withImpl);
        REGISTRY.put(new Key(forType, action), new Factory(withImpl));
    }

    global static void add(final Type forType, final String action, final Type withImpl) {
        INSTANCE.bind(forType, action, withImpl);
    }

    public static void checkForDuplicates() {
        final List<Binding__c> bindings = [SELECT Type__c, Action__c FROM Binding__c WITH USER_MODE];
        final Set<String> keys = new Set<String>();

        for (Binding__c binding : bindings) {
            if (binding.Action__c == null) {
                if (keys.contains(binding.Type__c)) {
                    throw new Registry.APIException(
                            'Binding for "'
                            + binding.Type__c
                            + '" already exists'
                    );
                }
                keys.add(binding.Type__c);
            } else {
                final String key = binding.Type__c + ':' + binding.Action__c;
                if (keys.contains(key)) {
                    throw new Registry.APIException(
                            'Binding for "'
                            + binding.Type__c
                            + '" for action "'
                            + binding.Action__c
                            + '" already exists'
                    );
                }
                keys.add(key);
            }
        }
    }

    public static void build(List<Binding__c> bindings) {
        for (Binding__c binding : bindings) {
            final Type abstractType = Type.forName(binding.Type__c);
            if (abstractType == null) {
                throw new Registry.APIException(
                        'Type "'
                        + binding.Type__c
                        + '" does not exist'
                );
            }

            final Type implementation = Type.forName(binding.Implementation__c);
            if (implementation == null) {
                throw new Registry.APIException(
                        'Implementation "'
                        + binding.Implementation__c
                        + '" does not exist'
                );
            }

            if (binding.Action__c == null) {
                add(abstractType, implementation);
            } else {
                add(abstractType, binding.Action__c, implementation);
            }
        }
    }

    private with sharing class Key {
        private final Type type;
        private String action;

        public Key(final Type type) {
            this(type, null);
        }

        public Key(final Type type, final String action) {
            this.type = type;
            this.action = action;
        }

        public override Integer hashCode() {
            return (action == null)
                    ? type.hashCode()
                    : (type.hashCode() * 13) + action.hashCode();
        }

        public Boolean equals(final Object other) {
            return (other instanceof Key)
                    && (action == ((Key) other).action)
                    && (type == ((Key) other).type);
        }
    }

    private void validateTypes(final Type forType, final Type withImpl) {
        Boolean instantiable = false;
        try {
            forType.newInstance();
            instantiable = true;
        } catch(Exception e) {
        }

        if (instantiable) {
            throw new Registry.APIException(
                    'Type "'
                    + forType.getName()
                    + '" must not be instantiable'
            );
        }

        try {
            withImpl.newInstance();
        } catch(Exception e) {
            throw new Registry.APIException(
                    'Implementation "'
                    + withImpl.getName()
                    + '" must be instantiable'
            );
        }
    }

    private void addCustomBindings() {
        if (!customBindingsAdded) {
            build([SELECT Type__c, Action__c, Implementation__c FROM Binding__c WITH USER_MODE]);
            customBindingsAdded = true;
        }
    }
}