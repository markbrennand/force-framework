/**
 * @description
 * Class providing check on Binding made to an Apex language type.
 *
 * In addition to the primitive types, some Map types are validated too.
 *
 * See [Binding Validation](https://github.com/markbrennand/sf-frameworks/blob/main/source/injection/README.md#Binding-Validation)
 *
 * @author Mark Brennand
 */
public with sharing class BindingCheck implements Injection.BindingCheck {

    /**
     * @description
     * Checks that a valid binding has been made to a primitive type.
     *
     * @param forType The type being bound to.
     * @param withImpl The implementation being bound.
     *
     * @return The result of the validation.
     */
    public Injection.ValidationResult validate(final Type forType, final Type withImpl) {
        switch on forType.getName() {
            when 'String' {
                return buildValidationResult(TypeHelper.newInstance(withImpl) instanceof String, forType, withImpl);
            }
            when 'Integer' {
                return buildValidationResult(TypeHelper.newInstance(withImpl) instanceof Integer, forType, withImpl);
            }
            when 'Long' {
                return buildValidationResult(TypeHelper.newInstance(withImpl) instanceof Long, forType, withImpl);
            }
            when 'Decimal' {
                return buildValidationResult(TypeHelper.newInstance(withImpl) instanceof Decimal, forType, withImpl);
            }
            when 'Double' {
                return buildValidationResult(TypeHelper.newInstance(withImpl) instanceof Double, forType, withImpl);
            }
            when 'Map<String,String>' {
                return buildValidationResult(TypeHelper.newInstance(withImpl) instanceof Map<String,String>, forType, withImpl);
            }
            when 'Map<String,Object>' {
                return buildValidationResult(TypeHelper.newInstance(withImpl) instanceof Map<String,Object>, forType, withImpl);
            }
            when 'Map<String,Integer>' {
                return buildValidationResult(TypeHelper.newInstance(withImpl) instanceof Map<String,Object>, forType, withImpl);
            }
            when else {
                return new Injection.ValidationResult(
                        false,
                        'Class ' + forType.getName() +' is not registered for bind checking'
                );
            }
        }
    }

    /**
     * @description
     * Builds the validation result for the bind check being made on a type.
     *
     * @param isValid True if the implementation is valid for the type.
     * @param forType The type the implementation must extend.
     * @param withImpl The implementation for the type.
     *
     * @return The validation result.
     */
    private Injection.ValidationResult buildValidationResult(final Boolean isValid, final Type forType, final Type withImpl) {
        return isValid
                ? new Injection.ValidationResult(true, null)
                : new Injection.ValidationResult(
                        false,
                        'Class ' + withImpl.getName() + ' cannot be assigned to an ' + forType.getName()
                );
    }
}