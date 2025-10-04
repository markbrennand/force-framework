/**
 * @description
 * <p>
 * Helper class providing utility methods for dependency API.
 * <p>
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../LICENSE target="_blank">MIT License</a>.
 *
 * @author Mark Brennand
 */
public with sharing class DependencyHelper {


    /**
     * @description
     * <p>
     * Builds an APIException with a common format.
     *
     * @param prefix Prefix from exception message.
     * @param typeName The name of the type the exception is for.
     * @param action The action the exception is for.
     * @param postfix Postfix for exception message.
     *
     * @return A new APIException with a formatted message.
     */
    public static DependencyV1.APIException createException(
            final String prefix,
            final String typeName,
            final OptionalV1 action,
            final String postfix
    ) {
        if (action.isPresent()) {
            return new DependencyV1.APIException(String.join(
                    new List<String>{
                            prefix,
                            ' ',
                            typeName,
                            ' with action ',
                            (String) action.get(),
                            ' ',
                            postfix
                    },
                    ''
            ));
        } else {
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
    }

    /**
     * @description
     * <p>
     * Return a validation result based on whether the isOfType parameter indicates that the implementation is of the
     * required type.
     *
     * @param isOfType True if the implementation is of the required type.
     * @param isForTypeAnInterface True if the required type is an interface.
     * @param forType The type the implementation is expected to be of.
     * @param withImpl The type of the implementation.
     *
     * @return The validation result.
     */
    public static DependencyV1.ValidationResult buildValidationResult(
            final Boolean isOfType,
            final Boolean isForTypeAnInterface,
            final Type forType,
            final Type withImpl
    ) {
        if (isOfType) {
            return DependencyV1.valid();
        } else {
            return DependencyV1.invalid(
                    isForTypeAnInterface
                        ? 'Class ' + withImpl.getName() + ' does not implement ' + forType.getName()
                        : 'Class ' + withImpl.getName() + ' does not extend ' + forType.getName()
            );
        }
    }

    /**
     * @description
     * <p>
     * Checks the custom bindings to see if there are any duplicates.
     * <p>
     * A duplicate is;
     * <br>
     * - A type without an action that is bound to more than one implementation.
     * <br>
     * - A type with an action that is bound to more than one implementation.
     */
    public static void checkForDuplicates() {
        // The Query API is injected into the QueryV1 class. Its use would create a circularity, so use the base
        // implementation.
        ((QueryV1.API) new QueryImpl.Factory().newInstance()).type(Binding__c.SObjectType)
                .security(AccessLevel.USER_MODE)
                .returning(Binding__c.Type__c)
                .returning(Binding__c.Action__c)
                .execute()
                .then(new CommonHelper.ToList(new List<Binding__c>()))
                .then(new DuplicateCheck());
    }

    /**
     * @description
     * <p>
     * Callback class to add a Binding Check from a Binding__mdt custom metadata record.
     */
    public with sharing class AddBindingCheck extends ArrayV1.Callback {
        final Boolean isTest = Test.isRunningTest();

        /**
         * @description
         * <p>
         * Adds a binding check to the Map of bindings keyed by the interface or class name to be injected.
         *
         * @param element The binding metadata records.
         * @param currentValue The Map of bindings.
         * @param index The positional index of the binding metadata record in its List of objects.
         *
         * @return The Map of bindings.
         */
        public override OptionalV1 function(final Object element, final OptionalV1 currentValue, final Integer index) {
            final BindingCheck__mdt check = (BindingCheck__mdt) element;
            final Map<Type, List<DependencyV1.BindingCheck>> checks = (Map<Type, List<DependencyV1.BindingCheck>>) currentValue.get();

            if (check.IsUnitTest__c == isTest) {
                AssertionV1.isNotNull(check.Type__c, 'Binding Check Metadata record ' + check.Label + ' has no Type defined');
                AssertionV1.isNotNull(check.BindingCheck__c, 'Binding Check Metadata record ' + check.Label + ' has no BindingCheck class');

                final Type forType = TypesV1.load(check.Type__c);
                final Object checker = TypesV1.newInstance(TypesV1.load(check.BindingCheck__c));

                if (! (checker instanceof DependencyV1.BindingCheck)) {
                    throw DependencyHelper.createException('Class', check.BindingCheck__c, OptionalV1.empty(), 'does not implement DependencyV1.BindingCheck');
                }

                if (!checks.containsKey(forType)) {
                    checks.put(forType, new List<DependencyV1.BindingCheck> { (DependencyV1.BindingCheck) checker });
                } else {
                    checks.get(forType).add((DependencyV1.BindingCheck) checker);
                }
            }

            return OptionalV1.of(checks);
        }
    }

    /**
     * @description
     * <p>
     * Callback class to add a Binding to the registry.
     */
    public with sharing class AddBinding extends ArrayV1.Callback {
        public override OptionalV1 function(final Object element, final OptionalV1 currentValue, final Integer index) {
            final Binding__c binding = (Binding__c) element;
            try {

                final DependencyAPI.API parent = (DependencyAPI.API) shared().get();
                final Type type = TypesV1.load(binding.Type__c);
                final Type implementation = TypesV1.load(binding.Implementation__c);

                if (binding.Action__c == null) {
                    parent.bind(type, implementation);
                } else {
                    parent.bind(type, binding.Action__c, implementation);
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
     * Callback class to check for a duplicate binding.
     */
    private with sharing class DuplicateCheck implements OptionalV1.Function {
        private final Set<String> keys = new Set<String>();

        /**
         * @description
         * <p>
         * Checks whether any of the bindings are duplicates of current ones in the Binding__c objects.
         *
         * @param value The bindings to be checked.
         *
         * @return The bindings.
         */
        public OptionalV1 apply(final OptionalV1 value) {
            if (value.isPresent()) {
                for (Binding__c binding : (List<Binding__c>) value.get()) {
                    if (binding.Action__c == null) {
                        checkType(binding);
                    } else {
                        checkTypeAndAction(binding);
                    }
                }
            }

            return value;
        }

        private void checkType(final Binding__c binding) {
            if (keys.contains(binding.Type__c)) {
                throw createException('Binding for', binding.Type__c, OptionalV1.empty(), 'already exists');
            }
            keys.add(binding.Type__c);
        }

        private void checkTypeAndAction(final Binding__c binding) {
            final String key = binding.Type__c + ':' + binding.Action__c;
            if (keys.contains(key)) {
                throw createException('Binding for', binding.Type__c, OptionalV1.of(binding.Action__c), 'already exists');
            }
            keys.add(key);
        }
    }
}