/**
 * @description
 * <p>
 * Class providing the default implementation of the Query API.
 * <p>
 * All application access is restricted to the API instance variable API. This ensures the application can only
 * ever call the methods of the API interface.
 * <p>
 * The outer class implements the API only to allow it to be mocked. Any calls to the API method implementations
 * in the outer class will throw an Exception.
 * <p>
 * See <a href=../README.md target="_blank">README</a> for full details of the Query API.
 * <p>
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../LICENSE target="_blank">MIT License</a>.
 *
 * @author Mark Brennand
 */
@SuppressWarnings('PMD.ApexDoc')
public with sharing virtual class QueryAPI extends QueryAPIMockable {

    /**
     * @description
     * <p>
     * Active API instance.
     * <p>
     * The instance is injected from the Registry. As the instance maintains state between calls, a new instance
     * must be injected each time it is requested.
     * <p>
     * The instance is test visible so it can be mocked.
     * <p>
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
     * <p>
     * Allow extension but not construction.
     * <p>
     * This is also required to support the Apex mocking classes. A private constructor cannot be mocked.
     */
    @SuppressWarnings('PMD.EmptyStatementBlock')
    protected QueryAPI() {}

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

    // Set the default implementation of API. This can be overridden using a Dependency Injection Binding.
    static {
        DependencyV1.bind(QueryV1.API.class, QueryImpl.Factory.class);
    }
}