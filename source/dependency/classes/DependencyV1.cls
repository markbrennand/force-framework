/**
 * @description
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../../LICENSE target="_blank">MIT License</a>.
 * <br><br>
 * Class defining the external Dependency API.
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
 * All bound Types are stored in a registry. Each bound Type must have a BindingCheck implementation associated with it.
 * To associate the Type with the BindingCheck, create and deploy a BindingCheck__mdt metadata record. Any attempt
 * to add a binding to the registry for a Type with no associated BindingCheck will throw an Exception.
 * <br><br>
 * See <a href=../README.md target="_blank">README</a> for full details of the Dependency Injection API.
 *
 * @author Mark Brennand
 */
global with sharing class DependencyV1 {

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
        return DependencyAPI.API.inject(forType);
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
        return DependencyAPI.API.inject(forType, action);
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
        return DependencyAPI.API.isBound(forType);
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
        return DependencyAPI.API.isBound(forType, action);
    }

    /**
     * @description
     * Adds a binding to the registry.
     *
     * @param forType The type to be bound. Must be either an interface or abstract class.
     * @param withImpl The implementation for the type and action. Must be a concrete class with a no-op constructor.
     */
    global static void bind(final Type forType, final Type withImpl) {
        DependencyAPI.API.bind(forType, withImpl);
    }

    /**
     * @description
     * Adds a binding to the registry.
     *
     * @param forType The type to be bound. Must be either an interface or abstract class.
     * @param action The action used in combination with the type to uniquely identify the binding.
     * @param withImpl The implementation for the type and action. Must be a concrete class with a no-op constructor.
     */
    global static void bind(final Type forType, final String action, final Type withImpl) {
        DependencyAPI.API.bind(forType, action, withImpl);
    }

    /**
     * @description
     * Forces the custom bindings to be reloaded.
     */
    global static void reload() {
        DependencyAPI.API.reload();
    }
}
