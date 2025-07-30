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
     * Result of a binding validation check.
     */
    global interface ValidationResult {}

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
        ValidationResult validate(final Type forType, final Type withImpl);
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

    /**
     * @description
     * Creates a validation result representing success.
     *
     * @return A validation result representing success.
     */
    global static ValidationResult valid() {
        return DependencyAPI.newValidationResult(true, null);
    }

    /**
     * @description
     * Creates a validation result representing failure.
     *
     * @param errorMessage The validation failure error message.
     *
     * @return A validation result representing failure.
     */
    global static ValidationResult invalid(final String errorMessage) {
        return DependencyAPI.newValidationResult(false, errorMessage);
    }
}
