
/**
 * @description
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../../LICENSE target="_blank">MIT License</a>.
 * <br><br>
 * Class defining the API for all DML and SOQL operations required by the default Asynchronous API implementation.
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
public with sharing virtual class AsynchronousDAO implements API {

    /**
     * @description
     * Interface defining the SOQL and DML operations.
     */
    public interface API {

        /**
         * @description
         * Given the Id of an object, the object is retrieved.
         *
         * @param asyncObjectId The Id of the object to retrieve.
         *
         * @return The object.
         */
        AsynchronousJob__c getObject(final Id asyncObjectId);

        /**
         * @description
         * Builds a List of the objects that are scheduled to run.
         * <br><br>
         * The List returned must be ordered chronologically, with the first entry being the job that has been
         * waiting the longest to run.
         *
         * @param maxJobsToReturn The maximum number of objects to return.
         *
         * @return The objects.
         */
        List<AsynchronousJob__c> getScheduledObjects(final Integer maxJobsToReturn);

        /**
         * @description
         * Determines the number os objects that remain to be run.
         * <br><br>
         * The remaining objects must includes all those that are in QUEUED or RUNNING state. The RUNNING must
         * be included as their job may fail and they will be scheduled to re-run if they have re-tries left.
         *
         * @return The number of objects that are scheduled or are running.
         */
        Integer countSchedulableObjects();

        /**
         * @description
         * Determines the number of active instances of the given object.
         * <br><br>
         * The Runnable in for the object determines the number of active instances.
         *
         * @param asyncObject The object to have its concurrency determined.
         *
         * @return The concurrency for the object.
         */
        Integer countActiveObjects(final AsynchronousJob__c asyncObject);

        /**
         * @description
         * Inserts or updates the given objects.
         *
         * @param asyncObjects The objects to persist.
         */
        void persistObjects(final List<AsynchronousJob__c> asyncObjects);

        /**
         * @description
         * Inserts or updates the given objects and states.
         * <br><br>
         * The objects must be persisted first and then each state linked to its associated object before
         * persisting.
         *
         * @param asyncObjects The objects to persist.
         * @param states The states to persist.
         */
        void persistObjects(final List<AsynchronousJob__c> asyncObjects, final List<Map<String, String>> states);

        /**
         * @description
         * Deletes the given objects.
         *
         * @param asyncObjects The objects to remove.
         */
        void removeObjects(final List<AsynchronousJob__c> asyncObjects);

        /**
         * @description
         * Inserts the given exception object.
         *
         * @param asyncErrorObject The exception object to persist.
         */
        void persistException(final AsynchronousJobException__c asyncErrorObject);
    }

    /**
     * @description
     * Active API instance.
     *
     * The instance is injected from the Registry.
     */
    @TestVisible
    @SuppressWarnings('PMD.PropertyNamingConventions')
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
     * Allow extension but not construction.
     * <br><br>
     * This is also required to support the Apex mocking classes. A private constructor cannot be mocked.
     */
    @SuppressWarnings('PMD.EmptyStatementBlock')
    protected AsynchronousDAO() {}

    /**
     * @description
     * Class providing the implementation of the API.
     */
    private with sharing class Implementation implements API {

        /**
         * @description
         * Given the Id of the AsynchronousJob__c object, the object is retrieved.
         *
         * @param asyncObjectId The Id of the object to retrieve.
         *
         * @return The object.
         */
        public AsynchronousJob__c getObject(final Id asyncObjectId) {
            AssertionV1.isNotNull(asyncObjectId, 'argument: AsynchronousDAO.apiGetObject.asyncObjectId');

            final OptionalV1 matches = QueryV1.of(AsynchronousJob__c.SObjectType)
                    .security(AccessLevel.USER_MODE)
                    .matching('Id = :asyncObjectId')
                    .returning(new Set<SObjectField> {
                            AsynchronousJob__c.OwnerId,
                            AsynchronousJob__c.Status__c,
                            AsynchronousJob__c.Reference__c,
                            AsynchronousJob__c.Runnable__c,
                            AsynchronousJob__c.MaximumRetries__c,
                            AsynchronousJob__c.RetryInterval__c,
                            AsynchronousJob__c.RetryNumber__c,
                            AsynchronousJob__c.ScheduledRunTime__c,
                            AsynchronousJob__c.LastRunTime__c,
                            AsynchronousJob__c.ApexJobId__c
                    })
                    .returning(
                            QueryV1.of(AsynchronousJobState__c.SObjectType)
                                    .returning(new Set<SObjectField> { AsynchronousJobState__c.Content__c })
                                    .ordered(QueryV1.ascending(AsynchronousJobState__c.ChunkNumber__c))
                    )
                    .max(1)
                    .execute(OptionalV1.of(new Map<String, Object> { 'asyncObjectId' => asyncObjectId }));

            AssertionV1.isTrue(matches.isPresent(), 'Asynchronous object with Id ' + asyncObjectId + ' not found');
            return ((List<AsynchronousJob__c>) matches.get())[0];
        }

        /**
         * @description
         * Builds a List of the AsynchronousJob__c objects that are scheduled to run.
         * <br><br>
         * The AsynchronousJob__c objects are ordered by ScheduledRunTime__c. This ensures that the list returned
         * is in chronological order, with the first entry being the job that has been waiting the longest to run.
         *
         * @param maxJobsToReturn The maximum number of objects to return.
         *
         * @return The objects.
         */
        public List<AsynchronousJob__c> getScheduledObjects(final Integer maxJobsToReturn) {
            return (List<AsynchronousJob__c>) QueryV1.of(AsynchronousJob__c.SObjectType)
                    .security(AccessLevel.USER_MODE)
                    .matching('OwnerId = :ownerId AND ScheduledRunTime__c <= :now AND Runnable__c != :schedulerClass AND Status__c = :queued')
                    .returning(new Set<SObjectField> { AsynchronousJob__c.Runnable__c })
                    .ordered(QueryV1.ascending(AsynchronousJob__c.ScheduledRunTime__c))
                    .max(maxJobsToReturn)
                    .execute(OptionalV1.of(
                            new Map<String, Object> {
                                    'ownerId' => UserInfo.getUserId(),
                                    'now' => CommonHelper.now(),
                                    'schedulerClass' => AsynchronousScheduler.RunNextAvailable.class.getName(),
                                    'queued' => AsynchronousV1.Status.QUEUED.name()
                            }
                            ))
                    .orElse(new List<AsynchronousJob__c>());
        }

        /**
         * @description
         * Determines the number os AsynchronousJob__c objects that remain to be run.
         * <br><br>
         * The AsynchronousJob__c objects are queried by QUEUED and RUNNING status.
         *
         * @return The number of objects that are scheduled or are running.
         */
        public Integer countSchedulableObjects() {
            final Set<String> schedulableStatuses = new Set<String> {
                    AsynchronousV1.Status.QUEUED.name(),
                    AsynchronousV1.Status.RUNNING.name()
            };

            return (Integer) QueryV1.of(AsynchronousJob__c.SObjectType)
                    .security(AccessLevel.USER_MODE)
                    .matching('OwnerId = :ownerId AND Status__c IN :schedulableStatuses AND Runnable__c != :schedulerClass')
                    .count()
                    .execute(OptionalV1.of(
                            new Map<String, Object> {
                                    'ownerId' => UserInfo.getUserId(),
                                    'schedulableStatuses' => schedulableStatuses,
                                    'schedulerClass' => AsynchronousScheduler.RunNextAvailable.class.getName()
                            }
                    ))
                    .orElse(0);
        }

        /**
         * @description
         * Determines the number of active instances of the given AsynchronousJob__c object.
         * <br><br>
         * A count of the RUNNING jobs are queried which have a Runnable__c that matches that of the given object.
         *
         * @param asyncObject The object to have its concurrency determined.
         *
         * @return The concurrency for the object.
         */
        public Integer countActiveObjects(final AsynchronousJob__c asyncObject) {
            AssertionV1.isNotNull(asyncObject, 'argument: AsynchronousDAO.apiCountActiveObjects.asyncObject');

            return (Integer) QueryV1.of(AsynchronousJob__c.SObjectType)
                    .security(AccessLevel.USER_MODE)
                    .matching('OwnerId = :ownerId AND Runnable__c = :runnableClass AND Status__c = :runningStatus')
                    .count()
                    .execute(OptionalV1.of(new Map<String, Object> {
                            'ownerId' => UserInfo.getUserId(),
                            'runnableClass' => asyncObject.Runnable__c,
                            'runningStatus' => AsynchronousV1.Status.RUNNING.name()
                    }))
                    .orElse(0);
        }

        /**
         * @description
         * Inserts or updates the given AsynchronousJob__c objects.
         *
         * @param asyncObjects The objects to persist.
         */
        public void persistObjects(final List<AsynchronousJob__c> asyncObjects) {
            AssertionV1.isNotNull(asyncObjects, 'argument: AsynchronousDAO.apiPersistAsynchronous.asyncObjects');

            final Boolean subscribersEnabled = TriggerV1.isEnabled(AsynchronousJobSubscriber.Factory.class);
            TriggerV1.disable(AsynchronousJobSubscriber.Factory.class);

            Database.upsert(asyncObjects, AccessLevel.USER_MODE);

            if (subscribersEnabled) {
                TriggerV1.enable(AsynchronousJobSubscriber.Factory.class);
            } else {
                TriggerV1.disable(AsynchronousJobSubscriber.Factory.class);
            }
        }

        /**
         * @description
         * Inserts or updates the given AsynchronousJob__c objects and states.
         * <br><br>
         * The AsynchronousJob__c objects are persisted first so each has an Id. The List of states is iterated
         * and AsynchronousJobState__c objects are created for the state, and linked to their associated
         * AsynchronousJob__c object. All extant AsynchronousJobState__c objects are deleted before all the new
         * AsynchronousJobState__c objects are persisted.
         *
         * @param asyncObjects The objects to persist.
         * @param states The states to persist.
         */
        public void persistObjects(final List<AsynchronousJob__c> asyncObjects, final List<Map<String, String>> states) {
            AssertionV1.isNotNull(asyncObjects, 'argument: AsynchronousDAO.apiPersistAsynchronous.asyncObjects');
            AssertionV1.isNotNull(states, 'argument: AsynchronousDAO.apiPersistAsynchronous.states');
            AssertionV1.areEqual(asyncObjects.size(), states.size(), 'The number of Asynchronous objects does not match the number of states');

            final Boolean subscribersEnabled = TriggerV1.isEnabled(AsynchronousJobSubscriber.Factory.class);
            TriggerV1.enable(AsynchronousJobSubscriber.Factory.class);

            Database.upsert(asyncObjects, AccessLevel.USER_MODE);

            final Set<Id> allIds = new Set<Id>();
            final List<AsynchronousJobState__c> newStates = new List<AsynchronousJobState__c>();
            for (Integer i = 0; i < asyncObjects.size(); i++) {
                final AsynchronousJob__c asynchronousObject = asyncObjects[i];
                allIds.add(asynchronousObject.Id);
                newStates.addAll(AsynchronousHelper.API.encodeState(asynchronousObject, states[i]));
            }

            QueryV1.of(AsynchronousJobState__c.SObjectType)
                    .security(AccessLevel.USER_MODE)
                    .matching('AsynchronousJob__c IN :allIds')
                    .execute(OptionalV1.of(new Map<String, Object> { 'allIds' => allIds }))
                    .call(new QueryHelper.SObjectDeleter(AccessLevel.USER_MODE));

            Database.upsert(newStates, AccessLevel.USER_MODE);

            if (subscribersEnabled) {
                TriggerV1.enable(AsynchronousJobSubscriber.Factory.class);
            } else {
                TriggerV1.disable(AsynchronousJobSubscriber.Factory.class);
            }
        }

        /**
         * @description
         * Deletes the given AsynchronousJob__c objects.
         *
         * @param asyncObjects The objects to remove.
         */
        public void removeObjects(final List<AsynchronousJob__c> asyncObjects) {
            AssertionV1.isNotNull(asyncObjects, 'argument: AsynchronousDAO.apiRemoveAsynchronous.asynchronousObjects');
            Database.delete(asyncObjects, AccessLevel.USER_MODE);
        }

        /**
         * @description
         * Inserts the given AsynchronousJobException__c object.
         *
         * @param asyncErrorObject The exception object to persist.
         */
        public void persistException(final AsynchronousJobException__c asyncErrorObject) {
            AssertionV1.isNotNull(asyncErrorObject, 'argument: AsynchronousDAO.apiPersistAsynchronousError.asyncErrorObject');
            Database.insert(asyncErrorObject, AccessLevel.USER_MODE);
        }
    }

    /**
     * @description
     * Method is solely for mocking use.
     */
    public AsynchronousJob__c getObject(final Id asyncObjectId) {
        throw new AsynchronousV1.APIException('Access denied');
    }

    /**
     * @description
     * Method is solely for mocking use.
     */
    public List<AsynchronousJob__c> getScheduledObjects(final Integer maxJobsToReturn) {
        throw new AsynchronousV1.APIException('Access denied');
    }

    /**
     * @description
     * Method is solely for mocking use.
     */
    public Integer countSchedulableObjects() {
        throw new AsynchronousV1.APIException('Access denied');
    }

    /**
     * @description
     * Method is solely for mocking use.
     */
    public Integer countActiveObjects(final AsynchronousJob__c asyncJob) {
        throw new AsynchronousV1.APIException('Access denied');
    }

    /**
     * @description
     * Method is solely for mocking use.
     */
    public void persistObjects(final List<AsynchronousJob__c> asyncObjects) {
        throw new AsynchronousV1.APIException('Access denied');
    }

    /**
     * @description
     * Method is solely for mocking use.
     */
    public void persistObjects(final List<AsynchronousJob__c> asyncObjects, final List<Map<String, String>> states) {
        throw new AsynchronousV1.APIException('Access denied');
    }

    /**
     * @description
     * Method is solely for mocking use.
     */
    public void removeObjects(final List<AsynchronousJob__c> asyncObjects) {
        throw new AsynchronousV1.APIException('Access denied');
    }

    /**
     * @description
     * Method is solely for mocking use.
     */
    public void persistException(final AsynchronousJobException__c asyncError) {
        throw new AsynchronousV1.APIException('Access denied');
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
     * Class providing check on Binding made to AsynchronousDAO.API.
     */
    public with sharing class BindingCheck implements DependencyV1.BindingCheck {

        /**
         * @description
         * Checks that a valid binding has been made to AsynchronousDAO.API.
         *
         * @param forType The type being bound to, AsynchronousDAO.API.
         * @param withImpl The implementation being bound to AsynchronousDAO.API.
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


    // Set the default implementation of the API. This can be overridden using a Dependency Binding.
    static {
        DependencyV1.bind(API.class, Factory.class);
    }
}