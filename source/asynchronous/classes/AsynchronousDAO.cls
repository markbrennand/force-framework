
/**
 * @description
 * <p>
 * Class defining the API for all DML and SOQL operations required by the default Asynchronous API implementation.
 * <p>
 * The implementation of the API is hidden in the private Implementation class. The class is hidden so an application
 * cannot access the class to mis-use it.
 * <p>
 * All application access is restricted to the API instance variable API. This ensures the application can only
 * ever call the methods of the API interface.
 * <p>
 * The outer class implements the API only to allow it to be mocked. Any calls to the API method implementations
 * in the outer class will throw an Exception.
 * <p>
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../LICENSE target="_blank">MIT License</a>.
 *
 * @author Mark Brennand
 */
public with sharing virtual class AsynchronousDAO implements API {

    /**
     * @description
     * <p>
     * Interface defining the SOQL and DML operations.
     */
    public interface API {

        /**
         * @description
         * <p>
         * Given the Id of an object, the object is retrieved.
         *
         * @param asyncObjectId The Id of the object to retrieve.
         *
         * @return The object.
         */
        AsynchronousJob__c getObject(final Id asyncObjectId);

        /**
         * @description
         * <p>
         * Builds a List of the objects that are scheduled to run.
         * <p>
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
         * <p>
         * Determines the number os objects that remain to be run.
         * <p>
         * The remaining objects must includes all those that are in QUEUED or RUNNING state. The RUNNING must
         * be included as their job may fail and they will be scheduled to re-run if they have re-tries left.
         *
         * @return The number of objects that are scheduled or are running.
         */
        Integer countSchedulableObjects();

        /**
         * @description
         * <p>
         * Determines the number of active instances of the given object.
         * <p>
         * The Runnable in for the object determines the number of active instances.
         *
         * @param asyncObject The object to have its concurrency determined.
         *
         * @return The concurrency for the object.
         */
        Integer countActiveObjects(final AsynchronousJob__c asyncObject);

        /**
         * @description
         * <p>
         * Inserts or updates the given objects.
         *
         * @param asyncObjects The objects to persist.
         */
        void persistObjects(final List<AsynchronousJob__c> asyncObjects);

        /**
         * @description
         * <p>
         * Inserts or updates the given objects and states.
         * <p>
         * The objects must be persisted first and then each state linked to its associated object before
         * persisting.
         *
         * @param asyncObjects The objects to persist.
         * @param states The states to persist.
         */
        void persistObjects(final List<AsynchronousJob__c> asyncObjects, final List<Map<String, String>> states);

        /**
         * @description
         * <p>
         * Deletes the given objects.
         *
         * @param asyncObjects The objects to remove.
         */
        void removeObjects(final List<AsynchronousJob__c> asyncObjects);

        /**
         * @description
         * <p>
         * Inserts the given exception object.
         *
         * @param asyncErrorObject The exception object to persist.
         */
        void persistException(final AsynchronousJobException__c asyncErrorObject);
    }

    /**
     * @description
     * <p>
     * Active API instance.
     *
     * The instance is injected from the Registry.
     */
    @TestVisible
    public static API impl {
        public get {
            if (Test.isRunningTest() && impl != null) { // API has been mocked.
                return impl;
            } else {
                return (API) DependencyV1.inject(API.class);
            }
        }
        private set;
    }

    /**
     * @description
     * <p>
     * Allow extension but not construction.
     * <p>
     * This is also required to support the Apex mocking classes. A private constructor cannot be mocked.
     */
    @SuppressWarnings('PMD.EmptyStatementBlock')
    protected AsynchronousDAO() {}

    /**
     * @description
     * <p>
     * Class providing the implementation of the API.
     */
    private with sharing class Implementation implements API {

        /**
         * @description
         * <p>
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
                    .returning(AsynchronousJob__c.OwnerId)
                    .returning(AsynchronousJob__c.Status__c)
                    .returning(AsynchronousJob__c.Reference__c)
                    .returning(AsynchronousJob__c.Runnable__c)
                    .returning(AsynchronousJob__c.MaximumRetries__c)
                    .returning(AsynchronousJob__c.RetryInterval__c)
                    .returning(AsynchronousJob__c.RetryNumber__c)
                    .returning(AsynchronousJob__c.ScheduledRunTime__c)
                    .returning(AsynchronousJob__c.LastRunTime__c)
                    .returning(AsynchronousJob__c.ApexJobId__c)
                    .returning(QueryV1.of(AsynchronousJobState__c.SObjectType)
                            .returning(AsynchronousJobState__c.Content__c)
                            .ordered(QueryV1.ascending(AsynchronousJobState__c.ChunkNumber__c))
                    )
                    .max(1)
                    .matching('Id = :asyncObjectId')
                    .bindings(new Map<String, Object> { 'asyncObjectId' => asyncObjectId })
                    .execute();

            AssertionV1.isTrue(matches.isPresent(), 'Asynchronous object with Id ' + asyncObjectId + ' not found');
            return ((AsynchronousJob__c) ((ImmutableV1.ReadOnlyList) matches.get()).get(0));
        }

        /**
         * @description
         * <p>
         * Builds a List of the AsynchronousJob__c objects that are scheduled to run.
         * <p>
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
                    .returning(AsynchronousJob__c.Runnable__c)
                    .ordered(QueryV1.ascending(AsynchronousJob__c.ScheduledRunTime__c))
                    .max(maxJobsToReturn)
                    .matching('OwnerId = :ownerId AND ScheduledRunTime__c <= :now AND Runnable__c != :schedulerClass AND Status__c = :queued')
                    .bindings(new Map<String, Object> {
                            'ownerId' => UserInfo.getUserId(),
                            'now' => CommonHelper.now(),
                            'schedulerClass' => AsynchronousScheduler.RunNextAvailable.class.getName(),
                            'queued' => AsynchronousV1.Status.QUEUED.name()
                    })
                    .execute()
                    .then(new CommonHelper.ToList(new List<AsynchronousJob__c>()))
                    .orElse(new List<AsynchronousJob__c>());
        }

        /**
         * @description
         * <p>
         * Determines the number os AsynchronousJob__c objects that remain to be run.
         * <p>
         * The AsynchronousJob__c objects are queried by QUEUED and RUNNING status.
         *
         * @return The number of objects that are scheduled or are running.
         */
        public Integer countSchedulableObjects() {
            final Set<String> schedulableStatuses = new Set<String> {
                    AsynchronousV1.Status.QUEUED.name(),
                    AsynchronousV1.Status.RUNNING.name()
            };

            return (Integer) QueryV1.count(AsynchronousJob__c.SObjectType)
                    .security(AccessLevel.USER_MODE)
                    .matching('OwnerId = :ownerId AND Status__c IN :schedulableStatuses AND Runnable__c != :schedulerClass')
                    .bindings(new Map<String, Object> {
                            'ownerId' => UserInfo.getUserId(),
                            'schedulableStatuses' => schedulableStatuses,
                            'schedulerClass' => AsynchronousScheduler.RunNextAvailable.class.getName()
                    })
                    .execute()
                    .orElse(0);
        }

        /**
         * @description
         * <p>
         * Determines the number of active instances of the given AsynchronousJob__c object.
         * <p>
         * A count of the RUNNING jobs are queried which have a Runnable__c that matches that of the given object.
         *
         * @param asyncObject The object to have its concurrency determined.
         *
         * @return The concurrency for the object.
         */
        public Integer countActiveObjects(final AsynchronousJob__c asyncObject) {
            AssertionV1.isNotNull(asyncObject, 'argument: AsynchronousDAO.apiCountActiveObjects.asyncObject');

            return (Integer) QueryV1.count(AsynchronousJob__c.SObjectType)
                    .security(AccessLevel.USER_MODE)
                    .matching('OwnerId = :ownerId AND Runnable__c = :runnableClass AND Status__c = :runningStatus')
                    .bindings(new Map<String, Object> {
                            'ownerId' => UserInfo.getUserId(),
                            'runnableClass' => asyncObject.Runnable__c,
                            'runningStatus' => AsynchronousV1.Status.RUNNING.name()
                    })
                    .execute()
                    .orElse(0);
        }

        /**
         * @description
         * <p>
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
         * <p>
         * Inserts or updates the given AsynchronousJob__c objects and states.
         * <p>
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
                newStates.addAll(AsynchronousHelper.impl.encodeState(asynchronousObject, states[i]));
            }

            QueryV1.of(AsynchronousJobState__c.SObjectType)
                    .security(AccessLevel.USER_MODE)
                    .matching('AsynchronousJob__c IN :allIds')
                    .bindings(new Map<String, Object> { 'allIds' => allIds })
                    .execute()
                    .then(new CommonHelper.ToList(new List<SObject>()))
                    .then(new QueryHelper.SObjectDeleter(AccessLevel.USER_MODE));

            Database.upsert(newStates, AccessLevel.USER_MODE);

            if (subscribersEnabled) {
                TriggerV1.enable(AsynchronousJobSubscriber.Factory.class);
            } else {
                TriggerV1.disable(AsynchronousJobSubscriber.Factory.class);
            }
        }

        /**
         * @description
         * <p>
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
         * <p>
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
     * <p>
     * Method is solely for mocking use.
     *
     * @param asyncObjectId ignored.
     *
     * @return ignored.
     */
    public AsynchronousJob__c getObject(final Id asyncObjectId) {
        throw new AsynchronousV1.APIException('Access denied');
    }

    /**
     * @description
     * <p>
     * Method is solely for mocking use.
     *
     * @param maxJobsToReturn ignored.
     *
     * @return ignored.
     */
    public List<AsynchronousJob__c> getScheduledObjects(final Integer maxJobsToReturn) {
        throw new AsynchronousV1.APIException('Access denied');
    }

    /**
     * @description
     * <p>
     * Method is solely for mocking use.
     *
     * @return ignored.
     */
    public Integer countSchedulableObjects() {
        throw new AsynchronousV1.APIException('Access denied');
    }

    /**
     * @description
     * <p>
     * Method is solely for mocking use.
     *
     * @param asyncJob ignored.
     *
     * @return ignored.
     */
    public Integer countActiveObjects(final AsynchronousJob__c asyncJob) {
        throw new AsynchronousV1.APIException('Access denied');
    }

    /**
     * @description
     * <p>
     * Method is solely for mocking use.
     *
     * @param asyncObjects ignored.
     */
    public void persistObjects(final List<AsynchronousJob__c> asyncObjects) {
        throw new AsynchronousV1.APIException('Access denied');
    }

    /**
     * @description
     * Method is solely for mocking use.
     *
     * @param asyncObjects ignored.
     * @param states ignored.
     */
    public void persistObjects(final List<AsynchronousJob__c> asyncObjects, final List<Map<String, String>> states) {
        throw new AsynchronousV1.APIException('Access denied');
    }

    /**
     * @description
     * <p>
     * Method is solely for mocking use.
     *
     * @param asyncObjects ignored.
     */
    public void removeObjects(final List<AsynchronousJob__c> asyncObjects) {
        throw new AsynchronousV1.APIException('Access denied');
    }

    /**
     * @description
     * <p>
     * Method is solely for mocking use.
     *
     * @param asyncError ignored.
     */
    public void persistException(final AsynchronousJobException__c asyncError) {
        throw new AsynchronousV1.APIException('Access denied');
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

        /**
         * @description
         * <p>
         * Returns an instance of the API implementation.
         *
         * @return The API implementation,
         */
        public Object newInstance() {
            return new Implementation();
        }
    }

    /**
     * @description
     * <p>
     * Class providing check on Binding made to AsynchronousDAO.API.
     */
    public with sharing class BindingCheck implements DependencyV1.BindingCheck {

        /**
         * @description
         * <p>
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