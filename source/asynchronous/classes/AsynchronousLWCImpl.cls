/**
 * @description
 * <p>
 * Implementation of Asynchronous LWC.
 * <p>
 * Implementation class is private to prevent re-use.
 * <p>
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../LICENSE target="_blank">MIT License</a>.
 * 
 * @author Mark Brennand
 */
public with sharing class AsynchronousLWCImpl {

    private final static String STATUS_ALIAS = 'Status__c';
    private final static String COUNT_ALIAS = 'Count__c';

    /**
     * @description
     * <p>
     * Class providing the implementation of the LWC.
     */
    private with sharing class API implements AsynchronousLWC.API {

        /**
         * @description
         * <p>
         * Returns a List of the AsynchronousJob__c objects matching the filter criteria.
         *
         * @param filters Query filters to be applied.
         * @param ordering The ordering to apply to the results.
         * @param offset The record to return results from.
         * @param max  The maximum number of records to return.
         *
         * @return A list of the matching objects.
         */
        public List<Map<String, Object>> getJobs(
                final Map<String, Object> filters,
                final String ordering,
                final Integer offset,
                final Integer max
        ) {
            final QueryV1.API query = QueryV1.of(AsynchronousJob__c.SObjectType)
                    .security(AccessLevel.USER_MODE)
                    .returning(AsynchronousJob__c.ApexJobId__c)
                    .returning(AsynchronousJob__c.Name)
                    .returning(AsynchronousJob__c.Reference__c)
                    .returning(AsynchronousJob__c.Status__c)
                    .returning(AsynchronousJob__c.RetryNumber__c)
                    .returning(AsynchronousJob__c.MaximumRetries__c)
                    .returning(AsynchronousJob__c.Runnable__c)
                    .returning(AsynchronousJob__c.ScheduledRunTime__c)
                    .returning(AsynchronousJob__c.LastRunTime__c)
                    .returning(AsynchronousJob__c.OwnerId, new Set<SObjectField> { User.Name })
                    .matching(buildQuery(filters))
                    .max(max)
                    .offset(offset);

            final String[] parts = ordering.split(' ');
            if (parts.size() != 2) {
                throw new AsynchronousV1.APIException('Invalid order by');
            }

            final Map<String, SObjectField> fields =
                    AsynchronousJob__c.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).fields.getMap();

            final SObjectField orderField = fields.get(CommonHelper.getSObjectNamespace() + parts[0]);

            final OptionalV1 matches;
            if (parts[1].toLowerCase() == 'asc') {
                matches = query.ordered(QueryV1.ascending(orderField)).execute();
            } else {
                matches = query.ordered(QueryV1.descending(orderField)).execute();
            }

            return (List<Map<String, Object>>) matches.then(new JobMatchProcessor()).get();
        }

        /**
         * @description
         * <p>
         * Deletes the given AsynchronousJob__c records.
         *
         * @param jobIds The ids of the jobs to delete.
         */
        public void deleteJobs(final List<Id> jobIds) {
            QueryV1.of(AsynchronousJob__c.SObjectType)
                    .security(AccessLevel.USER_MODE)
                    .returning(AsynchronousJob__c.Id)
                    .matching('Id IN :jobIds')
                    .bindings(new Map<String, Object> { 'jobIds' => jobIds })
                    .execute()
                    .then(new CommonHelper.ToList(new List<SObject>()))
                    .then(new SObjectHelper.Deleter(AccessLevel.USER_MODE));
        }

        /**
         * @description
         * <p>
         * Re-runs the given AsynchronousJob__c records.
         *
         * @param jobIds The ids of the jobs to re-run.
         */
        public void runJobs(final List<Id> jobIds) {
            QueryV1.of(AsynchronousJob__c.SObjectType)
                    .security(AccessLevel.USER_MODE)
                    .returning(AsynchronousJob__c.Id)
                    .matching('Id IN :jobIds AND Runnable__c != :schedulerClassName')
                    .bindings(new Map<String, Object> {
                            'jobIds' => jobIds,
                            'schedulerClassName' => AsynchronousScheduler.RunNextAvailable.class.getName()
                    })
                    .execute()
                    .then(new SObjectHelper.Transformer(new RequeueJob(), AccessLevel.USER_MODE));
        }

        /**
         * @description
         * <p>
         * Calculates the total number of objects per status for the current user.
         *
         * @return The totals.
         */
        public Map<String, Integer> getTotals() {
            final Map<String, Integer> returnMap = new Map<String, Integer>();
            for (AsynchronousV1.Status status : AsynchronousV1.Status.values()) {
                returnMap.put(status.name(), 0);
            }

            returnMap.putAll((Map<String, Integer>) QueryV1.of(AsynchronousJob__c.SObjectType)
                    .security(AccessLevel.USER_MODE)
                    .returning(QueryV1.aggregatedField(AsynchronousJob__c.Status__c, STATUS_ALIAS))
                    .returning(QueryV1.aggregatedField('COUNT', AsynchronousJob__c.Id, COUNT_ALIAS))
                    .group(new Set<SObjectField> { AsynchronousJob__c.Status__c })
                    .execute()
                    .then(new TotalsTransformer())
                    .get()
            );

            return returnMap;
        }

        /**
         * @description
         * <p>
         * Converts the filters argument from the LWC to a WHERE clause.
         *
         * @param filters The query filters.
         *
         * @return The WHERE clause for the query.
         */
        private String buildQuery(final Map<String, Object> filters) {
            if (filters == null || filters.isEmpty()) {
                return 'Id != null';
            }

            final List<String> clauses = new List<String>();
            for (String field : filters.keySet()) {
                final Object value = filters.get(field);
                Boolean hasValue = false;

                if (value instanceof List<Object>) {
                    final String values = buildInValue((List<Object>) value);
                    hasValue = !String.isEmpty(values);
                    clauses.add(field + ' IN(' + values +')');

                } else if (value instanceof String) {
                    clauses.add(field + ' LIKE ' + '\'' + String.escapeSingleQuotes((String) value) + '\'');
                    hasValue = true;

                } else {
                    clauses.add(field + '=' + filters.get(field));
                    hasValue = true;
                }

                if (!hasValue) {
                    // The query filter returns no matches.
                    return 'Id = null';
                }
            }

            return String.join(clauses, ' AND ');
        }

        private String buildInValue(final List<Object> value) {
            String values = '';
            Boolean first = true;
            for (Object option : value) {
                if (!first) {
                    values += ',';
                }

                if (option instanceof String) {
                    values += '\'' + String.escapeSingleQuotes((String) option) + '\'';
                } else {
                    values += option;
                }

                first = false;
            }

            return values;
        }
    }

    /**
     * @description
     * <p>
     * Callback class to re-queue a job.
     */
    private with sharing class RequeueJob extends ArrayV1.Callback {
        private final Datetime now = CommonHelper.now();

        public override OptionalV1 function(final Object element, final OptionalV1 currentValue, final Integer index) {
            final AsynchronousJob__c job = (AsynchronousJob__c) element;
            job.Status__c = AsynchronousV1.Status.PENDING.name();
            job.ScheduledRunTime__c = now;
            return OptionalV1.of(job);
        }
    }

    /**
     * @description
     * <p>
     * Callback class to build totals for Job status.
     */
    private with sharing class BuildTotals extends ArrayV1.Callback {
        public override OptionalV1 function(final Object element, final OptionalV1 currentValue, final Integer index) {
            final AggregateResult result = (AggregateResult) element;
            ((Map<String, Integer>) currentValue.get()).put((String) result.get(STATUS_ALIAS), (Integer) result.get(COUNT_ALIAS));
            return currentValue;
        }
    }

    /**
     * @description
     * <p>
     * Callback class to build the Map representing a job and add it to the List to return.
     */
    private with sharing class ResultBuilder extends ArrayV1.Callback {
        final Datetime now = CommonHelper.now();

        public override OptionalV1 function(final Object element, final OptionalV1 currentValue, final Integer index) {
            final AsynchronousJob__c match = (AsynchronousJob__c) element;
            final Map<String, Object> fields = match.getPopulatedFieldsAsMap();
            Map<String, Object> returnObject = new Map<String, Object>();

            for (String field : fields.keySet()) {
                final String stripped = field.replace(CommonHelper.getSObjectNamespace(), '');
                returnObject.put(stripped, fields.get(field));
            }

            final String apexJobId = (String) returnObject.get('ApexJobId__c');
            if ((apexJobId ?? '').length() > 15) {
                returnObject.put('ApexJobId__c', apexJobId.substring(0, 15));
            }
            returnObject.put('Owner', match.Owner.Name);

            if (match.Status__c == AsynchronousV1.Status.RUNNING.name()) {
                returnObject.put('RunTime__c', now.getTime() - match.LastRunTime__c.getTime());
            }

            returnObject.put('RetriesRemaining__c', match.MaximumRetries__c - match.RetryNumber__c);

            ((List<Map<String, Object>>) currentValue.get()).add(returnObject);
            return currentValue;
        }
    }

    /**
     * @description
     * <p>
     * Transformer class to build the List of jobs from the matches.
     */
    private with sharing class JobMatchProcessor implements OptionalV1.Function {

        /**
         * @description
         * <p>
         * Converts each matching job to a Map.
         *
         * @param value The matching jobs.
         *
         * @return The jobs converted to a list of Maps.
         */
        public OptionalV1 apply(final OptionalV1 value) {
            if (!value.isPresent()) {
                return OptionalV1.of(new List<Map<String, Object>>());
            }

            return OptionalV1.of(ArrayV1.over(value.get()).reduce(
                    new ResultBuilder(),
                    new List<Map<String, Object>>())
            );
        }
    }

    /**
     * @description
     * <p>
     * Transformer to build Map of Status counts from the List of aggregate results.
     */
    private with sharing class TotalsTransformer implements OptionalV1.Function {

        /**
         * @description
         * <p>
         * Converts the given totals to a Map which is keyed by the status name.
         *
         * @param value The total for each status.
         *
         * @return A Map keyed by the status name with the value recording the total.
         */
        public OptionalV1 apply(final OptionalV1 value) {
            if (!value.isPresent()) {
                return OptionalV1.of(new Map<String, Integer>());
            }

            return OptionalV1.of(ArrayV1.over(value.get()).reduce(
                    new BuildTotals(),
                    new Map<String, Integer>())
            );
        }
    }


    /**
     * @description
     * <p>
     * Creates the default LWC API implementation.
     * <p>
     * The constructor for the implementation is protected. This prevents the Dependency framework constructing it.
     * We use the factory to defer the construction by injection to this class, which is able to construct it.
     */
    public with sharing class Factory implements TypesV1.Factory {

        @SuppressWarnings('PMD.ApexDoc')
        public Object newInstance() {
            return new API();
        }
    }
}