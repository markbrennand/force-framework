/**
 * @description
 * <p>
 * Class providing Query API.
 * <p>
 * See <a href=../../source/query/README.md target="_blank">README</a> for full details of the Query API.
 * <p>
 * Copyright (c) 2025 Mark Brennand, released under <a href=../LICENSE target="_blank">MIT License</a>.
 *
 * @author Mark Brennand
 */
@SuppressWarnings('PMD.AvoidGlobalModifier')
global with sharing class QueryV1 {

    /**
     * @description
     * <p>
     * Implementation dependent representation  of an aggregated field.
     */
    global interface AggregatedField {}

    /**
     * @description
     * <p>
     * Representation of an SOQL order clause.
     */
    global interface Order {

        /**
         * @description
         * <p>
         * Returns the field that the results will be ordered by.
         *
         * @return The field to be ordered by.
         */
        String getField();

        /**
         * @description
         * <p>
         * Returns true if the results are to be ordered in ascending value, false if descending.
         *
         * @return True is the results are returned in ascending order, false if descending.
         */
        Boolean isAscending();

        /**
         * @description
         * <p>
         * Returns an OptionalV1 representing whether null values for the associated field are to be included in the
         * results at the start or end.
         * <p>
         * If the return value is not set in the OptionalV1, then the default null ordering is being used.
         * <p>
         * Otherwise, a value of true indicates null values will be returned first and false indicates last.
         *
         * @return An OptionalV1 representing the ordering of null values.
         */
        OptionalV1 isNullsFirst();

        /**
         * @description
         * <p>
         * Sets the result ordering to null values first.
         *
         * @return The current instance so it can be chained.
         */
        Order nullsFirst();

        /**
         * @description
         * <p>
         * Sets the result ordering to null values last.
         *
         * @return The current instance so it can be chained.
         */
        Order nullsLast();
    }

    /**
     * @description
     * <p>
     * Interface defining the actions required for querying.
     * <p>
     * A new implementation of the Query API must implement all the methods of this interface. It can then add a
     * Dependency Injection Binding to inject it as the implementation used in the QueryAPI class.
     */
    global interface API {

        /**
         * @description
         * <p>
         * Yields the type of the object being queried.
         *
         * @return The type of object.
         */
        SObjectType type();

        /**
         * @description
         * <p>
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
         * <p>
         * Sets the access level for the query.
         * <p>
         * In SYSTEM mode, no CRUD or FLS checks should be performed. In USER mode, CRUD and FLS checks must be performed.
         *
         * @param security The access level for the query.
         *
         * @return The current API instance so it can be chained.
         */
        API security(final AccessLevel security);

        /**
         * @description
         * <p>
         * Marks the query as a count.
         * <p>
         * The OptionalV1 returned by the execute method will contain an Integer with the result.
         *
         * @return The current API instance so it can be chained.
         */
        API count();

        /**
         * @description
         * <p>
         * Selects all the fields in the object being queried for return.
         * <p>
         * Only the fields the user has FLS read access to are returned.
         * <p>
         * No fields in joined objects or child relationships are returned.
         *
         * @return The current API instance so it can be chained.
         */
        API returningAll();

        /**
         * @description
         * <p>
         * Adds the given field to the fields to be returned by the query.
         * <p>
         * The fields to be returned are accumulated from all the calls to the returning methods.
         *
         * @param field The field to return.
         *
         * @return The current API instance so it can be chained.
         */
        API returning(final SObjectField field);

        /**
         * @description
         * <p>
         * Adds the given fields to the fields to be returned by the query.
         * <p>
         * The fields to be returned are accumulated from all the calls to the returning methods.
         *
         * @param fields The fields to return.
         *
         * @return The current API instance so it can be chained.
         */
        API returning(final Set<SObjectField> fields);

        /**
         * @description
         * <p>
         * Adds the given fields from a related object to the fields to be returned by the query.
         * <p>
         * The fields to be returned are accumulated from all the calls to the returning methods.
         *
         * @param joinField The Id field in the object being queried that links to the related object.
         * @param fields The fields to return.
         *
         * @return The current API instance so it can be chained.
         */
        API returning(final SObjectField joinField, final Set<SObjectField> fields);

        /**
         * @description
         * <p>
         * Adds the given sub query to the fields.
         * <p>
         * The SObjectType of the sub query is used to determine the child relationship(s) from the object being
         * queried to the object associated with the sub query. A query field is added to the query for each
         * child relationship.
         * <p>
         * The fields to be returned are accumulated from all the calls to the returning methods.
         *
         * @param query The sub query.
         *
         * @return The current API instance so it can be chained.
         */
        API returning(final API query);

        /**
         * @description
         * <p>
         * Adds the given aggregated field to the fields to be returned by the query.
         * <p>
         * The fields to be returned are accumulated from all the calls to the returning methods.
         *
         * @param field The aggregated field to return.
         *
         * @return The current API instance so it can be chained.
         */
        API returning(final AggregatedField field);

        /**
         * @description
         * <p>
         * Adds the given aggregated fields to the fields to be returned by the query.
         * <p>
         * The fields to be returned are accumulated from all the calls to the returning methods.
         *
         * @param fields The aggregated fields to return.
         *
         * @return The current API instance so it can be chained.
         */
        API returning(final Set<AggregatedField> fields);

        /**
         * @description
         * <p>
         * Sets the WHERE clause for the query.
         * <p>
         * The condition may include bind variables. The Map passed to the execute method must include a definition
         * for each bind variable in the condition.
         *
         * @param condition The query WHERE clause.
         *
         * @return The current API instance so it can be chained.
         */
        API matching(final String condition);

        /**
         * @description
         * <p>
         * Adds a result ordering to the query.
         * <p>
         * The result ordering is determined by the accumulation of all the ordered calls.
         *
         * @param order The result order to add to the query.
         *
         * @return The current API instance so it can be chained.
         */
        API ordered(final Order order);

        /**
         * @description
         * <p>
         * Adds result orderings to the query.
         * <p>
         * The result ordering is determined by the accumulation of all the ordered calls.
         *
         * @param order The result orders to add to the query.
         *
         * @return The current API instance so it can be chained.
         */
        API ordered(final Set<Order> order);

        /**
         * @description
         * <p>
         * For an aggregated query, sets the fields to group the results by.
         * <p>
         * The grouping is determined by the accumulation of all the group calls.
         *
         * @param fields The fields to group the results by.
         *
         * @return The current API instance so it can be chained.
         */
        API group(final Set<SObjectField> fields);

        /**
         * @description
         * <p>
         * For an aggregated query, sets the fields in a related object to group the results by.
         * <p>
         * The grouping is determined by the accumulation of all the group calls.
         *
         * @param joinField The Id field in the object being queried that links to the related object.
         * @param fields The fields to group the results by.
         *
         * @return The current API instance so it can be chained.
         */
        API group(final SObjectField joinField, final Set<SObjectField> fields);

        API has(final String condition);
        API max(final Integer max);
        API offset(final Integer offset);
        OptionalV1 execute(final OptionalV1 bindVars);
    }

    global static API of(final SObjectType type) {
        return QueryAPI.API.type(type);
    }

    global static API count(final SObjectType type) {
        return QueryAPI.API.type(type).count();
    }

    global static Order ascending(final SObjectField field) {
        return QueryAPI.order(OptionalV1.empty(), field, true);
    }

    global static Order ascending(final SObjectField joinField, final SObjectField field) {
        return QueryAPI.order(OptionalV1.of(joinField), field, true);
    }

    global static Order ascending(final AggregatedField field) {
        return QueryAPI.order(field, true);
    }

    global static Order descending(final SObjectField field) {
        return QueryAPI.order(OptionalV1.empty(), field, false);
    }

    global static Order descending(final SObjectField joinField, final SObjectField field) {
        return QueryAPI.order(OptionalV1.of(joinField), field, false);
    }

    global static Order descending(final AggregatedField field) {
        return QueryAPI.order(field, false);
    }

    /**
     * @description
     * <p>
     * Builds a field which may be used to aggregate data in a query.
     *
     * @param field The field to aggregate the results by.
     * @param alias The AggregateResult records returned will have the value keyed by the alias.
     *
     * @return An aggregate field which can be used in the query.
     */
    global static AggregatedField aggregatedField(final SObjectField field, final String alias) {
        return QueryAPI.aggregatedField(OptionalV1.empty(), OptionalV1.empty(), field, alias);
    }

    /**
     * @description
     * <p>
     * Builds a field from a related object which may be used to aggregate data in a query.
     *
     * @param joinField The field which links the related object.
     * @param field The field in the related object to aggregate the results by.
     * @param alias The AggregateResult records returned will have the value keyed by the alias.
     *
     * @return An aggregate field which can be used in the query.
     */
    global static AggregatedField aggregatedField(final SObjectField joinField, final SObjectField field, final String alias) {
        return QueryAPI.aggregatedField(OptionalV1.empty(), OptionalV1.of(joinField), field, alias);
    }

    /**
     * @description
     * <p>
     * Builds a field from a related object which may be used to aggregate data in a query.
     *
     * @param function The aggregation function to use, e.g. COUNT or SUM.
     * @param field The field in the related object to aggregate the results by.
     * @param alias The AggregateResult records returned will have the value keyed by the alias.
     *
     * @return An aggregate field which can be used in the query.
     */
    global static AggregatedField aggregatedField(final String function, final SObjectField field, final String alias) {
        return QueryAPI.aggregatedField(OptionalV1.of(function), OptionalV1.empty(), field, alias);
    }

    /**
     * @description
     * <p>
     * Builds a field from a related object which may be used to aggregate data in a query.
     *
     * @param function The aggregation function to use, e.g. COUNT or SUM.
     * @param joinField The field which links the related object.
     * @param field The field in the related object to aggregate the results by.
     * @param alias The AggregateResult records returned will have the value keyed by the alias.
     *
     * @return An aggregate field which can be used in the query.
     */
    global static AggregatedField aggregatedField(final String function, final SObjectField joinField, final SObjectField field, final String alias) {
        return QueryAPI.aggregatedField(OptionalV1.of(function), OptionalV1.of(joinField), field, alias);
    }
}