/**
 * @description
 * Classes providing validation for bindings.
 *
 * @author Mark Brennand
 */
public with sharing class BindingValidators {

    /**
     * @description
     * Class providing validation of any bindings made to QueryInterface and AbstractQuery.
     *
     * A custom metadata record for the BindingCheck__mdt type is used to register the validator.
     */
    public class QueryValidator implements Dependency.BindingCheck {
        public Dependency.ValidationResult validate(Type forType, Type withImpl) {
            if (forType == QueryClasses.QueryInterface.class) {
                if (TypeHelper.newInstance(withImpl) instanceof QueryClasses.QueryInterface) {
                    return new Dependency.ValidationResult(true, null);
                } else {
                    return new Dependency.ValidationResult(
                            false,
                            'Class "' + withImpl.getName() + '" does not implement "' + forType.getName() + '"'
                    );
                }
            } else if (forType == QueryClasses.AbstractQuery.class) {
                if (TypeHelper.newInstance(withImpl) instanceof QueryClasses.AbstractQuery) {
                    return new Dependency.ValidationResult(true, null);
                } else {
                    return new Dependency.ValidationResult(
                            false,
                            'Class "' + withImpl.getName() + '" does not extend "' + forType.getName() + '"'
                    );
                }
            } else {
                return new Dependency.ValidationResult(
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
    public with sharing class MapValidator implements Dependency.BindingCheck {
        public Dependency.ValidationResult validate(Type forType, Type withImpl) {
            Object impl = TypeHelper.newInstance(withImpl);

            switch on forType.getName() {
                when 'Map<String,Integer>' {
                    if (impl instanceof Map<String, Integer>) {
                        return new Dependency.ValidationResult(true, null);
                    }
                }
                when else {
                    return new Dependency.ValidationResult(
                            false,
                            'Type "' + withImpl + '" can not be validated'
                    );
                }
            }

            return new Dependency.ValidationResult(
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
    public with sharing class AccountManagerValidator implements Dependency.BindingCheck {
        public Dependency.ValidationResult validate(Type forType, Type withImpl) {
            if (TypeHelper.newInstance(withImpl) instanceof AccountClasses.AccountManager) {
                return new Dependency.ValidationResult(true, null);
            } else {
                return new Dependency.ValidationResult(
                        false,
                        'Implementation "' + withImpl.getName() + '" is not an instance of "' + forType.getName() + '"'
                );
            }
        }
    }
}