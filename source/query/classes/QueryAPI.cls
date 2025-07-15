/**
 * @description
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../../LICENSE target="_blank">MIT License</a>.
 * <br><br>
 * Class providing the default implementation of the Query API.
 * <br><br>
 * All application access is restricted to the API instance variable API. This ensures the application can only
 * ever call the methods of the API interface.
 * <br><br>
 * The outer class implements the API only to allow it to be mocked. Any calls to the API method implementations
 * in the outer class will throw an Exception.
 * <br><br>
 * See <a href=../README.md target="_blank">README</a> for full details of the Query API.
 *
 * @author Mark Brennand
 */
public with sharing virtual class QueryAPI implements QueryV1.API {

    final static Map<String, Map<String, List<String>>> CHILD_RELATIONSHIPS = new Map<String, Map<String, List<String>>>();

    /**
     * @description
     * Active API instance.
     * <br><br>
     * The instance is injected from the Registry.
     * <br><br>
     * The instance is test visible so it can be mocked.
     * <br><br>
     * Any implementation must be of type DependencyV1.Prototype as state must be maintained.
     */
    @TestVisible
    public static QueryV1.API API {
        public get {
            if (Test.isRunningTest() && API != null) { // API has been mocked.
                return API;
            } else {
                return (QueryV1.API) DependencyV1.inject(QueryV1.API.class);
            }
        }
        private set;
    }

    private enum SortOrder { ASCENDING, DESCENDING }

    protected QueryAPI() {}

    private with sharing class Implementation implements QueryV1.API, DependencyV1.Prototype {
        private SObjectType type;
        private AccessLevel security = AccessLevel.USER_MODE;
        private Set<String> returning = new Set<String> { 'Id' };
        private List<Set<String>> joins = new List<Set<String>>();
        private Optional aggregates = Optional.empty();
        private Optional groupBy = Optional.empty();
        private Optional condition = Optional.empty();
        private final List<String> ordering = new List<String>();
        private Optional max = Optional.empty();
        private Optional offset = Optional.empty();
        private final Map<String, QueryV1.API> children = new Map<String, QueryV1.API>();
        private Boolean isCount = false;

        public SObjectType type() {
            Assert.isNotNull(this.type, 'Query type has not been set');
            return type;
        }

        public QueryV1.API type(SObjectType type) {
            Assert.isNull(this.type, 'Query type cannot be changed');
            this.type = type;
            return this;
        }

        public QueryV1.API security(final AccessLevel security) {
            this.security = security;
            return this;
        }

        public QueryV1.API returning(final Set<SObjectField> fields) {
            throwExceptionIfCountQuery();
            throwExceptionIfAggregatedQuery();
            this.returning.addAll((Set<String>) ArrayV1.over(new List<SObjectField>(fields))
                    .reduce(new BuildReturning(), new Set<String>()));
            return this;
        }

        public QueryV1.API returning(final SObjectField joinField, final Set<SObjectField> fields) {
            throwExceptionIfCountQuery();
            throwExceptionIfAggregatedQuery();
            this.joins = (List<Set<String>>) ArrayV1.over(this.joins).concat(
                    new List<Set<String>> { QueryHelper.buildJoinFields(joinField, fields) }
            );
            return this;
        }

        public QueryV1.API returning(Set<QueryV1.AggregatedField> fields) {
            throwExceptionIfCountQuery();
            throwExceptionIfRegularQuery();
            aggregates = Optional.of(ArrayV1.over(new List<QueryV1.AggregatedField>(fields)).reduce(new AggregateToString(), new List<String>()));
            return this;
        }

        public QueryV1.API count() {
            isCount = true;
            return this;
        }

        public QueryV1.API matching(final String condition) {
            this.condition = Optional.ofNullable(condition);
            return this;
        }

        public QueryV1.API ascending(final SObjectField field) {
            throwExceptionIfCountQuery();
            this.ordering.add(new Order(field, SortOrder.ASCENDING, Optional.empty()).toString());
            return this;
        }

        public QueryV1.API descending(final SObjectField field) {
            throwExceptionIfCountQuery();
            this.ordering.add(new Order(field, SortOrder.DESCENDING, Optional.empty()).toString());
            return this;
        }

        public QueryV1.API ascending(final SObjectField field, final Boolean nullsFirst) {
            throwExceptionIfCountQuery();
            this.ordering.add(new Order(field, SortOrder.ASCENDING, Optional.of(nullsFirst)).toString());
            return this;
        }

        public QueryV1.API descending(final SObjectField field, final Boolean nullsFirst) {
            throwExceptionIfCountQuery();
            this.ordering.add(new Order(field, SortOrder.DESCENDING, Optional.of(nullsFirst)).toString());
            return this;
        }

        public QueryV1.API aggregated(Set<SObjectField> fields) {
            throwExceptionIfCountQuery();
            throwExceptionIfRegularQuery();
            groupBy = Optional.of(ArrayV1.over(new List<SObjectField>(fields)).reduce(new FieldToString(), new List<String>()));
            return this;
        }

        public QueryV1.API children(QueryV1.API query) {
            throwExceptionIfCountQuery();
            for (String relationshipName : getChildRelationshipsNames(query.type())) {
                children.put(relationshipName, query);
            }
            return this;
        }

        public QueryV1.API max(final Optional max) {
            if (max.isPresent()) {
                if (! (max.get() instanceof Integer)) {
                    throw new QueryException('Maximum rows to return must be an Integer');
                }
                this.max = Optional.of(' LIMIT ' + max.get());
            } else {
                this.max = max;
            }

            return this;
        }

        public QueryV1.API offset(final Optional offset) {
            if (offset.isPresent()) {
                if (! (offset.get() instanceof Integer)) {
                    throw new QueryException('Offset must be an Integer');
                }
                this.offset = Optional.of(' OFFSET ' + offset.get());
            } else {
                this.offset = offset;
            }

            return this;
        }

        public Optional execute(Optional bindVars) {
            final String query = buildOuterQuery();

            if (isCount) {
                if (bindVars.isPresent()) {
                    return Optional.of(Database.countQueryWithBinds(query, (Map<String, Object>) bindVars.get(), security));
                } else {
                    return Optional.of(Database.countQuery(query, security));
                }
            } else {
                final List<SObject> matches;
                if (bindVars.isPresent()) {
                    matches = Database.queryWithBinds(query, (Map<String, Object>) bindVars.get(), security);
                } else {
                    matches = Database.query(query, security);
                }

                return matches.isEmpty() ? Optional.empty() : Optional.of(matches);
            }
        }

        private String buildOuterQuery() {
            final List<String> additionalFields = new List<String>();
            additionalFields.addAll(joins.isEmpty()
                    ? new List<String>()
                    : (List<String>) ArrayV1.over(joins).reduce(new AllJoins(), new List<String>()));

            for (String relationshipName : children.keySet()) {
                additionalFields.add(((Implementation) children.get(relationshipName)).buildInnerQuery(relationshipName));
            }

            Optional order = ordering.isEmpty()
                    ? Optional.empty()
                    : Optional.of(' ORDER BY ' + ArrayV1.over(this.ordering).join(','));

            return ArrayV1.over(
                    new List<String> {
                            'SELECT ',
                            isCount ? 'COUNT()' : aggregates.isPresent()
                                    ? ''
                                    : ArrayV1.over(ArrayV1.over(new List<String>(this.returning)).concat(additionalFields)).join(','),
                            aggregates.isPresent() ? ArrayV1.over((List<String>) aggregates .get()).join(',') : '',
                            ' FROM ',
                            type.getDescribe().name,
                            condition.isPresent() ? ' WHERE ' : '',
                            condition.isPresent() ? (String) condition.get() : '',
                            groupBy.isPresent() ? ' GROUP BY ' + ArrayV1.over((List<String>) groupBy.get()).join(',') : '',
                            order.isPresent() ? (String) order.get() : '',
                            max.isPresent() ? (String) max.get() : '',
                            offset.isPresent() ? (String) offset.get() : ''
                    }
            ).join('');
        }

        private String buildInnerQuery(final String relationshipName) {
            final List<String> allJoins = joins.isEmpty()
                    ? new List<String>()
                    : (List<String>) ArrayV1.over(joins).reduce(new AllJoins(), new List<String>());

            Optional order = ordering.isEmpty()
                    ? Optional.empty()
                    : Optional.of(' ORDER BY ' + ArrayV1.over(this.ordering).join(','));

            return ArrayV1.over(
                    new List<String> {
                            '(SELECT ',
                            ArrayV1.over(ArrayV1.over(new List<String>(this.returning)).concat(allJoins)).join(','),
                            ' FROM ',
                            relationshipName,
                            condition.isPresent() ? ' WHERE ' : '',
                            condition.isPresent() ? (String) condition.get() : '',
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
            if (returning.size() > 1 || !joins.isEmpty()) {
                throw new QueryException('Operation may not be performed on a regular query');
            }
        }

        private List<String> getChildRelationshipsNames(final SObjectType childType) {
            final List<String> relationships =  (List<String>) ArrayV1.over(type.getDescribe().getChildRelationships())
                    .sharing(childType)
                    .reduce(new GetRelationshipName(), new List<String>());

            if (relationships.isEmpty()) {
                throw new QueryException('No relationship found to object ' + childType.getDescribe().name);
            }

            return relationships;
        }
    }

    /**
     * @description
     * Creates the default API implementation.
     * <br><br>
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
     * Class providing check on Binding made to AsynchronousAPI.API.
     */
    public with sharing class BindingCheck implements DependencyV1.BindingCheck {

        /**
         * @description
         * Checks that a valid binding has been made to QueryAPI.API.
         *
         * @param forType The type being bound to, QueryAPI.API.
         * @param withImpl The implementation being bound to QueryAPI.API.
         *
         * @return The result of the validation.
         */
        public DependencyV1.ValidationResult validate(final Type forType, final Type withImpl) {
            return DependencyHelper.buildValidationResult(
                    TypesV1.newInstance(withImpl) instanceof QueryV1.API,
                    true,
                    forType,
                    withImpl
            );
        }
    }

    private with sharing class BuildReturning extends ArrayV1.Callback {
        public override Optional function(final Object element, final Optional currentValue, final Integer index) {
            ((Set<String>) currentValue.get()).add(((SObjectField) element).getDescribe().name);
            return currentValue;
        }
    }

    private with sharing class AllJoins extends ArrayV1.Callback {
        public override Optional function(final Object element, final Optional currentValue, final Integer index) {
            ((List<String>) currentValue.get()).addAll((Set<String>) element);
            return currentValue;
        }
    }

    private with sharing class GetRelationshipName extends ArrayV1.Callback {
        public override Optional function(final Object element, final Optional currentValue, final Integer index) {
            final ChildRelationship relationship = (ChildRelationship) element;

            if (relationship.childSObject == (SObjectType) shared().get()) {
                ((List<String>) currentValue.get()).add(relationship.getRelationshipName());
            }

            return currentValue;
        }
    }

    private with sharing class FieldToString extends ArrayV1.Callback {
        public override Optional function(final Object element, final Optional currentValue, final Integer index) {
            ((List<String>) currentValue.get()).add(((SObjectField) element).getDescribe().name);
            return currentValue;
        }
    }

    private with sharing class AggregateToString extends ArrayV1.Callback {
        public override Optional function(final Object element, final Optional currentValue, final Integer index) {
            ((List<String>) currentValue.get()).add(((QueryV1.AggregatedField) element).toString());
            return currentValue;
        }
    }

    private with sharing class Order {
        private final SObjectField field;
        private final SortOrder order;
        private final Optional nullsFirst;

        public Order(final SObjectField field, final SortOrder order, final Optional nullsFirst) {
            this.field = field;
            this.order = order;
            this.nullsFirst = nullsFirst;
        }

        public override String toString() {
            if (nullsFirst.isPresent()) {
                return (Boolean) nullsFirst.get()
                        ? order == SortOrder.ASCENDING
                                ? field.getDescribe().name + ' ASC NULLS FIRST'
                                : field.getDescribe().name + ' DESC NULLS FIRST'
                        : order == SortOrder.ASCENDING
                                ? field.getDescribe().name + ' ASC NULLS LAST'
                                : field.getDescribe().name + ' DESC NULLS LAST';
            } else {
                return order == SortOrder.ASCENDING
                        ? field.getDescribe().name + ' ASC'
                        : field.getDescribe().name + ' DESC';
            }
        }
    }

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

    public QueryV1.API returning(final SObjectField linkField, final Set<SObjectField> fields) {
        throw new QueryException('Access denied');
    }

    public QueryV1.API returning(final Set<SObjectField> fields) {
        throw new QueryException('Access denied');
    }

    public QueryV1.API returning(Set<QueryV1.AggregatedField> fields) {
        throw new QueryException('Access denied');
    }

    public QueryV1.API matching(final String condition) {
        throw new QueryException('Access denied');
    }

    public QueryV1.API ascending(final SObjectField field) {
        throw new QueryException('Access denied');
    }

    public QueryV1.API descending(final SObjectField field) {
        throw new QueryException('Access denied');
    }

    public QueryV1.API ascending(final SObjectField field, final Boolean nullsFirst) {
        throw new QueryException('Access denied');
    }

    public QueryV1.API descending(final SObjectField field, final Boolean nullsFirst) {
        throw new QueryException('Access denied');
    }

    public QueryV1.API aggregated(final Set<SObjectField> fields) {
        throw new QueryException('Access denied');
    }

    public QueryV1.API children(final QueryV1.API query) {
        throw new QueryException('Access denied');
    }

    public Optional execute(final Optional bindVars) {
        throw new QueryException('Access denied');
    }

    public QueryV1.API max(Optional max) {
        throw new QueryException('Access denied');
    }

    public QueryV1.API offset(Optional offset) {
        throw new QueryException('Access denied');
    }

    // Set the default implementation of API. This can be overridden using a Dependency Injection Binding.
    static {
        DependencyV1.bind(QueryV1.API.class, Factory.class);
    }
}