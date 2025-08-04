/**
 * @description
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../../LICENSE target="_blank">MIT License</a>.
 * <br><br>
 * Helper class providing utility methods for dependency API.
 *
 * @author Mark Brennand
 */
public with sharing class DependencyHelper {

    /**
     * @description
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
}