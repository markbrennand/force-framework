/**
 * @description
 * Classes providing validation for bindings.
 *
 * @author Mark Brennand
 */
global with sharing class BindingChecks {

    /**
     * @description
     * Class providing validation of any bindings made to QueryInterface and AbstractQuery.
     *
     * A custom metadata record for the BindingCheck__mdt type is used to register the validator.
     */
    global class QueryBindingCheck implements forcefw.DependencyV1.BindingCheck {
        public forcefw.DependencyV1.ValidationResult validate(Type forType, Type withImpl) {
            if (forType == QueryClasses.QueryInterface.class) {
                return forcefw.DependencyV1.validationResult(
                        forcefw.TypesV1.newInstance(withImpl) instanceof QueryClasses.QueryInterface,
                        true,
                        forType,
                        withImpl

                );
            } else if (forType == QueryClasses.AbstractQuery.class) {
                return forcefw.DependencyV1.validationResult(
                        forcefw.TypesV1.newInstance(withImpl) instanceof QueryClasses.AbstractQuery,
                        false,
                        forType,
                        withImpl
                );
            } else {
                return forcefw.DependencyV1.invalid('Type "' + forType.getName() + '" is not supported for validation');
            }
        }
    }

    /**
     * @description
     * Class providing validation of any bindings made to Map<String, Integer>.
     *
     * A custom metadata record for the BindingCheck__mdt type is used to register the validator.
     */
    global with sharing class MapBindingCheck implements forcefw.DependencyV1.BindingCheck {
        public forcefw.DependencyV1.ValidationResult validate(Type forType, Type withImpl) {
            Object impl = forcefw.TypesV1.newInstance(withImpl);

            switch on forType.getName() {
                when 'Map<String,Integer>' {
                    if (impl instanceof Map<String, Integer>) {
                        return forcefw.DependencyV1.valid();
                    }
                }
                when else {
                    return forcefw.DependencyV1.invalid('Type "' + withImpl + '" can not be validated');
                }
            }

            return forcefw.DependencyV1.invalid('Implementation "' + withImpl.getName() + '" is not an instance of "' + forType.getName() + '"');
        }
    }

    /**
    * @description
    * Class providing validation of any bindings made to AccountClasses.AccountManager.
    *
    * A custom metadata record for the BindingCheck__mdt type is used to register the validator.
    */
    global with sharing class AccountManagerBindingCheck implements forcefw.DependencyV1.BindingCheck {
        public forcefw.DependencyV1.ValidationResult validate(Type forType, Type withImpl) {
            return forcefw.DependencyV1.validationResult(
                    forcefw.TypesV1.newInstance(withImpl) instanceof AccountClasses.AccountManager,
                    true,
                    forType,
                    withImpl
            );
        }
    }
}