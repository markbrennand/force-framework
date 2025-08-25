/**
 * @description
 * <p/>
 * Class providing the default implementation of the Query API.
 * <p/>
 * All application access is restricted to the API instance variable API. This ensures the application can only
 * ever call the methods of the API interface.
 * <p/>
 * The outer class implements the API only to allow it to be mocked. Any calls to the API method implementations
 * in the outer class will throw an Exception.
 * <p/>
 * See <a href=../README.md target="_blank">README</a> for full details of the Query API.
 * <p/>
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../LICENSE target="_blank">MIT License</a>.
 *
 * @author Mark Brennand
 */
@SuppressWarnings('PMD.ApexDoc')
public with sharing virtual class QueryAPI extends MockableQueryAPI {

    /**
     * @description
     * <p/>
     * Active API instance.
     * <p/>
     * The instance is injected from the Registry. As the instance maintains state between calls, a new instance
     * must be injected each time it is requested.
     * <p/>
     * The instance is test visible so it can be mocked.
     * <p/>
     * Any implementation must be of type DependencyV1.Prototype as state must be maintained.
     */
    @TestVisible
    public static QueryV1.API impl {
        public get {
            if (Test.isRunningTest() && impl != null) { // API has been mocked.
                return impl;
            } else {
                return (QueryV1.API) DependencyV1.inject(QueryV1.API.class);
            }
        }
        private set;
    }

    private enum SortOrder { ASCENDING, DESCENDING }

    /**
     * @description
     * <p/>
     * Allow extension but not construction.
     * <p/>
     * This is also required to support the Apex mocking classes. A private constructor cannot be mocked.
     */
    @SuppressWarnings('PMD.EmptyStatementBlock')
    protected QueryAPI() {}

    /**
     * @description
     * <p/>
     * Class inaccessible outside the QueryAPI class providing implementation of the Query API.
     * <p/>
     * The Factory class is used to create new instances of this class.
     * <p/>
     * As the class maintains state between calls, it must be a prototype class to ensure a new instance is created
     * each time it is injected.
     * <p/>
     * See QueryV1.API for method signatures.
     */
    private with sharing class Implementation implements QueryV1.API, DependencyV1.Prototype {
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
            ArrayV1.over(new List<SObjectField> { field }).reduce(new FieldToString(), value);

            returning = OptionalV1.of(value);
            return this;
        }

        public QueryV1.API returning(final Set<SObjectField> fields) {
            throwExceptionIfCountQuery();
            throwExceptionIfAggregatedQuery();

            final Set<String> value = getValue(returning);
            ArrayV1.over(fields).reduce(new FieldToString(), value);

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
            ArrayV1.over(fields).reduce(new FieldToString(), value);

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
                    .reduce(new GetRelationshipName(), new List<String>());

            if (relationships.isEmpty()) {
                throw new QueryException('No relationship found to object ' + childType.getDescribe(SObjectDescribeOptions.DEFERRED).name);
            }

            return relationships;
        }

        private Set<String> getValue(final OptionalV1 value) {
            return value.isPresent() ? (Set<String>) value.get() : new Set<String>();
        }
    }

    /**
     * @description
     * <p/>
     * Creates the default API implementation.
     * <p/>
     * The constructor for the implementation is protected. This prevents the Dependency framework constructing it.
     * We use the factory to defer the construction by injection to this class, which is able to construct it.
     */
    public with sharing class Factory implements TypesV1.Factory {
        public Object newInstance() {
            return new Implementation();
        }
    }

    /**
     * @description
     * <p/>
     * Class providing check on Binding made to AsynchronousAPI.API.
     */
    public with sharing class BindingCheck implements DependencyV1.BindingCheck {

        public DependencyV1.ValidationResult validate(final Type forType, final Type withImpl) {
            return DependencyHelper.buildValidationResult(
                    TypesV1.newInstance(withImpl) instanceof QueryV1.API,
                    true,
                    forType,
                    withImpl
            );
        }
    }

    public static QueryV1.AggregatedField aggregatedField(final OptionalV1 function, final OptionalV1 joinField, final SObjectField field, final String alias) {
        return new AggregatedFieldImpl(joinField, field, function, alias);
    }

    public static QueryV1.Order order(final OptionalV1 joinField, final SObjectField field, final Boolean isAscending) {
        return new OrderImpl(field, isAscending ? SortOrder.ASCENDING : SortOrder.DESCENDING, joinField);
    }

    public static QueryV1.Order order(final QueryV1.AggregatedField aggregate, final Boolean isAscending) {
        return new OrderImpl(aggregate, isAscending ? SortOrder.ASCENDING : SortOrder.DESCENDING);
   }

    private with sharing class AggregatedFieldImpl implements QueryV1.AggregatedField {
        private final String field;
        private final String alias;
        private final OptionalV1 function;

        private AggregatedFieldImpl(final OptionalV1 joinField, final SObjectField field, final OptionalV1 function, final String alias) {
            if (function.isPresent() && !(function.get() instanceof String)) {
                throw new QueryException('Function must be a String');
            }

            if (joinField.isPresent() && !(joinField.get() instanceof SObjectField)) {
                throw new QueryException('Join field must be an SObjectField');
            }

            if (joinField.isPresent()) {
                final Set<String> joined = QueryHelper.buildJoinFields((SObjectField) joinField.get(), new Set<SObjectField>{ field });
                this.field = joined.iterator().next();
                this.alias = alias;
                this.function = function;
            } else {
                this.field = field.getDescribe().name;
                this.alias = alias;
                this.function = function;
            }
        }

        public String toOrderString() {
            if (function.isPresent()) {
                return ArrayV1.over(new List<String>{ (String) function.get(), '(', field, ')' } ).join('');
            } else {
                return field;
            }
        }

        public override String toString() {
            if (function.isPresent()) {
                return ArrayV1.over(new List<String>{(String) function.get(), '(', field, ') ', alias }).join('');
            } else {
                return ArrayV1.over(new List<String>{ field, ' ', alias }).join('');
            }
        }
    }

    private with sharing class OrderImpl implements QueryV1.Order {
        private final String field;
        private final SortOrder order;
        private OptionalV1 nullsFirst = OptionalV1.empty();

        public OrderImpl(final SObjectField field, final SortOrder order, final OptionalV1 joinField) {
            if (joinField.isPresent()) {
                if (! (joinField.get() instanceof SObjectField)) {
                    throw new QueryException('Join field must be an SObjectField');
                }

                this.field =
                        QueryHelper.buildJoinFields((SObjectField) joinField.get(), new Set<SObjectField> { field })
                                .iterator().next();
            } else {
                this.field = field.getDescribe().name;
            }
            this.order = order;
        }

        public OrderImpl(final QueryV1.AggregatedField aggregatedField, final SortOrder order) {
            this.field = ((AggregatedFieldImpl) aggregatedField).toOrderString();
            this.order = order;
        }

        public String getField() {
            return field;
        }

        public Boolean isAscending() {
            return order == SortOrder.ASCENDING;
        }

        public OptionalV1 isNullsFirst() {
            return nullsFirst;
        }

        public QueryV1.Order nullsFirst() {
            nullsFirst = OptionalV1.of(true);
            return (QueryV1.Order) this;
        }

        public QueryV1.Order nullsLast() {
            nullsFirst = OptionalV1.of(false);
            return (QueryV1.Order) this;
        }

        public override String toString() {
            if (nullsFirst.isPresent()) {
                return (Boolean) nullsFirst.get()
                        ? order == SortOrder.ASCENDING ? field + ' ASC NULLS FIRST' : field + ' DESC NULLS FIRST'
                        : order == SortOrder.ASCENDING ? field + ' ASC NULLS LAST' : field + ' DESC NULLS LAST';
            } else {
                return order == SortOrder.ASCENDING ? field + ' ASC' : field + ' DESC';
            }
        }
    }

    private with sharing class GetRelationshipName extends ArrayV1.Callback {
        public override OptionalV1 function(final Object element, final OptionalV1 currentValue, final Integer index) {
            final ChildRelationship relationship = (ChildRelationship) element;

            if (relationship.childSObject == (SObjectType) shared().get()) {
                ((List<String>) currentValue.get()).add(relationship.getRelationshipName());
            }

            return currentValue;
        }
    }

    private with sharing class FieldToString extends ArrayV1.Callback {
        public override OptionalV1 function(final Object element, final OptionalV1 currentValue, final Integer index) {
            ((Set<String>) currentValue.get()).add(((SObjectField) element).getDescribe().name);
            return currentValue;
        }
    }

    private with sharing class AddRelationship extends ArrayV1.Callback {
        public override OptionalV1 function(final Object element, final OptionalV1 currentValue, final Integer index) {
            ((Set<String>) currentValue.get()).add(((Implementation) shared().get()).buildInnerQuery((String) element));
            return currentValue;
        }
    }

    // Set the default implementation of API. This can be overridden using a Dependency Injection Binding.
    static {
        DependencyV1.bind(QueryV1.API.class, Factory.class);
    }
}