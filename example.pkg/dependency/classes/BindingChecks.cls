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
    global class QueryBindingCheck implements forcefw.Dependency.BindingCheck {
        public forcefw.Dependency.ValidationResult validate(Type forType, Type withImpl) {
            if (forType == QueryClasses.QueryInterface.class) {
                if (forcefw.TypesV1.newInstance(withImpl) instanceof QueryClasses.QueryInterface) {
                    return new forcefw.Dependency.ValidationResult(true, null);
                } else {
                    return new forcefw.Dependency.ValidationResult(
                            false,
                            'Class "' + withImpl.getName() + '" does not implement "' + forType.getName() + '"'
                    );
                }
            } else if (forType == QueryClasses.AbstractQuery.class) {
                if (forcefw.TypesV1.newInstance(withImpl) instanceof QueryClasses.AbstractQuery) {
                    return new forcefw.Dependency.ValidationResult(true, null);
                } else {
                    return new forcefw.Dependency.ValidationResult(
                            false,
                            'Class "' + withImpl.getName() + '" does not extend "' + forType.getName() + '"'
                    );
                }
            } else {
                return new forcefw.Dependency.ValidationResult(
                        false,
                        'Type "' + forType.getName() + '" is not supported for validation'
                );
            }
        }
    }

    /**
     * @description
     * Class providing validation of any bindings made to Map<String, Integer>.
     *
     * A custom metadata record for the BindingCheck__mdt type is used to register the validator.
     */
    global with sharing class MapBindingCheck implements forcefw.Dependency.BindingCheck {
        public forcefw.Dependency.ValidationResult validate(Type forType, Type withImpl) {
            Object impl = forcefw.TypesV1.newInstance(withImpl);

            switch on forType.getName() {
                when 'Map<String,Integer>' {
                    if (impl instanceof Map<String, Integer>) {
                        return new forcefw.Dependency.ValidationResult(true, null);
                    }
                }
                when else {
                    return new forcefw.Dependency.ValidationResult(
                            false,
                            'Type "' + withImpl + '" can not be validated'
                    );
                }
            }

            return new forcefw.Dependency.ValidationResult(
                    false,
                    'Implementation "' + withImpl.getName() + '" is not an instance of "' + forType.getName() + '"'
            );
        }
    }

    /**
    * @description
    * Class providing validation of any bindings made to AccountClasses.AccountManager.
    *
    * A custom metadata record for the BindingCheck__mdt type is used to register the validator.
    */
    global with sharing class AccountManagerBindingCheck implements forcefw.Dependency.BindingCheck {
        public forcefw.Dependency.ValidationResult validate(Type forType, Type withImpl) {
            if (forcefw.TypesV1.newInstance(withImpl) instanceof AccountClasses.AccountManager) {
                return new forcefw.Dependency.ValidationResult(true, null);
            } else {
                return new forcefw.Dependency.ValidationResult(
                        false,
                        'Implementation "' + withImpl.getName() + '" is not an instance of "' + forType.getName() + '"'
                );
            }
        }
    }
}