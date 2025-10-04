/**
 * @description
 * <p>
 * Class providing the Dependency Injection API implementation.
 * <p>
 * Dependencies can be injected into an application by their interface or abstract class.
 * <p>
 * Variable and member variable values can also be injected into a class using the variable's class and an action.
 * <p>
 * An optional action argument is supported to allow for the binding of the same interface or class with different
 * implementations.
 * <p>
 * By default, the implementation created when injected will be a singleton. If the binding is required to create
 * a new implementation for each use an application, the implementing class should implement the Prototype
 * interface.
 * <p>
 * The implementation of the API is hidden in the private Implementation class. The class is hidden so an application
 * cannot access the class to mis-use it.
 * <p>
 * All application access is restricted to the API instance variable INSTANCE. This ensures the application can only
 * ever call the methods of the API interface.
 * <p>
 * The outer class implements the API only to allow it to be mocked. Any calls to the API method implementations
 * in the outer class will throw an Exception.
 * <p>
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../LICENSE target="_blank">MIT License</a>.
 *
 * @author Mark Brennand
 */
public with sharing virtual class DependencyAPI extends DependencyAPIMockable {

    /**
     * @description
     * <p>
     * Active API instance.
     * <p>
     * The instance is test visible so it can be mocked.
     */
    @TestVisible
    public static API impl {
        public get {
            if (Test.isRunningTest() && impl != null) { // API has been mocked.
                return impl;
            } else {
                if (impl == null) {
                    impl = (API) new DependencyImpl.Factory().newInstance();
                }
                return impl;
            }
        }
        private set;
    }
    /**
     * @description
     * <p>
     * Interface defining the API provided by this class.
     * <p>
     * It is public as it is not intended for re-implementation outside the package.
     */
    public interface API {

        /**
         * @description
         * <p>
         * If the registry contains a binding for the given type, its implementation is returned.
         * <p>
         * Should no binding exist, an exception must be thrown.
         *
         * @param forType The type to be bound.
         *
         * @return The implementation of the given type.
         */
        Object inject(final Type forType);

        /**
         * @description
         * <p>
         * If the registry contains a binding for the given type and action, its implementation is returned.
         * <p>
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
         * <p>
         * Returns true if registry contains a binding for the given type and action, false if not.
         *
         * @param forType The type to be checked.
         *
         * @return True if binding exists, false if not.
         */
        Boolean isBound(final Type forType);

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
        Boolean isBound(final Type forType, final String action);

        /**
         * @description
         * <p>
         * Adds a binding to the registry.
         *
         * @param forType The type to be bound. Must be either an interface or abstract class.
         * @param withImpl The implementation for the type and action. Must be a concrete class with a no-op constructor.
         */
        void bind(final Type forType, final Type withImpl);

        /**
         * @description
         * <p>
         * Adds a binding to the registry.
         *
         * @param forType The type to be bound. Must be either an interface or abstract class.
         * @param action The action used in combination with the type to uniquely identify the binding.
         * @param withImpl The implementation for the type and action. Must be a concrete class with a no-op constructor.
         */
        void bind(final Type forType, final String action, final Type withImpl);

        /**
         * @description
         * <p>
         * Forces the custom bindings to be reloaded.
         */
        void reload();
    }

    /**
     * @description
     * <p>
     * Allow extension but not construction.
     * <p>
     * This is also required to support the Apex mocking classes. A private constructor cannot be mocked.
     */
    @SuppressWarnings('PMD.EmptyStatementBlock')
    protected DependencyAPI() {}

    /**
     * @description
     * <p>
     * Validates the given bindings.
     *
     * @param bindings The custom bindings to add to the registry.
     */
    public static void validate(final List<Binding__c> bindings) {
        ArrayV1.over(bindings).sharing(new DependencyImpl.Factory().newInstance()).forEach(new BindingValidator());
    }

    /**
     * @description
     * <p>
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
     * <p>
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
     * <p>
     * Class representing result of a binding validation check.
     */
    @TestVisible
    private with sharing class ValidationResultImpl implements DependencyV1.ValidationResult {

        private final Boolean isValid;
        private final String errorMessage;

        /**
         * @description
         * <p>
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

        public Boolean isValid() {
            return isValid;
        }

        public String getErrorMessage() {
            return errorMessage;
        }
    }

}