/**
 * @description
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../../LICENSE target="_blank">MIT License</a>.
 * <br><br>
 * Class providing Query API.
 *
 * @author Mark Brennand
 */
global with sharing class QueryV1 {

    global interface AggregatedField {}

    global interface Order {}

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
        API ordered(final Order order);
        API ordered(final List<Order> order);
        API group(final Set<SObjectField> fields);
        API group(final SObjectField joinField, final Set<SObjectField> fields);
        API has(final String condition);
        API children(final API query);
        API max(final Integer max);
        API offset(final Integer offset);
        OptionalV1 execute(final OptionalV1 bindVars);
    }

    global static API of(final SObjectType type) {
        return QueryAPI.API.type(type);
    }

    global static Order ascending(final SObjectField field) {
        return QueryAPI.order(field, true, OptionalV1.empty(), OptionalV1.empty());
    }

    global static Order ascending(final SObjectField field, final Boolean nullsFirst) {
        return QueryAPI.order(field, true, OptionalV1.empty(), OptionalV1.of(nullsFirst));
    }

    global static Order ascending(final SObjectField joinField, final SObjectField field) {
        return QueryAPI.order(field, true, OptionalV1.of(joinField), OptionalV1.empty());
    }

    global static Order ascending(final SObjectField joinField, final SObjectField field, final Boolean nullsFirst) {
        return QueryAPI.order(field, true, OptionalV1.of(joinField), OptionalV1.of(nullsFirst));
    }

    global static Order descending(final SObjectField field) {
        return QueryAPI.order(field, false, OptionalV1.empty(), OptionalV1.empty());
    }

    global static Order descending(final SObjectField field, final Boolean nullsFirst) {
        return QueryAPI.order(field, false, OptionalV1.empty(), OptionalV1.of(nullsFirst));
    }

    global static Order descending(final SObjectField joinField, final SObjectField field) {
        return QueryAPI.order(field, false, OptionalV1.of(joinField), OptionalV1.empty());
    }

    global static Order descending(final SObjectField joinField, final SObjectField field, final Boolean nullsFirst) {
        return QueryAPI.order(field, false, OptionalV1.of(joinField), OptionalV1.of(nullsFirst));
    }

    global static AggregatedField aggregatedField(final SObjectField field, final String alias) {
        return QueryAPI.aggregatedField(field, OptionalV1.empty(), alias);
    }

    global static AggregatedField aggregatedField(final SObjectField joinField, final SObjectField field, final String alias) {
        return QueryAPI.aggregatedField(joinField, field, OptionalV1.empty(), alias);
    }

    global static AggregatedField aggregatedField(final String function, final SObjectField field, final String alias) {
        return QueryAPI.aggregatedField(field, OptionalV1.of(function), alias);
    }

    global static AggregatedField aggregatedField(final String function, final SObjectField joinField, final SObjectField field, final String alias) {
        return QueryAPI.aggregatedField(joinField, field, OptionalV1.of(function), alias);
    }
}