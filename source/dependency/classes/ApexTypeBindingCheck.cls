/**
 * @description
 * Class providing check on Binding made to an Apex language type.
 * <br><br>
 * In addition to the primitive types, some Map types are validated too.
 *<br><br>
 * See <a href=../README.md target="_blank">README</a> for full details of Dependency.BindingCheck API.
 *
 * @author Mark Brennand
 */
public with sharing class ApexTypeBindingCheck implements Dependency.BindingCheck {

    /**
     * @description
     * Checks that a valid binding has been made to a primitive type.
     *
     * @param forType The type being bound to.
     * @param withImpl The implementation being bound.
     *
     * @return The result of the validation.
     */
    public Dependency.ValidationResult validate(final Type forType, final Type withImpl) {
        switch on forType.getName() {
            when 'String' {
                return buildValidationResult(Types.newInstance(withImpl) instanceof String, forType, withImpl);
            }
            when 'Integer' {
                return buildValidationResult(Types.newInstance(withImpl) instanceof Integer, forType, withImpl);
            }
            when 'Long' {
                return buildValidationResult(Types.newInstance(withImpl) instanceof Long, forType, withImpl);
            }
            when 'Decimal' {
                return buildValidationResult(Types.newInstance(withImpl) instanceof Decimal, forType, withImpl);
            }
            when 'Double' {
                return buildValidationResult(Types.newInstance(withImpl) instanceof Double, forType, withImpl);
            }
            when 'Map<String,String>' {
                return buildValidationResult(Types.newInstance(withImpl) instanceof Map<String,String>, forType, withImpl);
            }
            when 'Map<String,Integer>' {
                return buildValidationResult(Types.newInstance(withImpl) instanceof Map<String,Integer>, forType, withImpl);
            }
            when 'Map<String,ANY>' {
                return buildValidationResult(Types.newInstance(withImpl) instanceof Map<String,Object>, forType, withImpl);
            }
            when else {
                return new Dependency.ValidationResult(
                        false,
                        'Class ' + forType.getName() + ' is not registered for bind checking'
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
    private Dependency.ValidationResult buildValidationResult(final Boolean isValid, final Type forType, final Type withImpl) {
        return isValid
                ? new Dependency.ValidationResult(true, null)
                : new Dependency.ValidationResult(
                        false,
                        'Class ' + withImpl.getName() + ' cannot be assigned to an ' + forType.getName()
                );
    }
}
