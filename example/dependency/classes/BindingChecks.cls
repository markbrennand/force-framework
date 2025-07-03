/**
 * @description
 * Classes providing validation for bindings.
 *
 * @author Mark Brennand
 */
public with sharing class BindingChecks {

    /**
     * @description
     * Class providing validation of any bindings made to QueryInterface and AbstractQuery.
     *
     * A custom metadata record for the BindingCheck__mdt type is used to register the validator.
     */
    public class QueryBindingCheck implements DependencyV1.BindingCheck {
        public DependencyV1.ValidationResult validate(Type forType, Type withImpl) {
            if (forType == QueryClasses.QueryInterface.class) {
                if (TypesV1.newInstance(withImpl) instanceof QueryClasses.QueryInterface) {
                    return new DependencyV1.ValidationResult(true, null);
                } else {
                    return new DependencyV1.ValidationResult(
                            false,
                            'Class "' + withImpl.getName() + '" does not implement "' + forType.getName() + '"'
                    );
                }
            } else if (forType == QueryClasses.AbstractQuery.class) {
                if (TypesV1.newInstance(withImpl) instanceof QueryClasses.AbstractQuery) {
                    return new DependencyV1.ValidationResult(true, null);
                } else {
                    return new DependencyV1.ValidationResult(
                            false,
                            'Class "' + withImpl.getName() + '" does not extend "' + forType.getName() + '"'
                    );
                }
            } else {
                return new DependencyV1.ValidationResult(
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
    public with sharing class MapBindingCheck implements DependencyV1.BindingCheck {
        public DependencyV1.ValidationResult validate(Type forType, Type withImpl) {
            Object impl = TypesV1.newInstance(withImpl);

            switch on forType.getName() {
                when 'Map<String,Integer>' {
                    if (impl instanceof Map<String, Integer>) {
                        return new DependencyV1.ValidationResult(true, null);
                    }
                }
                when else {
                    return new DependencyV1.ValidationResult(
                            false,
                            'Type "' + withImpl + '" can not be validated'
                    );
                }
            }

            return new DependencyV1.ValidationResult(
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
    public with sharing class AccountManagerBindingCheck implements DependencyV1.BindingCheck {
        public DependencyV1.ValidationResult validate(Type forType, Type withImpl) {
            if (TypesV1.newInstance(withImpl) instanceof AccountClasses.AccountManager) {
                return new DependencyV1.ValidationResult(true, null);
            } else {
                return new DependencyV1.ValidationResult(
                        false,
                        'Implementation "' + withImpl.getName() + '" is not an instance of "' + forType.getName() + '"'
                );
            }
        }
    }
}