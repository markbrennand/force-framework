/**
 * @description
 * Class providing the default implementation of the Asynchronous API.
 * <br><br>
 * The default implementation of the API in this class uses the AsynchronousJob__c object to represent a job. The object
 * may be queried to find all the information about the job.
 * <br><br>
 * The implementation of the API is hidden in the private Implementation class. The class is hidden so an application
 * cannot access the class to mis-use it.
 * <br><br>
 * All application access is restricted to the API instance variable INJECT. This ensures the application can only
 * ever call the methods of the API interface.
 * <br><br>
 * The outer class implements the API only to allow it to be mocked. Any calls to the API method implementations
 * in the outer class will throw an Exception.
 * <br><br>
 * See <a href=../README.md target="_blank">README</a> for full details of the Asynchronous API.
 *
 * @author Mark Brennand
 */
public with sharing virtual class AsynchronousImpl implements AsynchronousV1.API {

    /**
     * @description
     * Flag determining whether to run the triggers or not.
     * <br><br>
     * When persisting an AsynchronousJob__c object in all places other than job creation, the triggers should be
     * disabled as they add a lot of overhead. And there is no need to try and start an Asynchronous Scheduler
     * for the updates made to the object.
     */
    public static Boolean skipTriggers = false;

    /**
     * @description
     * Active API instance.
     * <br><br>
     * The instance is injected from the Registry.
     * <br><br>
     * The instance is test visible so it can be mocked.
     */
    @TestVisible
    public static AsynchronousV1.API INJECT {
        public get {
            if (Test.isRunningTest() && INJECT != null) { // INJECT has been mocked.
                return INJECT;
            } else {
                return (AsynchronousV1.API) DependencyV1.inject(AsynchronousV1.API.class);
            }
        }
        private set;
    }

    /**
     * @description
     * Allow extension but not construction.
     * <br><br>
     * This is also required to support the Apex mocking classes. A private constructor cannot be mocked.
     */
    protected AsynchronousImpl() {}

    /**
     * @description
     * Creates the default API implementation.
     * <br><br>
     * The constructor for the implementation is protected. This prevents the Dependency framework constructing it.
     * We use the factory to defer the construction by injection to this class, which is able to construct it.
     */
    public with sharing class Factory implements TypesV1.Factory {
        public Object newInstance() {
            return new APIImpl();
        }
    }

    /**
     * @description
     * Class providing the implementation of the API.
     */
    private with sharing class APIImpl implements AsynchronousV1.API {

        /**
         * @description
         * Creates a new instance of a job to be managed by the default API implementation.
         * <br><br>
         * The Apex class must implement the Runnable interface. If it doesn't, the implementation will throw an
         * exception.
         * <br><br>
         * The state is data specific to the job. It is passed to the Runnable for the job when it is invoked. It
         * can contain any data an application chooses. For example, it may include arguments specific to the job.
         *
         * @param type The Apex class of the job to be run.
         * @param reference The user's reference for the job.
         * @param maximumRetries The maximum number of retries to make before failing the job.
         * @param retryInterval The number of milliseconds between each re-try event.
         * @param state Job specific data.
         *
         * @return The job.
         */
        public AsynchronousV1.Job createJob(
                final Type type,
                final String reference,
                final Integer maximumRetries,
                final Integer retryInterval,
                final Map<String, String> state
        ) {
            final AsynchronousJob__c asynchronousObject = new AsynchronousJob__c(
                    Status__c = AsynchronousV1.Status.PENDING.name(),
                    OwnerId = UserInfo.getUserId(),
                    Runnable__c = type.getName(),
                    Reference__c = reference,
                    MaximumRetries__c = maximumRetries,
                    RetryInterval__c = retryInterval,
                    ScheduledRunTime__c = Datetime.now(),
                    RetryNumber__c = 0
            );

            final AsynchronousV1.Job job = AsynchronousJob.fromSObject(asynchronousObject);
            job.setState(state);

            return job;
        }

        /**
         * @description
         * Schedules the given job for processing by the default API implementation.
         * <br><br>
         * Each job will have an AsynchronousJob__c object created for it. The job's state will be saved in the
         * AsynchronousState__c object.
         * <br><br>
         * The trigger on AsynchronousJob__c will validate the job. If the job is valid, the trigger will change the
         * Status to QUEUED and start an Asynchronous Scheduler to run the job.
         *
         * @param asyncJobs The jobs to schedule for processing.
         *
         * @return The jobs queued for processing.
         */
        public List<AsynchronousV1.Job> queueJobs(final List<AsynchronousV1.Job> asyncJobs) {
            Assertion.isNotNull(asyncJobs, 'argument: Asynchronous.queueJobs.asyncJobs');

            final List<AsynchronousJob__c> asyncObjects = new List<AsynchronousJob__c>();
            final List<Map<String, String>> states = new List<Map<String, String>>();

            for (AsynchronousV1.Job job : asyncJobs) {
                asyncObjects.add(AsynchronousJob.toSObject(job));
                states.add(job.getState());
            }

            AsynchronousDAO.INJECT.persistObjects(asyncObjects, states);

            final List<AsynchronousV1.Job> returnList = new List<AsynchronousV1.Job>();
            Integer i = 0;

            for (AsynchronousJob__c asyncObject : asyncObjects) {
                Assertion.isNotNull(asyncObject.Id, 'Asynchronous.Job object has not been assigned an Id');

                final AsynchronousV1.Job updatedJob = AsynchronousJob.fromSObject(asyncObject);
                updatedJob.setState(states[i++]);
                returnList.add(updatedJob);
            }

            return returnList;
        }
    }

    /**
     * @description
     * Processes any persisted AsynchronousJob__c objects before they are added to the database.
     * <br><br>
     * Validation is performed on the objects.
     * <br><br>
     * If all objects are valid, their status is set to QUEUED and an Asynchronous Scheduler is started to run them.
     *
     * @param asyncObjects The persisted objects.
     */
    public static void onTriggerBefore(final List<AsynchronousJob__c> asyncObjects) {
        if (skipTriggers) {
            return;
        }

        Boolean hasErrors = false;

        for (AsynchronousJob__c asyncObject : asyncObjects) {
            try {
                final Object runnable = TypesV1.newInstance(TypesV1.load(asyncObject.Runnable__c));
                if (! (runnable instanceof AsynchronousV1.Runnable)) {
                    asyncObject.addError('Class ' + asyncObject.Runnable__c + ' does not implement Asynchronous.Runnable');
                    hasErrors = true;

                } else if (asyncObject.Status__c == AsynchronousV1.Status.PENDING.name()) {
                    asyncObject.Status__c = AsynchronousV1.Status.QUEUED.name();
                    asyncObject.ScheduledRunTime__c = Datetime.now();
                    asyncObject.RetryNumber__c = 0;
                }

            } catch(Exception e) {
                asyncObject.addError(e.getMessage());
                hasErrors = true;
            }
        }
    }

    /**
     * @description
     * Processes any persisted AsynchronousJob__c objects after they have been added to the database.
     * <br><br>
     * Any new cancellations are processed.
     *
     * @param asyncObjects The persisted objects.
     * @param previousAsyncObjects The previous values of the persisted objects.
     */
    public static void onTriggerAfter(final List<AsynchronousJob__c> asyncObjects, final Map<Id, AsynchronousJob__c> previousAsyncObjects) {
        if (skipTriggers) {
            return;
        }

        final List<AsynchronousJob__c> toDelete = new List<AsynchronousJob__c>();
        Boolean startScheduler = false;

        for (AsynchronousJob__c asyncObject : asyncObjects) {
            final Boolean isScheduler = AsynchronousJob.fromSObject(asyncObject).getRunnable() instanceof AsynchronousScheduler;

            if (asyncObject.Status__c == AsynchronousV1.Status.CANCELLED.name() &&
                    asyncObject.Status__c != previousAsyncObjects?.get(asyncObject.Id)?.Status__c
            ) {
                final AsynchronousV1.Job asyncJob = AsynchronousJob.fromSObject(asyncObject);
                if (!asyncJob.getRunnable().onCancellation(asyncJob)) {
                    toDelete.add(new AsynchronousJob__c(Id = asyncObject.Id));
                }
            } else if (!isScheduler) {
                startScheduler = true;
            }
        }

        AsynchronousDAO.INJECT.removeObjects(toDelete);

        if (startScheduler) {
            AsynchronousScheduler.queue(new Set<String>());
        }
    }


    /**
     * @description
     * Class providing check on Binding made to AsynchronousV1.API.
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
        public DependencyV1.ValidationResult validate(Type forType, Type withImpl) {
            if (TypesV1.newInstance(withImpl) instanceof AsynchronousV1.API) {
                return new DependencyV1.ValidationResult(true, null);
            } else {
                return new DependencyV1.ValidationResult(
                        false,
                        'Class ' + withImpl.getName() + ' does not implement ' + forType.getName()
                );
            }
        }
    }

    /**
     * @description
     * Method is solely for mocking use.
     */
    public AsynchronousV1.Job createJob(
            final Type type,
            final String reference,
            final Integer maximumRetries,
            final Integer retryInterval,
            final Map<String, String> state
    ) {
        throw new AsynchronousV1.APIException('Access denied');
    }

    /**
     * @description
     * Method is solely for mocking use.
     */
    public List<AsynchronousV1.Job> queueJobs(final List<AsynchronousV1.Job> asyncJobs) {
        throw new AsynchronousV1.APIException('Access denied');
    }

    /**
     * @description
     * Returns a List of the AsynchronousJob__c objects matching the filter criteria.
     *
     * @param filters Query filters to be applied.
     * @param offset The record to return results from.
     * @param max  The maximum number of records to return.
     *
     * @return A list of the matching objects.
     */
    @AuraEnabled(Cacheable = false)
    public static List<Map<String, Object>> getJobs(final Map<String, Object> filters, final Integer offset, final Integer max) {
        final String userId = UserInfo.getUserId();
        final List<AsynchronousJob__c> matches;

        if (filters == null || filters.isEmpty()) {
            matches = [
                    SELECT Id, ApexJobId__c, Reference__c, Status__c, RetryNumber__c, MaximumRetries__c, Runnable__c, ScheduledRunTime__c, LastRunTime__c
                    FROM AsynchronousJob__c
                    WHERE OwnerId = :userId
                    WITH USER_MODE
                    ORDER BY ScheduledRunTime__c
                    LIMIT :max
                    OFFSET :offset
            ];
        } else {
            matches = Database.query(
                    'SELECT Id, ApexJobId__c, Reference__c, Status__c, RetryNumber__c, MaximumRetries__c, Runnable__c, ScheduledRunTime__c, LastRunTime__c'
                            + ' FROM AsynchronousJob__c'
                            + ' WHERE ' + buildQuery(filters)
                            + ' WITH USER_MODE'
                            + ' ORDER BY ScheduledRunTime__c '
                            + ' LIMIT :max'
                            + ' OFFSET :offset'
            );
        }

        return buildReturnList(matches);
    }

    /**
     * @description
     * Deletes the given AsynchronousJob__c records.
     *
     * @param jobIds The ids of the jobs to delete.
     */
    @AuraEnabled(Cacheable = false)
    public static void deleteJobs(final List<Id> jobIds) {
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
    @AuraEnabled(Cacheable = false)
    public static void runJobs(final List<Id> jobIds) {
        final String schedulerClassName = AsynchronousScheduler.RunNextAvailable.class.getName();

        final List<AsynchronousJob__c> jobs = [
                SELECT Id
                FROM AsynchronousJob__c
                WHERE Id IN :jobIds AND Runnable__c != :schedulerClassName
                WITH USER_MODE
        ];

        final Datetime now = Datetime.now();
        for (AsynchronousJob__c job : jobs) {
            job.Status__c = AsynchronousV1.Status.PENDING.name();
            job.ScheduledRunTime__c = now;
        }

        Database.update(jobs, AccessLevel.USER_MODE);
    }

    /**
     * @description
     * Converts the filters argument from the LWC to a WHERE clause.
     *
     * @param filters The query filters.
     *
     * @return The WHERE clause for the query.
     */
    private static String buildQuery(final Map<String, Object> filters) {
        String query = 'OwnerId = :userId';

        for (String field : filters.keySet()) {
            query += ' AND ';

            final Object value = filters.get(field);
            Boolean hasValue = false;

            if (value instanceof List<Object>) {
                query += (field += ' IN(');

                Boolean first = true;
                for (Object option : (List<Object>) value) {
                    if (!first) {
                        query += ',';
                    }

                    if (option instanceof String) {
                        query += '\'' + String.escapeSingleQuotes((String) option) + '\'';
                    } else {
                        query += option;
                    }

                    first = false;
                    hasValue = true;
                }

                query += ')';

            } else if (value instanceof String){
                query += (field += ' LIKE ');
                query += '\'' + String.escapeSingleQuotes((String) value) + '\'';
                hasValue = true;

            } else {
                query += (field += '=');
                query += filters.get(field);
                hasValue = true;
            }

            if (!hasValue) {
                // The query filter returns no matches.
                return 'Id = null';
            }
        }

        return query;
    }

    /**
     * @description
     * Converts a List of AsynchronousJob__c records to the data format expectged by the LWC.
     *
     * @param matches Jobs to build the return list for.
     *
     * @return The list.
     */
    private static List<Map<String, Object>> buildReturnList(final List<AsynchronousJob__c> matches) {
        final List<Map<String, Object>> returnList = new List<Map<String, Object>>();
        final Datetime now = Datetime.now();
        for (AsynchronousJob__c match : matches) {
            Map<String, Object> fields = match.getPopulatedFieldsAsMap();
            Map<String, Object> returnObject = new Map<String, Object>();

            for (String field : fields.keySet()) {
                final String stripped = field.replace('forcefw__', '');
                returnObject.put(stripped, fields.get(field));
            }

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

            returnList.add(returnObject);
        }

        return returnList;

    }

    // Set the default implementation of the API. This can be overridden using a Dependency Injection Binding.
    static {
        DependencyV1.bind(AsynchronousV1.API.class, Factory.class);
    }
}