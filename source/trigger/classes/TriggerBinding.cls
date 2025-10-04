/**
 * @description
 * <p>
 * Binding checker for Trigger API.
 * <p>
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../LICENSE target="_blank">MIT License</a>.
 * 
 * @author Mark Brennand
 */
public with sharing class TriggerBinding implements DependencyV1.BindingCheck {

    /**
     * @description
     * <p>
     * Checks that a valid binding has been made to TriggerAPI.API.
     *
     * @param forType The type being bound to, TriggerAPI.API.
     * @param withImpl The implementation being bound to TriggerAPI.API.
     *
     * @return The result of the validation.
     */
    public DependencyV1.ValidationResult validate(final Type forType, final Type withImpl) {
        return DependencyHelper.buildValidationResult(
                TypesV1.newInstance(withImpl) instanceof TriggerAPI.API,
                true,
                forType,
                withImpl
        );
    }
}