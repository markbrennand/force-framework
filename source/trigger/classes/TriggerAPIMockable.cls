/**
 * @description
 * <p>
 * Class providing a mockable implementation of the Trigger API.
 * <p>
 * See <a href=../README.md target="_blank">README</a> for full details of the Query API.
 * <p>
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../LICENSE target="_blank">MIT License</a>.
 *
 * @author Mark Brennand
 */
@SuppressWarnings('PMD.ApexDoc')
public with sharing virtual class TriggerAPIMockable implements TriggerAPI.API {

    public void publish() {
        throw new TriggerV1.APIException('Access denied');
    }

    public void disable(final SObjectType type) {
        throw new TriggerV1.APIException('Access denied');
    }

    public void enable(final SObjectType type) {
        throw new TriggerV1.APIException('Access denied');
    }

    public Boolean isEnabled(final SObjectType type) {
        throw new TriggerV1.APIException('Access denied');
    }

    public void disable(final Type type) {
        throw new TriggerV1.APIException('Access denied');
    }

    public void enable(final Type type) {
        throw new TriggerV1.APIException('Access denied');
    }

    public Boolean isEnabled(final Type type) {
        throw new TriggerV1.APIException('Access denied');
    }
}