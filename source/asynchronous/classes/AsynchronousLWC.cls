/**
 * @description
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../../LICENSE target="_blank">MIT License</a>.
 * <br><br>
 * Class providing the default implementation of the Asynchronous LWC API.
 * <br><br>
 * The implementation of the API is hidden in the private Implementation class. The class is hidden so an application
 * cannot access the class to mis-use it.
 * <br><br>
 * All application access is restricted to the API instance variable API. This ensures the application can only
 * ever call the methods of the API interface.
 * <br><br>
 * The outer class implements the API only to allow it to be mocked. Any calls to the API method implementations
 * in the outer class will throw an Exception.
 *
 * @author Mark Brennand
 */
public with sharing virtual class AsynchronousLWC implements API {

    /**
     * Interface defining the calls that may be made from the Asynchronous Job LWC.
     */
    public interface API {

        /**
         * @description
         * Returns a List of the AsynchronousJob__c objects matching the filter criteria.
         *
         * @param filters Query filters to be applied.
         * @param ordering The ordering to apply to the results.
         * @param offset The record to return results from.
         * @param max  The maximum number of records to return.
         *
         * @return A list of the matching objects.
         */
        List<Map<String, Object>> getJobs(final Map<String, Object> filters, final String ordering, final Integer offset, final Integer max);

        /**
         * @description
         * Deletes the given AsynchronousJob__c records.
         *
         * @param jobIds The ids of the jobs to delete.
         */
        void deleteJobs(final List<Id> jobIds);

        /**
         * @description
         * Re-runs the given AsynchronousJob__c records.
         *
         * @param jobIds The ids of the jobs to re-run.
         */
        void runJobs(final List<Id> jobIds);

        /**
         * @description
         * Calculates the total number of objects per status for the current user.
         *
         * @return The totals.
         */
        Map<String, Integer> getTotals();
    }

    /**
     * @description
     * Active LWC instance.
     * <br><br>
     * The instance is injected from the Registry. As the instance is injected, a development version of the
     * interface could be used to provide data to the LWC during development. This would allow the LWC to be
     * developed in isolation from the real implementation being developed.
     * <br><br>
     * The instance is test visible so it can be mocked.
     */
    @TestVisible
    public static API API {
        public get {
            if (Test.isRunningTest() && API != null) { // API has been mocked.
                return API;
            } else {
                return (API) DependencyV1.inject(API.class);
            }
        }
        private set;
    }

    /**
     * @description
     * Class providing the implementation of the LWC.
     */
    private with sharing class Implementation implements API {

        /**
         * @description
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
            return (List<Map<String, Object>>) ArrayV1.over(
                    Database.query(
                            'SELECT Id, Owner.Name, ApexJobId__c, Reference__c, Status__c, RetryNumber__c, MaximumRetries__c, Runnable__c, ScheduledRunTime__c, LastRunTime__c'
                                    + ' FROM AsynchronousJob__c'
                                    + ' WHERE ' + buildQuery(filters)
                                    + ' WITH USER_MODE'
                                    + ' ORDER BY '
                                    + ordering
                                    + ' LIMIT :max'
                                    + ' OFFSET :offset'
                    ))
                    .reduce(new ResultBuilder(), new List<Map<String, Object>>());
        }

        /**
         * @description
         * Deletes the given AsynchronousJob__c records.
         *
         * @param jobIds The ids of the jobs to delete.
         */
        public void deleteJobs(final List<Id> jobIds) {
            Database.delete(
                    [SELECT Id FROM AsynchronousJob__c WHERE Id IN :jobIds WITH USER_MODE],
                    AccessLevel.USER_MODE
            );
        }

        /**
         * @description
         * Re-runs the given AsynchronousJob__c records.
         *
         * @param jobIds The ids of the jobs to re-run.
         */
        public void runJobs(final List<Id> jobIds) {
            final String schedulerClassName = AsynchronousScheduler.RunNextAvailable.class.getName();
            final List<AsynchronousJob__c> jobs = (List<AsynchronousJob__c>) ArrayV1.over([
                        SELECT Id
                        FROM AsynchronousJob__c
                        WHERE Id IN :jobIds AND Runnable__c != :schedulerClassName
                        WITH USER_MODE
                    ])
                    .transform(new RequeueJob());

            Database.update(jobs, AccessLevel.USER_MODE);
        }

        /**
         * @description
         * Calculates the total number of objects per status for the current user.
         *
         * @return The totals.
         */
        public Map<String, Integer> getTotals() {
            final Map<String, Integer> returnMap = (Map<String, Integer>) ArrayV1.over([
                            SELECT Status__c, Count(Id) Total__c
                            FROM AsynchronousJob__c
                            WITH USER_MODE
                            GROUP BY Status__c
                    ])
                    .reduce(new BuildTotals(), new Map<String, Integer>());

            for (AsynchronousV1.Status status : AsynchronousV1.Status.values()) {
                final String statusName = status.name();
                if (!returnMap.containsKey(statusName)) {
                    returnMap.put(statusName, 0);
                }
            }

            return returnMap;
        }

        /**
         * @description
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
                    String clause =(field += ' IN(');

                    Boolean first = true;
                    for (Object option : (List<Object>) value) {
                        if (!first) {
                            clause += ',';
                        }

                        if (option instanceof String) {
                            clause += '\'' + String.escapeSingleQuotes((String) option) + '\'';
                        } else {
                            clause += option;
                        }

                        first = false;
                        hasValue = true;
                    }

                    clauses.add(clause + ')');

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
    }

    /**
     * @description
     * Class providing check on Binding made to AsynchronousV1.LWC.
     */
    public with sharing class BindingCheck implements DependencyV1.BindingCheck {

        /**
         * @description
         * Checks that a valid binding has been made to AsynchronousV1.API.
         *
         * @param forType The type being bound to, AsynchronousV1.API.
         * @param withImpl The implementation being bound to AsynchronousV1.API.
         *
         * @return The result of the validation.
         */
        public DependencyV1.ValidationResult validate(final Type forType, final Type withImpl) {
            return DependencyHelper.buildValidationResult(
                    TypesV1.newInstance(withImpl) instanceof API,
                    true,
                    forType,
                    withImpl
            );
        }
    }

    /**
     * @description
     * Creates the default LWC API implementation.
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
     * Callback class to re-queue a job.
     */
    private with sharing class RequeueJob extends ArrayV1.Callback {
        private final Datetime now = Datetime.now();

        public override Optional function(final Object element, final Optional currentValue, final Integer index) {
            final AsynchronousJob__c job = (AsynchronousJob__c) element;
            job.Status__c = AsynchronousV1.Status.PENDING.name();
            job.ScheduledRunTime__c = now;
            return Optional.of(job);
        }
    }

    /**
     * @description
     * Callback class to build totals for Job status.
     */
    private with sharing class BuildTotals extends ArrayV1.Callback {
        private final String statusField = AsynchronousJob__c.Status__c.getDescribe().name;

        public override Optional function(final Object element, final Optional currentValue, final Integer index) {
            final AggregateResult result = (AggregateResult) element;
            ((Map<String, Integer>) currentValue.get()).put((String) result.get(statusField), (Integer) result.get('Total__c'));
            return currentValue;
        }
    }

    /**
     * @description
     * Callback class to build the Map representing a job and add it to the List to return.
     */
    private with sharing class ResultBuilder extends ArrayV1.Callback {
        final Datetime now = Datetime.now();

        public override Optional function(final Object element, final Optional currentValue, final Integer index) {
            final AsynchronousJob__c match = (AsynchronousJob__c) element;
            final Map<String, Object> fields = match.getPopulatedFieldsAsMap();
            Map<String, Object> returnObject = new Map<String, Object>();

            for (String field : fields.keySet()) {
                final String stripped = field.replace('forcefw__', '');
                returnObject.put(stripped, fields.get(field));
            }

            returnObject.put('Owner', match.Owner.Name);

            if (match.Status__c == AsynchronousV1.Status.RUNNING.name()) {
                returnObject.put('RunTime__c', now.getTime() - match.LastRunTime__c.getTime());
                if (match.RetryNumber__c > 0) {
                    returnObject.put('Retry__c', match.RetryNumber__c + ' of ' + match.MaximumRetries__c);
                }
            } else if (match.Status__c == AsynchronousV1.Status.QUEUED.name()) {
                if (match.RetryNumber__c > 0) {
                    returnObject.put('Retry__c', match.RetryNumber__c + ' of ' + match.MaximumRetries__c);
                }
            }

            ((List<Map<String, Object>>) currentValue.get()).add(returnObject);
            return currentValue;
        }
    }

    /**
      * @description
      * Method is solely for mocking use.
      */
    public List<Map<String, Object>> getJobs(final Map<String, Object> filters, final String ordering, final Integer offset, final Integer max) {
        throw new AsynchronousV1.APIException('Access denied');
    }

    /**
      * @description
      * Method is solely for mocking use.
      */
    public void deleteJobs(final List<Id> jobIds) {
        throw new AsynchronousV1.APIException('Access denied');
    }

    /**
      * @description
      * Method is solely for mocking use.
      */
    public void runJobs(final List<Id> jobIds) {
        throw new AsynchronousV1.APIException('Access denied');
    }

    /**
      * @description
      * Method is solely for mocking use.
      */
    public Map<String, Integer> getTotals() {
        throw new AsynchronousV1.APIException('Access denied');
    }

    // Set the default implementations of API and LWC. This can be overridden using a Dependency Injection Binding.
    static {
        DependencyV1.bind(API.class, Factory.class);
    }
}