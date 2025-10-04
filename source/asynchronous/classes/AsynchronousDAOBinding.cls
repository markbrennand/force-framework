/**
 * @description
 * <p>
 * Binding check for Asynchronous DAO.
 * <p>
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../LICENSE target="_blank">MIT License</a>.
 * 
 * @author Mark Brennand
 */
public with sharing class AsynchronousDAOBinding implements DependencyV1.BindingCheck {

    /**
     * @description
     * <p>
     * Checks that a valid binding has been made to AsynchronousDAO.API.
     *
     * @param forType The type being bound to, AsynchronousDAO.API.
     * @param withImpl The implementation being bound to AsynchronousDAO.API.
     *
     * @return The result of the validation.
     */
    public DependencyV1.ValidationResult validate(final Type forType, final Type withImpl) {
        return DependencyHelper.buildValidationResult(
                TypesV1.newInstance(withImpl) instanceof AsynchronousDAO.API,
                true,
                forType,
                withImpl
        );
    }
}