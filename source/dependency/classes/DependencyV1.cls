/**
 * @description
 * <p/>
 * Class defining the external Dependency API.
 * <p/>
 * Dependencies can be injected into an application by their interface or abstract class.
 * <p/>
 * Variable and member variable values can also be injected into a class using the variable's class and an action.
 * <p/>
 * An optional action argument is supported to allow for the binding of the same interface or class with different
 * implementations.
 * <p/>
 * By default, the implementation created when injected will be a singleton. If the binding is required to create
 * a new implementation for each use an application, the implementing class should implement the Prototype
 * interface.
 * <p/>
 * All bound Types are stored in a registry. Each bound Type must have a BindingCheck implementation associated with it.
 * To associate the Type with the BindingCheck, create and deploy a BindingCheck__mdt metadata record. Any attempt
 * to add a binding to the registry for a Type with no associated BindingCheck will throw an Exception.
 * <p/>
 * See <a href=../../source/dependency/README.md target="_blank">README</a> for full details of the Dependency Injection API.
 * <p/>
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../LICENSE target="_blank">MIT License</a>.
 *
 * @author Mark Brennand
 */
@SuppressWarnings('PMD.AvoidGlobalModifier')
global with sharing class DependencyV1 {

    /**
     * @description
     * <p/>
     * Exception thrown when a dependency injection operation fails.
     */
    global with sharing class APIException extends ForceFwException {}

    /**
     * @description
     * <p/>
     * A class implementing this interface will have a new instance of itself created each time it is in injected into
     * an application.
     */
    global interface Prototype {}

    /**
     * @description
     * <p/>
     * Result of a binding validation check.
     */
    global interface ValidationResult {}

    /**
     * @description
     * <p/>
     * Interface to be implemented to check a binding in the registry.
     * <p/>
     * Each checker must be defined in a record in the Binding Check custom metadata.
     */
    global interface BindingCheck {

        /**
         * @description
         * <p/>
         * Given a type to be bound, a class implementing this method must check that the given implementation class
         * can be bound to it.
         * <p/>
         * If the for type is an interface then an implementation of this method must check that the implementation
         * class implements the interface.
         * <p/>
         * If the for type is an abstract class then an implementation of this method must check that the implementation
         * class extends the abstract class.
         * <p/>
         * If the for type is a class then an implementation of this method must check that the implementation
         * class is of the same class or a super class of it.
         *
         * @param forType The type to be bound.
         * @param withImpl The implementation to bind to the type.
         *
         * @return The result of the validation.
         */
        DependencyV1.ValidationResult validate(final Type forType, final Type withImpl);
    }

    /**
     * @description
     * <p/>
     * If the registry contains a binding for the given type, its implementation is returned.
     * <p/>
     * Should no binding exist, an exception is thrown.
     *
     * @param forType The type to be bound.
     *
     * @return The implementation of the given type.
     */
    global static Object inject(final Type forType) {
        return DependencyAPI.impl.inject(forType);
    }

    /**
     * @description
     * <p/>
     * If the registry contains a binding for the given type and action, its implementation is returned.
     * <p/>
     * Should no binding exist, an exception is thrown.
     *
     * @param forType The type to be bound.
     * @param action The action specific to the binding to be bound.
     *
     * @return The implementation of the given type.
     */
    global static Object inject(final Type forType, final String action) {
        return DependencyAPI.impl.inject(forType, action);
    }

    /**
     * @description
     * <p/>
     * Returns true if registry contains a binding for the given type and action, false if not.
     *
     * @param forType The type to be checked.
     *
     * @return True if binding exists, false if not.
     */
    global static Boolean isBound(final Type forType) {
        return DependencyAPI.impl.isBound(forType);
    }

    /**
     * @description
     * <p/>
     * Returns true if registry contains a binding for the given type and action, false if not.
     *
     * @param forType The type to be checked.
     * @param action The action specific to the binding to be checked.
     *
     * @return True if binding exists, false if not.
     */
    global static Boolean isBound(final Type forType, final String action) {
        return DependencyAPI.impl.isBound(forType, action);
    }

    /**
     * @description
     * <p/>
     * Adds a binding to the registry.
     *
     * @param forType The type to be bound. Must be either an interface or abstract class.
     * @param withImpl The implementation for the type and action. Must be a concrete class with a no-op constructor.
     */
    global static void bind(final Type forType, final Type withImpl) {
        DependencyAPI.impl.bind(forType, withImpl);
    }

    /**
     * @description
     * <p/>
     * Adds a binding to the registry.
     *
     * @param forType The type to be bound. Must be either an interface or abstract class.
     * @param action The action used in combination with the type to uniquely identify the binding.
     * @param withImpl The implementation for the type and action. Must be a concrete class with a no-op constructor.
     */
    global static void bind(final Type forType, final String action, final Type withImpl) {
        DependencyAPI.impl.bind(forType, action, withImpl);
    }

    /**
     * @description
     * <p/>
     * Forces the custom bindings to be reloaded.
     */
    global static void reload() {
        DependencyAPI.impl.reload();
    }

    /**
     * @description
     * <p/>
     * Creates a validation result representing success.
     *
     * @return A validation result representing success.
     */
    global static DependencyV1.ValidationResult valid() {
        return DependencyAPI.newValidationResult(true, null);
    }

    /**
     * @description
     * <p/>
     * Creates a validation result representing failure.
     *
     * @param errorMessage The validation failure error message.
     *
     * @return A validation result representing failure.
     */
    global static DependencyV1.ValidationResult invalid(final String errorMessage) {
        return DependencyAPI.newValidationResult(false, errorMessage);
    }
}