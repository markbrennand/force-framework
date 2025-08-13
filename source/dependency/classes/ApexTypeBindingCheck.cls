/**
 * @description
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../LICENSE target="_blank">MIT License</a>.
 * <br><br>
 * Class providing check on Binding made to an Apex language type.
 * <br><br>
 * In addition to the primitive types, some Map types are validated too.
 * <br><br>
 * See <a href=../README.md target="_blank">README</a> for full details of DependencyV1.BindingCheck API.
 *
 * @author Mark Brennand
 */
public with sharing class ApexTypeBindingCheck implements DependencyV1.BindingCheck {

    /**
     * @description
     * Checks that a valid binding has been made to a primitive type.
     *
     * @param forType The type being bound to.
     * @param withImpl The implementation being bound.
     *
     * @return The result of the validation.
     */
    public DependencyV1.ValidationResult validate(final Type forType, final Type withImpl) {
        switch on forType.getName() {
            when 'String' {
                return DependencyHelper.buildValidationResult(TypesV1.newInstance(withImpl) instanceof String, false, forType, withImpl);
            }
            when 'Integer' {
                return DependencyHelper.buildValidationResult(TypesV1.newInstance(withImpl) instanceof Integer, false, forType, withImpl);
            }
            when 'Long' {
                return DependencyHelper.buildValidationResult(TypesV1.newInstance(withImpl) instanceof Long, false, forType, withImpl);
            }
            when 'Decimal' {
                return DependencyHelper.buildValidationResult(TypesV1.newInstance(withImpl) instanceof Decimal, false, forType, withImpl);
            }
            when 'Double' {
                return DependencyHelper.buildValidationResult(TypesV1.newInstance(withImpl) instanceof Double, false, forType, withImpl);
            }
            when 'Map<String,String>' {
                return DependencyHelper.buildValidationResult(TypesV1.newInstance(withImpl) instanceof Map<String, String>, false, forType, withImpl);
            }
            when 'Map<String,Integer>' {
                return DependencyHelper.buildValidationResult(TypesV1.newInstance(withImpl) instanceof Map<String, Integer>, false, forType, withImpl);
            }
            when 'Map<String,ANY>' {
                return DependencyHelper.buildValidationResult(TypesV1.newInstance(withImpl) instanceof Map<String, Object>, false, forType, withImpl);
            }
            when else {
                return DependencyV1.invalid('Class ' + forType.getName() + ' is not registered for bind checking');
            }
        }
    }
}
