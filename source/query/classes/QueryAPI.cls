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

    /**
     * @description
     * <p>
     * Sort direction for ORDER BY clauses.
     * <p>
     * ASCENDING renders as "ASC" and DESCENDING renders as "DESC" in the generated SOQL.
     * Used internally by OrderImpl to control ordering and NULLS FIRST/LAST handling.
     */
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

    /**
     * @description
     * <p>
     * Factory for creating an AggregatedField used in SELECT clauses and ORDER BY expressions.
     * Supports optional relationship traversal (joinField) and an aggregate function applied to the base field.
     * When joinField is provided, the method resolves the full relationship path for the field.
     *
     * @param function   Optional aggregate function name (e.g., 'SUM', 'COUNT', 'AVG'). Must be a String if present.
     * @param joinField  Optional relationship field to traverse from the root object. Must be an SObjectField if present.
     * @param field      The target SObjectField to aggregate.
     * @param alias      Alias to use for the aggregated field in the SELECT list.
     *
     * @return QueryV1.AggregatedField representing the aggregate expression, suitable for SELECT and ORDER BY.
     */
    @SuppressWarnings('PMD.ExcessiveParameterList')
    public static QueryV1.AggregatedField aggregatedField(final OptionalV1 function, final OptionalV1 joinField, final SObjectField field, final String alias) {
        return new AggregatedFieldImpl(joinField, field, function, alias);
    }

    /**
     * @description
     * <p>
     * Builds an ORDER BY clause element for a base SObject field with optional relationship traversal.
     * Handles direction (ASC/DESC) and defers NULLS FIRST/LAST configuration to returned instance methods.
     *
     * @param joinField   Optional relationship field to traverse from the root object. Must be an SObjectField if present.
     * @param field       The SObjectField to order by.
     * @param isAscending True for ascending (ASC), false for descending (DESC).
     *
     * @return QueryV1.Order that can render an ORDER BY fragment and be further configured for NULLS FIRST/LAST.
     */
    public static QueryV1.Order order(final OptionalV1 joinField, final SObjectField field, final Boolean isAscending) {
        return new OrderImpl(field, isAscending ? SortOrder.ASCENDING : SortOrder.DESCENDING, joinField);
    }

    /**
     * @description
     * <p>
     * Builds an ORDER BY clause element for an aggregated field (e.g., SUM(Amount)).
     * Leverages the aggregated field rendering for proper ORDER BY expression output and sets sort direction.
     *
     * @param aggregate   The previously constructed aggregated field to order by.
     * @param isAscending True for ascending (ASC), false for descending (DESC).
     *
     * @return QueryV1.Order that can render an ORDER BY fragment on an aggregate and be configured for NULLS FIRST/LAST.
     */
    public static QueryV1.Order order(final QueryV1.AggregatedField aggregate, final Boolean isAscending) {
        return new OrderImpl(aggregate, isAscending ? SortOrder.ASCENDING : SortOrder.DESCENDING);
   }

    /**
     * @description
     * <p>
     * Implementation of an aggregated field capable of rendering both SELECT alias and ORDER BY forms.
     * Validates optional inputs and resolves relationship paths when a join field is provided.
     */
    private with sharing class AggregatedFieldImpl implements QueryV1.AggregatedField {
        private final String field;
        private final String alias;
        private final OptionalV1 function;

        /**
         * @description
         * <p>
         * Constructs an aggregated field with optional relationship traversal and function.
         * Ensures provided optionals contain correct types and resolves join paths as needed.
         *
         * @param joinField Optional relationship SObjectField to traverse from root object.
         * @param field     Base SObjectField being aggregated.
         * @param function  Optional aggregate function name as String (e.g., 'SUM').
         * @param alias     Alias for the SELECT list.
         */
        @SuppressWarnings('PMD.ExcessiveParameterList')
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

        /**
         * @description
         * <p>
         * Renders the aggregated field for ORDER BY usage.
         * If a function is present, outputs FUNCTION(field); otherwise returns the field path/name.
         *
         * @return String ORDER BY-safe expression.
         */
        public String toOrderString() {
            if (function.isPresent()) {
                return ArrayV1.over(new List<String>{ (String) function.get(), '(', field, ')' } ).join('');
            } else {
                return field;
            }
        }

        /**
         * @description
         * <p>
         * Renders the aggregated field for SELECT usage including alias.
         * If a function is present, outputs "FUNCTION(field) alias"; otherwise "field alias".
         *
         * @return String SELECT expression with alias.
         */
        public override String toString() {
            if (function.isPresent()) {
                return ArrayV1.over(new List<String>{(String) function.get(), '(', field, ') ', alias }).join('');
            } else {
                return ArrayV1.over(new List<String>{ field, ' ', alias }).join('');
            }
        }
    }

    /**
     * @description
     * <p>
     * Implementation of ORDER BY element supporting base and aggregated fields,
     * direction (ASC/DESC), and optional NULLS FIRST/LAST hints.
     */
    private with sharing class OrderImpl implements QueryV1.Order {
        private final String field;
        private final SortOrder order;
        private OptionalV1 nullsFirst = OptionalV1.empty();

        /**
         * @description
         * <p>
         * Constructs an Order for a base SObject field with optional relationship traversal.
         * Validates joinField type and resolves relationship path when provided.
         *
         * @param field     The SObjectField to order by.
         * @param order     Internal sort direction (ASCENDING/DESCENDING).
         * @param joinField Optional relationship SObjectField to traverse from root object.
         *
         * @throws QueryException if joinField is present and not an SObjectField.
         */
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

        /**
         * @description
         * <p>
         * Constructs an Order for an aggregated field.
         * Uses the aggregated field's ORDER BY-safe rendering.
         *
         * @param aggregatedField Aggregated field to order by.
         * @param order           Internal sort direction (ASCENDING/DESCENDING).
         */
        public OrderImpl(final QueryV1.AggregatedField aggregatedField, final SortOrder order) {
            this.field = ((AggregatedFieldImpl) aggregatedField).toOrderString();
            this.order = order;
        }

        /**
          * @description
         * <p>
          * Returns the rendered field or aggregate expression used for ordering.
          *
          * @return String field path/name or aggregate expression.
          */
        public String getField() {
            return field;
        }

        /**
         * @description
         * <p>
         * Indicates whether the sort direction is ascending.
         *
         * @return True if ascending; otherwise, false.
         */
        public Boolean isAscending() {
            return order == SortOrder.ASCENDING;
        }

        /**
         * @description
         * <p>
         * Returns the configured NULLS FIRST/LAST state, if any.
         *
         * @return OptionalV1 of Boolean true for NULLS FIRST, false for NULLS LAST, or empty if not set.
         */
        public OptionalV1 isNullsFirst() {
            return nullsFirst;
        }

        /**
         * @description
         * <p>
         * Configures the ORDER BY to render with NULLS FIRST.
         *
         * @return QueryV1.Order for chaining.
         */
        public QueryV1.Order nullsFirst() {
            nullsFirst = OptionalV1.of(true);
            return (QueryV1.Order) this;
        }

        /**
         * @description
         * <p>
         * Configures the ORDER BY to render with NULLS LAST.
         *
         * @return QueryV1.Order for chaining.
         */
        public QueryV1.Order nullsLast() {
            nullsFirst = OptionalV1.of(false);
            return (QueryV1.Order) this;
        }

        /**
         * @description
         * <p>
         * Renders the ORDER BY fragment including direction and optional NULLS FIRST/LAST clause.
         *
         * @return String ORDER BY fragment (e.g., "Amount ASC NULLS LAST").
         */
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
}