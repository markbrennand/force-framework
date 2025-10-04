/**
 * @description
 * <p>
 * Implementation of Query API.
 * <p>
 * The implemention class is private to prevent re-use.
 * <p>
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../LICENSE target="_blank">MIT License</a>.
 * 
 * @author Mark Brennand
 */
public with sharing class QueryImpl {

    /**
     * @description
     * <p>
     * Class inaccessible outside the QueryAPI class providing implementation of the Query API.
     * <p>
     * The Factory class is used to create new instances of this class.
     * <p>
     * As the class maintains state between calls, it must be a prototype class to ensure a new instance is created
     * each time it is injected.
     * <p>
     * See QueryV1.API for method signatures.
     */
    private with sharing class API implements QueryV1.API, DependencyV1.Prototype {
        private SObjectType type;
        private AccessLevel security = AccessLevel.USER_MODE;
        private OptionalV1 returning = OptionalV1.empty();
        private OptionalV1 has = OptionalV1.empty();
        private OptionalV1 aggregates = OptionalV1.empty();
        private OptionalV1 groupBy = OptionalV1.empty();
        private OptionalV1 matching = OptionalV1.empty();
        private OptionalV1 ordering = OptionalV1.empty();
        private OptionalV1 max = OptionalV1.empty();
        private OptionalV1 offset = OptionalV1.empty();
        private OptionalV1 bindings = OptionalV1.empty();
        private Boolean isCount = false;

        public SObjectType type() {
            Assert.isNotNull(type, 'Query type has not been set');
            return type;
        }

        public QueryV1.API type(final SObjectType type) {
            Assert.isNull(this.type, 'Query type cannot be changed');
            this.type = type;
            return this;
        }

        public QueryV1.API security(final AccessLevel security) {
            this.security = security;
            return this;
        }

        public QueryV1.API returningAll() {
            throwExceptionIfCountQuery();
            throwExceptionIfAggregatedQuery();
            return returning(new Set<SObjectField>(type.getDescribe(SObjectDescribeOptions.DEFERRED).fields.getMap().values()));
        }

        public QueryV1.API returning(final SObjectField field) {
            throwExceptionIfCountQuery();
            throwExceptionIfAggregatedQuery();

            final Set<String> value = getValue(returning);
            ArrayV1.over(new List<SObjectField> { field }).reduce(new QueryHelper.FieldToString(), value);

            returning = OptionalV1.of(value);
            return this;
        }

        public QueryV1.API returning(final Set<SObjectField> fields) {
            throwExceptionIfCountQuery();
            throwExceptionIfAggregatedQuery();

            final Set<String> value = getValue(returning);
            ArrayV1.over(fields).reduce(new QueryHelper.FieldToString(), value);

            returning = OptionalV1.of(value);
            return this;
        }

        public QueryV1.API returning(final SObjectField joinField, final Set<SObjectField> fields) {
            throwExceptionIfCountQuery();
            throwExceptionIfAggregatedQuery();

            final Set<String> value = getValue(returning);
            value.addAll(QueryHelper.buildJoinFields(joinField, fields));

            returning = OptionalV1.of(value);
            return this;
        }

        public QueryV1.API returning(final QueryV1.API query) {
            throwExceptionIfCountQuery();
            throwExceptionIfAggregatedQuery();

            final Set<String> value = getValue(returning);
            ArrayV1.over(getChildRelationshipsNames(query.type())).sharing(query).reduce(new AddRelationship(), value);

            returning = OptionalV1.of(value);
            return this;
        }

        public QueryV1.API returning(final QueryV1.AggregatedField field) {
            throwExceptionIfCountQuery();
            throwExceptionIfRegularQuery();

            final Set<String> value = getValue(aggregates);
            ArrayV1.over(new List<QueryV1.AggregatedField> { field }).reduce(new CommonHelper.ToString(), value);

            aggregates = OptionalV1.of(value);
            return this;
        }

        public QueryV1.API returning(final Set<QueryV1.AggregatedField> fields) {
            throwExceptionIfCountQuery();
            throwExceptionIfRegularQuery();

            final Set<String> value = getValue(aggregates);
            ArrayV1.over(fields).reduce(new CommonHelper.ToString(), value);

            aggregates = OptionalV1.of(value);
            return this;
        }

        public QueryV1.API count() {
            throwExceptionIfAggregatedQuery();
            isCount = true;
            return this;
        }

        public QueryV1.API matching(final String condition) {
            matching = OptionalV1.ofNullable(condition);
            return this;
        }

        public QueryV1.API bindings(final Map<String, Object> values) {
            bindings = OptionalV1.of(values);
            return this;
        }

        public QueryV1.API ordered(final QueryV1.Order order) {
            return ordered(new Set<QueryV1.Order> { order });
        }

        public QueryV1.API ordered(final Set<QueryV1.Order> order) {
            throwExceptionIfCountQuery();

            final Set<String> value = getValue(ordering);
            ArrayV1.over(order).reduce(new CommonHelper.ToString(), value);

            ordering = OptionalV1.of(value);
            return this;
        }

        public QueryV1.API group(final Set<SObjectField> fields) {
            throwExceptionIfCountQuery();
            throwExceptionIfRegularQuery();

            final Set<String> value = getValue(groupBy);
            ArrayV1.over(fields).reduce(new QueryHelper.FieldToString(), value);

            groupBy = OptionalV1.of(value);
            return this;
        }

        public QueryV1.API group(final SObjectField joinField, final Set<SObjectField> fields) {
            throwExceptionIfCountQuery();
            throwExceptionIfRegularQuery();

            final Set<String> value = getValue(groupBy);
            value.addAll(QueryHelper.buildJoinFields(joinField, fields));

            groupBy = OptionalV1.of(value);
            return this;
        }

        public QueryV1.API has(final String condition) {
            throwExceptionIfRegularQuery();

            has = OptionalV1.of(condition);
            return this;
        }

        public QueryV1.API max(final Integer max) {
            this.max = OptionalV1.of(' LIMIT ' + max);
            return this;
        }

        public QueryV1.API offset(final Integer offset) {
            this.offset = OptionalV1.of(' OFFSET ' + offset);
            return this;
        }

        public OptionalV1 execute() {
            final String query = buildOuterQuery();

            if (isCount) {
                if (bindings.isPresent()) {
                    return OptionalV1.of(Database.countQueryWithBinds(query, (Map<String, Object>) bindings.get(), security));
                } else {
                    return OptionalV1.of(Database.countQuery(query, security));
                }
            } else {
                final List<SObject> matches;
                if (bindings.isPresent()) {
                    matches = Database.queryWithBinds(query, (Map<String, Object>) bindings.get(), security);
                } else {
                    matches = Database.query(query, security);
                }

                return matches.isEmpty() ? OptionalV1.empty() : OptionalV1.of(ImmutableV1.of(matches));
            }
        }

        private String buildOuterQuery() {
            final Set<String> allFields = new Set<String>();
            if (!aggregates.isPresent()) {
                allFields.add('Id');

                if (returning.isPresent()) {
                    allFields.addAll((Set<String>) returning.get());
                }
            } else {
                allFields.addAll((Set<String>) aggregates.get());
            }

            OptionalV1 order = ordering.isPresent()
                    ? OptionalV1.of(' ORDER BY ' + ArrayV1.over(ordering.get()).join(','))
                    : OptionalV1.empty();

            return ArrayV1.over(
                    new List<String> {
                            'SELECT ',
                            isCount ? 'COUNT()' : ArrayV1.over(allFields).join(','),
                            ' FROM ',
                            type.getDescribe(SObjectDescribeOptions.DEFERRED).name,
                            matching.isPresent() ? ' WHERE ' + (String) matching.get() : '',
                            groupBy.isPresent() ? ' GROUP BY ' + ArrayV1.over(groupBy.get()).join(',') : '',
                            has.isPresent() ? ' HAVING ' + has.get() : '',
                            order.isPresent() ? (String) order.get() : '',
                            max.isPresent() ? (String) max.get() : '',
                            offset.isPresent() ? (String) offset.get() : ''
                    }
            ).join('');
        }

        private String buildInnerQuery(final String relationshipName) {
            final Set<String> allFields = new Set<String> { 'Id' };

            if (returning.isPresent()) {
                allFields.addAll((Set<String>) returning.get());
            }

            OptionalV1 order = ordering.isPresent()
                    ? OptionalV1.of(' ORDER BY ' + ArrayV1.over(ordering.get()).join(','))
                    : OptionalV1.empty();

            return ArrayV1.over(
                    new List<String> {
                            '(SELECT ',
                            ArrayV1.over(allFields).join(','),
                            ' FROM ',
                            relationshipName,
                            matching.isPresent() ? ' WHERE ' + (String) matching.get() : '',
                            order.isPresent() ? (String) order.get() : '',
                            max.isPresent() ? (String) max.get() : '',
                            offset.isPresent() ? (String) offset.get() : '',
                            ')'
                    }
            ).join('');
        }

        private void throwExceptionIfCountQuery() {
            if (isCount) {
                throw new QueryException('Operation may not be performed on a count query');
            }
        }

        private void throwExceptionIfAggregatedQuery() {
            if (aggregates.isPresent()) {
                throw new QueryException('Operation may not be performed on an aggregation query');
            }
        }

        private void throwExceptionIfRegularQuery() {
            if (returning.isPresent()) {
                throw new QueryException('Operation may not be performed on a regular query');
            }
        }

        private List<String> getChildRelationshipsNames(final SObjectType childType) {
            final List<String> relationships = (List<String>) ArrayV1.over(type.getDescribe(SObjectDescribeOptions.FULL).getChildRelationships())
                    .sharing(childType)
                    .reduce(new QueryHelper.GetRelationshipName(), new List<String>());

            if (relationships.isEmpty()) {
                throw new QueryException('No relationship found to object ' + childType.getDescribe(SObjectDescribeOptions.DEFERRED).name);
            }

            return relationships;
        }

        private Set<String> getValue(final OptionalV1 value) {
            return value.isPresent() ? (Set<String>) value.get() : new Set<String>();
        }
    }

    private with sharing class AddRelationship extends ArrayV1.Callback {
        public override OptionalV1 function(final Object element, final OptionalV1 currentValue, final Integer index) {
            ((Set<String>) currentValue.get()).add(((API) shared().get()).buildInnerQuery((String) element));
            return currentValue;
        }
    }

    /**
     * @description
     * <p>
     * Creates the default API implementation.
     * <p>
     * The constructor for the implementation is protected. This prevents the Dependency framework constructing it.
     * We use the factory to defer the construction by injection to this class, which is able to construct it.
     */
    public with sharing class Factory implements TypesV1.Factory {
        public Object newInstance() {
            return new API();
        }
    }
}