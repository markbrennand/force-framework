/**
 * @description
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../../LICENSE target="_blank">MIT License</a>.
 * <br><br>
 * Class providing Query API.
 * <br><br>
 * See <a href=../README.md target="_blank">README</a> for full details of the Array API.
 *
 * @author Mark Brennand
 */
global with sharing class QueryV1 {

    /**
     * @description
     * Implementation dependent representation  of an aggregated field.
     */
    global interface AggregatedField {}

    /**
     * @description
     * Implementation dependent representation of a SOQL order clause.
     */
    global interface Order {}

    /**
     * @description
     * Interface defining the actions required for querying.
     * <br><br>
     * A new implementation of the Query API must implement all the methods of this interface. It can then add a
     * Dependency Injection Binding to inject it as the implementation used in the QueryAPI class.
     */
    global interface API {

        /**
         * @description
         * Yields the type of the object being queried.
         *
         * @return The type of object.
         */
        SObjectType type();

        /**
         * @description
         * Sets the type of object to query.
         *
         * @param type The object type.
         *
         * @return The current API instance so it can be chained.
         *
         */
        API type(final SObjectType type);

        /**
         * @description
         * Sets the access level for the query.
         * <br><br>
         * In SYSTEM mode, no CRUD or FLS checks should be performed. In USER mode, CRUD and FLS checks must be performed.
         *
         * @param security The access level for the query.
         *
         * @return The current API instance so it can be chained.
         */
        API security(final AccessLevel security);

        /**
         * @description
         * Marks the query as a count.
         * <br><br>
         * The OptionalV1 returned by the execute method will contain an Integer with the result.
         *
         * @return The current API instance so it can be chained.
         */
        API count();

        /**
         * @description
         * Selects all the fields in the object being queried for return.
         * <br><br>
         * Only the fields the user has FLS read access to are returned.
         * <br><br>
         * No fields in joined objects or child relationships are returned.
         *
         * @return The current API instance so it can be chained.
         */
        API returningAll();

        API returning(final Set<SObjectField> fields);
        API returning(final SObjectField joinField, final Set<SObjectField> fields);
        API returning(final API query);
        API returning(final Set<AggregatedField> fields);
        API matching(final String condition);
        API ordered(final Order order);
        API ordered(final Set<Order> order);
        API group(final Set<SObjectField> fields);
        API group(final SObjectField joinField, final Set<SObjectField> fields);
        API has(final String condition);
        API max(final Integer max);
        API offset(final Integer offset);
        OptionalV1 execute(final OptionalV1 bindVars);
    }

    global static API of(final SObjectType type) {
        return QueryAPI.API.type(type);
    }

    global static Order ascending(final SObjectField field) {
        return QueryAPI.order(OptionalV1.empty(), field, true, OptionalV1.empty());
    }

    global static Order ascending(final SObjectField field, final Boolean nullsFirst) {
        return QueryAPI.order(OptionalV1.empty(), field, true, OptionalV1.of(nullsFirst));
    }

    global static Order ascending(final SObjectField joinField, final SObjectField field) {
        return QueryAPI.order(OptionalV1.of(joinField), field, true, OptionalV1.empty());
    }

    global static Order ascending(final SObjectField joinField, final SObjectField field, final Boolean nullsFirst) {
        return QueryAPI.order(OptionalV1.of(joinField), field, true, OptionalV1.of(nullsFirst));
    }

    global static Order ascending(final AggregatedField field) {
        return QueryAPI.order(field, true, OptionalV1.empty());
    }

    global static Order ascending(final AggregatedField field, final Boolean nullsFirst) {
        return QueryAPI.order(field, true, OptionalV1.of(nullsFirst));
    }

    global static Order descending(final AggregatedField field) {
        return QueryAPI.order(field, false, OptionalV1.empty());
    }

    global static Order descending(final AggregatedField field, final Boolean nullsFirst) {
        return QueryAPI.order(field, false, OptionalV1.of(nullsFirst));
    }

    global static Order descending(final SObjectField field) {
        return QueryAPI.order(OptionalV1.empty(), field, false, OptionalV1.empty());
    }

    global static Order descending(final SObjectField field, final Boolean nullsFirst) {
        return QueryAPI.order(OptionalV1.empty(), field, false, OptionalV1.of(nullsFirst));
    }

    global static Order descending(final SObjectField joinField, final SObjectField field) {
        return QueryAPI.order(OptionalV1.of(joinField), field, false, OptionalV1.empty());
    }

    global static Order descending(final SObjectField joinField, final SObjectField field, final Boolean nullsFirst) {
        return QueryAPI.order(OptionalV1.of(joinField), field, false, OptionalV1.of(nullsFirst));
    }

    global static AggregatedField aggregatedField(final SObjectField field, final String alias) {
        return QueryAPI.aggregatedField(OptionalV1.empty(), field, OptionalV1.empty(), alias);
    }

    global static AggregatedField aggregatedField(final SObjectField joinField, final SObjectField field, final String alias) {
        return QueryAPI.aggregatedField(OptionalV1.of(joinField), field, OptionalV1.empty(), alias);
    }

    global static AggregatedField aggregatedField(final String function, final SObjectField field, final String alias) {
        return QueryAPI.aggregatedField(OptionalV1.empty(), field, OptionalV1.of(function), alias);
    }

    global static AggregatedField aggregatedField(final SObjectField joinField, final String function, final SObjectField field, final String alias) {
        return QueryAPI.aggregatedField(OptionalV1.of(joinField), field, OptionalV1.of(function), alias);
    }
}