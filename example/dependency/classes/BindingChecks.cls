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
                    return DependencyV1.valid();
                } else {
                    return DependencyV1.invalid(
                            'Class "' + withImpl.getName() + '" does not implement "' + forType.getName() + '"'
                    );
                }
            } else if (forType == QueryClasses.AbstractQuery.class) {
                if (TypesV1.newInstance(withImpl) instanceof QueryClasses.AbstractQuery) {
                    return DependencyV1.valid();
                } else {
                    return DependencyV1.invalid(
                            'Class "' + withImpl.getName() + '" does not extend "' + forType.getName() + '"'
                    );
                }
            } else {
                return DependencyV1.invalid(
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
                        return DependencyV1.valid();
                    }
                }
                when else {
                    return DependencyV1.invalid(
                            'Type "' + withImpl + '" can not be validated'
                    );
                }
            }

            return DependencyV1.invalid(
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
                return DependencyV1.valid();
            } else {
                return DependencyV1.invalid(
                        'Implementation "' + withImpl.getName() + '" is not an instance of "' + forType.getName() + '"'
                );
            }
        }
    }
}