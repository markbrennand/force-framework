/**
 * @description
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../../LICENSE target="_blank">MIT License</a>.
 * <br><br>
 * Class providing Query API.
 *
 * @author Mark Brennand
 */
global with sharing class QueryV1 {

    global enum Security { NONE, SECURITY_ENFORCED, USER_MODE }

    global interface AggregatedField {
        String getField();
        String getAlias();
        Optional getFunction();
    }

    global interface API {
        SObjectType type();
        API type(final SObjectType type);
        API security(final AccessLevel security);
        API count();
        API returningAll();
        API returning(final Set<SObjectField> fields);
        API returning(final SObjectField joinField, final Set<SObjectField> fields);
        API returning(final Set<AggregatedField> fields);
        API matching(final String condition);
        API ascending(final SObjectField field);
        API descending(final SObjectField field);
        API ascending(final SObjectField field, final Boolean nullsFirst);
        API descending(final SObjectField field, final Boolean nullsFirst);
        API group(final Set<SObjectField> fields);
        API group(final SObjectField joinField, final Set<SObjectField> fields);
        API has(final String condition);
        API children(final API query);
        API max(final Optional max);
        API offset(final Optional offset);
        Optional execute(final Optional bindVars);
    }

    global static API of(final SObjectType type) {
        return QueryAPI.API.type(type);
    }

    global static AggregatedField aggregatedField(final SObjectField field, final String alias) {
        return QueryAPI.aggregatedField(field, Optional.empty(), alias);
    }

    global static AggregatedField aggregatedField(final SObjectField joinField, final SObjectField field, final String alias) {
        return QueryAPI.aggregatedField(joinField, field, Optional.empty(), alias);
    }

    global static AggregatedField aggregatedField(final SObjectField field, final String function, final String alias) {
        return QueryAPI.aggregatedField(field, Optional.of(function), alias);
    }

    global static AggregatedField aggregatedField(final SObjectField joinField, final SObjectField field, final String function, final String alias) {
        return QueryAPI.aggregatedField(joinField, field, Optional.of(function), alias);
    }
}