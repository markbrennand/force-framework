/**
 * @description
 * <p>
 * Implementation of Dependency API.
 * <p>
 * Implementation class is private to prevent re-use.
 * <p>
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../LICENSE target="_blank">MIT License</a>.
 * 
 * @author Mark Brennand
 */
public with sharing class DependencyImpl {

    /**
     * @description
     * <p>
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
     * <p>
     * Class providing the implementation of the API.
     */
    private class API implements DependencyAPI.API {

        /**
         * @description
         * <p>
         * Registry containing bindings from interfaces and abstract classes to implementations.
         */
        private final Map<Key, InstanceFactory> registry = new Map<Key, InstanceFactory>();

        private Boolean customBindingsAdded = false;

        /**
         * @description
         * <p>
         * If the registry contains a binding for the given type, its implementation is returned.
         * <p>
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
                throw DependencyHelper.createException('Binding for', forType.getName(), OptionalV1.empty(), 'not found in registry');
            }

            return registry.get(key).newInstance();
        }

        /**
         * @description
         * <p>
         * If the registry contains a binding for the given type and action, its implementation is returned.
         * <p>
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
                throw DependencyHelper.createException('Binding for', forType.getName(), OptionalV1.of(action), 'not found in registry');
            }

            return registry.get(key).newInstance();
        }

        /**
         * @description
         * <p>
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
         * <p>
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
         * <p>
         * Adds a binding to the registry.
         *
         * @param forType The type to be bound. Must be either an interface or abstract class.
         * @param withImpl The implementation for the type and action. Must be a concrete class with a no-op constructor.
         */
        public void bind(final Type forType, final Type withImpl) {
            validateTypes(forType, OptionalV1.empty(), withImpl);
            registry.put(new Key(forType), new InstanceFactory(withImpl));
        }

        /**
         * @description
         * <p>
         * Adds a binding to the registry.
         *
         * @param forType The type to be bound. Must be either an interface or abstract class.
         * @param action The action used in combination with the type to uniquely identify the binding.
         * @param withImpl The implementation for the type and action. Must be a concrete class with a no-op constructor.
         */
        public void bind(final Type forType, final String action, final Type withImpl) {
            validateTypes(forType, OptionalV1.of(action), withImpl);
            registry.put(new ActionKey(forType, action), new InstanceFactory(withImpl));
        }

        /**
         * @description
         * <p>
         * Forces the custom bindings to be reloaded.
         */
        public void reload() {
            customBindingsAdded = false;
        }

        /**
         * @description
         * <p>
         * Adds the given custom bindings to the registry.
         *
         * @param bindings The custom bindings to add to the registry.
         */
        public void build(final List<Binding__c> bindings) {
            ArrayV1.over(bindings).sharing(this).forEach(new DependencyHelper.AddBinding());
        }

        /**
         * @description
         * <p>
         * Selects all the custom bindings and adds them to the registry.
         * <p>
         * This method need only be called on the first call to inject a binding.
         */
        private void addCustomBindings() {
            if (!customBindingsAdded) {
                // The Query API is injected into the QueryV1 class. Its use would create a circularity, so use the base
                // implementation.
                build((List<Binding__c>)
                        ((QueryV1.API) new QueryImpl.Factory().newInstance())
                                .type(Binding__c.SObjectType)
                                .security(AccessLevel.USER_MODE)
                                .returning(Binding__c.Type__c)
                                .returning(Binding__c.Action__c)
                                .returning(Binding__c.Implementation__c)
                                .execute()
                                .then(new CommonHelper.ToList(new List<Binding__c>()))
                                .orElse(new List<Binding__c>())
                );
                customBindingsAdded = true;
            }
        }

        /**
         * @description
         * <p>
         * Performs basic checks on the type and implementation being bound.
         * <p>
         * The type must be an interface or abstract class. The check is that it cannot be instantiated.
         * <p>
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
                    DependencyV1.ValidationResult result = check.validate(forType, withImpl);
                    if (!result.isValid()) {
                        throw new DependencyV1.APIException(result.getErrorMessage());
                    }
                }
            } else {
                throw DependencyHelper.createException('Class', forType.getName(), OptionalV1.empty(), 'has no registered bind checker');
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
                    throw DependencyHelper.createException('Class', forType.getName(), OptionalV1.empty(),  'must not be instantiable');
                }
            }

            try {
                TypesV1.newInstance(withImpl);
            } catch(Exception e) {
                throw DependencyHelper.createException('Implementation', withImpl.getName(), OptionalV1.empty(), 'must be instantiable');
            }
        }
    }

    /**
     * @description
     * <p>
     * Builds a Map from the Type set in a binding to a Binding Check that can be called to validate its
     * assignment.
     *
     * @return  The Map of Types to Bind Check.
     */
    private static Map<Type, List<DependencyV1.BindingCheck>> loadBindingChecks() {
        return (Map<Type, List<DependencyV1.BindingCheck>>)
                ArrayV1.over(BindingCheck__mdt.getAll().values())
                        .reduce(new DependencyHelper.AddBindingCheck(), new Map<Type, List<DependencyV1.BindingCheck>>());
    }

    /**
     * @description
     * <p>
     * Class used as the basic key to the registry map.
     */
    private with sharing virtual class Key {
        protected final Type type;

        /**
         * @description
         * <p>
         * Constructs a key for the given type.
         *
         * @param type Type the key represents.
         */
        public Key(final Type type) {
            this.type = type;
        }

        /**
         * @description
         * <p>
         * Determines a hash code for the key.
         *
         * @return The hash code.
         */
        public virtual Integer hashCode() {
            return type.hashCode();
        }

        /**
         * @description
         * <p>
         * Determines whether current object and given object are equal.
         * <p>
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
     * <p>
     * Class used as the basic key to the registry map.
     * <p>
     * To ensure a balanced Map, the action is not included in the hash code. This may need to be re-considered
     * if many actions are keyed for the same type.
     */
    @SuppressWarnings('PMD.OverrideBothEqualsAndHashcode')
    private with sharing class ActionKey extends Key {
        private final String action;

        /**
         * @description
         * <p>
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
         * <p>
         * Determines whether current object and given object are equal.
         * <p>
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

        /**
         * @description
         * <p>
         * Determines a hash code for the key.
         *
         * @return The hash code.
         */
        public override Integer hashCode() {
            return super.hashCode();
        }
    }

    /**
     * @description
     * <p>
     * Class that creates instances of the implementation class for the binding.
     * <p>
     * By default, a singleton instance is created on the first call to the new instance method.
     * <p>
     * If the class  implements the Prototype interface then a new instance is created for each wiring of the binding.
     */
    private with sharing class InstanceFactory {
        private OptionalV1 instance = OptionalV1.empty();
        private final Type type;

        /**
         * @description
         * <p>
         * Constructs a factory which may be called to create an instance of the given class.
         *
         * @param type The type the factory is to construct.
         */
        public InstanceFactory(final Type type) {
            this.type = type;
        }

        /**
         * @description
         * <p>
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
     * <p>
     * Factory to create the default API implementation.
     */
    public class Factory implements TypesV1.Factory {
        @SuppressWarnings('PMD.ApexDoc')
        public Object newInstance() {
            return new API();
        }
    }
}