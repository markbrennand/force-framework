/**
 * @description
 * <p>
 * Binding check for Query API.
 * <p>
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../LICENSE target="_blank">MIT License</a>.
 * 
 * @author Mark Brennand
 */
public with sharing class QueryBinding implements DependencyV1.BindingCheck {

    /**
     * @description
     * <p>
     * Checks that a valid binding has been made to QueryAPI.API.
     *
     * @param forType The type being bound to, QueryAPI.API.
     * @param withImpl The implementation being bound to QueryAPI.API.
     *
     * @return The result of the validation.
     */
    public DependencyV1.ValidationResult validate(final Type forType, final Type withImpl) {
        return DependencyHelper.buildValidationResult(
                TypesV1.newInstance(withImpl) instanceof QueryV1.API,
                true,
                forType,
                withImpl
        );
    }
}