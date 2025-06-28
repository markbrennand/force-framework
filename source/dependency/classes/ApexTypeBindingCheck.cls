/**
 * MIT License
 *
 * Copyright (c) 2025 Mark Brennand
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */
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
                return buildValidationResult(TypesV1.newInstance(withImpl) instanceof String, forType, withImpl);
            }
            when 'Integer' {
                return buildValidationResult(TypesV1.newInstance(withImpl) instanceof Integer, forType, withImpl);
            }
            when 'Long' {
                return buildValidationResult(TypesV1.newInstance(withImpl) instanceof Long, forType, withImpl);
            }
            when 'Decimal' {
                return buildValidationResult(TypesV1.newInstance(withImpl) instanceof Decimal, forType, withImpl);
            }
            when 'Double' {
                return buildValidationResult(TypesV1.newInstance(withImpl) instanceof Double, forType, withImpl);
            }
            when 'Map<String,String>' {
                return buildValidationResult(TypesV1.newInstance(withImpl) instanceof Map<String,String>, forType, withImpl);
            }
            when 'Map<String,Integer>' {
                return buildValidationResult(TypesV1.newInstance(withImpl) instanceof Map<String,Integer>, forType, withImpl);
            }
            when 'Map<String,ANY>' {
                return buildValidationResult(TypesV1.newInstance(withImpl) instanceof Map<String,Object>, forType, withImpl);
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
