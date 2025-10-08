/**
 * @description
 * <p>
 * Class providing a mockable implementation of the Dependency API.
 * <p>
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../LICENSE target="_blank">MIT License</a>.
 * 
 * @author Mark Brennand
 */
@SuppressWarnings('PMD.ApexDoc')
public with sharing virtual class DependencyAPIMockable implements DependencyAPI.API {

    public Object inject(final Type forType) {
        throw new DependencyV1.APIException('Access denied');
    }

    public Object inject(final Type forType, final String action) {
        throw new DependencyV1.APIException('Access denied');
    }

    public Boolean isBound(final Type forType) {
        throw new DependencyV1.APIException('Access denied');
    }

    public Boolean isBound(final Type forType, final String action) {
        throw new DependencyV1.APIException('Access denied');
    }

    public void bind(final Type forType, final Type withImpl) {
        throw new DependencyV1.APIException('Access denied');
    }

    public void bind(final Type forType, final String action, final Type withImpl) {
        throw new DependencyV1.APIException('Access denied');
    }

    public void reload() {
        throw new DependencyV1.APIException('Access denied');
    }
}