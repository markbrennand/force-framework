/**
 * @description
 * API providing all SOQL and DML access for the Asynchronous framework.
 *
 * @author Mark Brennand
 */
public with sharing virtual class AsynchronousDAO implements API {

    public interface API {
        AsynchronousJob__c apiGetObject(Id asyncOjectId);
        AsynchronousJob__c apiGetNextScheduled();
        Integer apiCountScheduledObjects(Boolean scheduledOnly);
        Integer apiCountActiveObjects(final AsynchronousJob__c asyncJob);
        void apiPersistObjects(List<AsynchronousJob__c> asyncObjects);
        void apiPersistObjects(List<AsynchronousJob__c> asyncObjects, List<Map<String, String>> states);
        void apiRemoveObjects(List<AsynchronousJob__c> asyncObject);
        void apiPersistException(AsynchronousJobException__c asyncError);
    }

    protected AsynchronousDAO() {}

    public AsynchronousJob__c apiGetObject(Id asyncObjectId) {
        Assertion.isNotNull(asyncObjectId, 'argument: AsynchronousDAO.apiGetObject.asyncObjectId');

        final List<AsynchronousJob__c> asyncObjects = [
                SELECT Id, OwnerId, Status__c, Reference__c, Runnable__c, MaximumRetries__c, RetryInterval__c,
                        RetryNumber__c, ScheduledRunTime__c, LastRunTime__c,
                        (SELECT Content__c FROM AsynchronousJobState__r ORDER BY ChunkNumber__c)
                FROM AsynchronousJob__c
                WHERE Id = :asyncObjectId
                WITH USER_MODE
                LIMIT 1
        ];

        Assertion.areEqual(1, asyncObjects.size(), 'Asynchronous object with Id ' + asyncObjectId + ' not found');

        return asyncObjects[0];
    }

    public AsynchronousJob__c apiGetNextScheduled() {
        final List<AsynchronousJob__c> scheduledAsyncObjects = [
                SELECT Id, ScheduledRunTime__c, RetryNumber__c, Status__c
                FROM AsynchronousJob__c
                WHERE OwnerId = :UserInfo.getUserId()
                AND ScheduledRunTime__c <= :Datetime.now()
                AND Runnable__c != :AsynchronousScheduler.class.getName()
                AND Status__c = :Asynchronous.Status.QUEUED.name()
                WITH USER_MODE
                ORDER BY ScheduledRunTime__c
                LIMIT 1
        ];

        if (scheduledAsyncObjects.isEmpty()) {
            return null;
        }

        try {
            final List<AsynchronousJob__c> lockedAsyncObjects = [
                    SELECT Id, OwnerId, Status__c, Reference__c, Runnable__c, MaximumRetries__c, RetryInterval__c,
                            RetryNumber__c, ScheduledRunTime__c, LastRunTime__c,
                            (SELECT Content__c FROM AsynchronousJobState__r ORDER BY ChunkNumber__c)
                    FROM AsynchronousJob__c
                    WHERE Id = :scheduledAsyncObjects[0].Id
                    AND Status__c = :Asynchronous.Status.QUEUED.name()
                    AND ScheduledRunTime__c = :scheduledAsyncObjects[0].ScheduledRunTime__c
                    AND RetryNumber__c = :scheduledAsyncObjects[0].RetryNumber__c
                    WITH USER_MODE
                    FOR UPDATE
            ];

            return lockedAsyncObjects.isEmpty() ? null : lockedAsyncObjects[0];
        } catch(Exception exc) {
            if (exc.getMessage().startsWith('Record Currently Unavailable')) {
                return null;
            } else {
                throw exc;
            }
        }
    }

    public Integer apiCountScheduledObjects(final Boolean scheduledOnly) {
        Assertion.isNotNull(scheduledOnly, 'argument: AsynchronousDAO.apiCountScheduledObjects.scheduledOnly');

        if (scheduledOnly) {
            return [
                    SELECT COUNT()
                    FROM AsynchronousJob__c
                    WHERE OwnerId = :UserInfo.getUserId()
                    AND ScheduledRunTime__c <= :Datetime.now()
                    AND Status__c = :Asynchronous.Status.QUEUED.name()
                    AND Runnable__c != :AsynchronousScheduler.class.getName()
                    WITH USER_MODE
            ];
        } else {
            return [
                    SELECT COUNT()
                    FROM AsynchronousJob__c
                    WHERE OwnerId = :UserInfo.getUserId()
                    AND Status__c = :Asynchronous.Status.QUEUED.name()
                    AND Runnable__c != :AsynchronousScheduler.class.getName()
                    WITH USER_MODE
            ];
        }
    }

    public Integer apiCountActiveObjects(final AsynchronousJob__c asyncJob) {
        Assertion.isNotNull(asyncJob, 'argument: AsynchronousDAO.apiCountActiveObjects.asyncJob');
        final String runnableName = AsynchronousJob.fromSObject(asyncJob).getRunnable().getType().getName();

        return [
                SELECT COUNT()
                FROM AsynchronousJob__c
                WHERE OwnerId = :UserInfo.getUserId()
                AND Runnable__c = :runnableName
                AND Status__c = :Asynchronous.Status.RUNNING.name()
                WITH USER_MODE
        ];
    }

    public void apiPersistObjects(final List<AsynchronousJob__c> asyncObjects, final List<Map<String, String>> states) {
        Assertion.isNotNull(asyncObjects, 'argument: AsynchronousDAO.apiPersistAsynchronous.asyncObjects');
        Assertion.isNotNull(states, 'argument: AsynchronousDAO.apiPersistAsynchronous.states');
        Assertion.areEqual(asyncObjects.size(), states.size(), 'The number of Asynchronous objects does not match the number of states');

        Database.upsert(asyncObjects, AccessLevel.USER_MODE);

        final Set<Id> allIds = new Set<Id>();
        final List<AsynchronousJobState__c> newStates = new List<AsynchronousJobState__c>();
        for (Integer i = 0; i < asyncObjects.size(); i++) {
            final AsynchronousJob__c asynchronousObject = asyncObjects[i];
            allIds.add(asynchronousObject.Id);
            newStates.addAll(AsynchronousHelper.encodeState(asynchronousObject, states[i]));
        }

        Database.delete(
                [SELECT Id FROM AsynchronousJobState__c WHERE AsynchronousJob__c IN :allIds WITH USER_MODE],
                AccessLevel.USER_MODE
        );

        Database.upsert(newStates, AccessLevel.USER_MODE);
    }

    public void apiPersistObjects(final List<AsynchronousJob__c> asyncObjects) {
        Assertion.isNotNull(asyncObjects, 'argument: AsynchronousDAO.apiPersistAsynchronous.asyncObjects');
        Database.upsert(asyncObjects, AccessLevel.USER_MODE);
    }

    public void apiRemoveObjects(final List<AsynchronousJob__c> asynchronousObjects) {
        Assertion.isNotNull(asynchronousObjects, 'argument: AsynchronousDAO.apiRemoveAsynchronous.asynchronousObjects');
        Database.delete(asynchronousObjects, AccessLevel.USER_MODE);
    }

    public void apiPersistException(AsynchronousJobException__c asyncError) {
        Assertion.isNotNull(asyncError, 'argument: AsynchronousDAO.apiPersistAsynchronousError.asyncError');
        Database.insert(asyncError, AccessLevel.USER_MODE);
    }

    public static AsynchronousJob__c getObject(final Id asyncObjectId) {
        return INSTANCE.apiGetObject(asyncObjectId);
    }

    public static AsynchronousJob__c getNextScheduled() {
        return INSTANCE.apiGetNextScheduled();
    }

    public static Integer countScheduledObjects(final Boolean scheduledOnly) {
        return INSTANCE.apiCountScheduledObjects(scheduledOnly);
    }

    public static Integer countActiveObjects(final AsynchronousJob__c asyncJob) {
        return INSTANCE.apiCountActiveObjects(asyncJob);
    }

    public static void persistObjects(final List<AsynchronousJob__c> asyncObjects) {
        INSTANCE.apiPersistObjects(asyncObjects);
    }

    public static void persistObjects(final List<AsynchronousJob__c> asyncObjects, final List<Map<String, String>> states) {
        INSTANCE.apiPersistObjects(asyncObjects, states);
    }

    public static void removeObjects(final List<AsynchronousJob__c> asyncObjects) {
        INSTANCE.apiRemoveObjects(asyncObjects);
    }

    public static void persistException(AsynchronousJobException__c asyncError) {
        INSTANCE.apiPersistException(asyncError);
    }

    /**
     * @description
     * Creates the default API implementation.
     *
     * The constructor for the implementation is protected. This prevents the Dependency framework constructing it.
     * We use the factory to defer the construction by injection to this class, which is able to construct it.
     */
    public with sharing class Factory implements TypeHelper.Factory {
        public Object newInstance() {
            return new AsynchronousDAO();
        }
    }

    /**
     * @description
     * Class providing check on Binding made to AsynchronousDAO.API.
     */
    public with sharing class BindingCheck implements Dependency.BindingCheck {

        /**
         * @description
         * Checks that a valid binding has been made to AsynchronousDAO.API.
         *
         * @param forType The type being bound to, AsynchronousDAO.API.
         * @param withImpl The implementation being bound to AsynchronousDAO.API.
         *
         * @return The result of the validation.
         */
        public Dependency.ValidationResult validate(Type forType, Type withImpl) {
            if (TypeHelper.newInstance(withImpl) instanceof AsynchronousDAO.API) {
                return new Dependency.ValidationResult(true, null);
            } else {
                return new Dependency.ValidationResult(
                        false,
                        'Class ' + withImpl.getName() + ' does not implement ' + forType.getName()
                );
            }
        }
    }

    /**
     * @description
     * Active API instance.
     *
     * The instance is wired in from the Registry.
     *
     * The instance is test visible so it can be mocked.
     */
    @TestVisible
    private static API INSTANCE {
        private get {
            if (INSTANCE == null) {
                INSTANCE = (API) Dependency.inject(API.class);
            }
            return INSTANCE;
        }
        private set;
    }

    // Set the default implementation of the API. This can be overridden using a Dependency Binding.
    static {
        Dependency.bind(API.class, Factory.class);
    }
}