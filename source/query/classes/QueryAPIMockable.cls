/**
 * @description
 * <p>
 * Class providing a mockable implementation of the Query API.
 * <p>
 * See <a href=../README.md target="_blank">README</a> for full details of the Query API.
 * <p>
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../LICENSE target="_blank">MIT License</a>.
 *
 * @author Mark Brennand
 */
@SuppressWarnings('PMD.ApexDoc')
public with sharing virtual class QueryAPIMockable implements QueryV1.API {

    public QueryV1.API type(final SObjectType type) {
        throw new QueryException('Access denied');
    }

    public SObjectType type() {
        throw new QueryException('Access denied');
    }

    public QueryV1.API security(final AccessLevel security) {
        throw new QueryException('Access denied');
    }

    public QueryV1.API count() {
        throw new QueryException('Access denied');
    }

    public QueryV1.API returningAll() {
        throw new QueryException('Access denied');
    }

    public QueryV1.API returning(final SObjectField joinField, final Set<SObjectField> fields) {
        throw new QueryException('Access denied');
    }

    public QueryV1.API returning(final SObjectField field) {
        throw new QueryException('Access denied');
    }

    public QueryV1.API returning(final Set<SObjectField> fields) {
        throw new QueryException('Access denied');
    }

    public QueryV1.API returning(final QueryV1.API query) {
        throw new QueryException('Access denied');
    }

    public QueryV1.API returning(final QueryV1.AggregatedField field) {
        throw new QueryException('Access denied');
    }

    public QueryV1.API returning(final Set<QueryV1.AggregatedField> fields) {
        throw new QueryException('Access denied');
    }

    public QueryV1.API matching(final String condition) {
        throw new QueryException('Access denied');
    }

    public QueryV1.API ordered(final QueryV1.Order order) {
        throw new QueryException('Access denied');
    }

    public QueryV1.API ordered(final Set<QueryV1.Order> order) {
        throw new QueryException('Access denied');
    }

    public QueryV1.API group(final Set<SObjectField> fields) {
        throw new QueryException('Access denied');
    }

    public QueryV1.API group(final SObjectField joinField, final Set<SObjectField> fields) {
        throw new QueryException('Access denied');
    }

    public QueryV1.API has(final String condition) {
        throw new QueryException('Access denied');
    }

    public OptionalV1 execute() {
        throw new QueryException('Access denied');
    }

    public QueryV1.API max(final Integer max) {
        throw new QueryException('Access denied');
    }

    public QueryV1.API offset(final Integer offset) {
        throw new QueryException('Access denied');
    }

    public QueryV1.API bindings(final Map<String, Object> values) {
        throw new QueryException('Access denied');
    }
}