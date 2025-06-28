/**
 * MIT License
 *
 * Copyright (c) 2025 Mark Brennand
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */
/**
 * @description
 * Class defining the Dependency Injection API.
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
global with sharing class Dependency {

    /**
     * @description
     * Exception thrown when a dependency injection operation fails.
     */
    global with sharing class APIException extends Exception {}

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
     * A class implementing this interface will have a new instance of itself created each time it is in injected into
     * an application.
     */
    global interface Prototype {}


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
}
