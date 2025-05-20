/**
 * @description
 * API providing all SOQL and DML access for the Asynchronous framework.
 *
 * @author Mark Brennand
 */
public with sharing class AsynchronousDAO implements API {

    public interface API {
        Asynchronous__c apiGetObject(Id asyncOjectId);
        Asynchronous__c apiGetNextScheduled();
        Integer apiCountScheduledObjects(Boolean scheduledOnly);
        Integer apiCountActiveObjects(final Asynchronous__c asyncJob);
        void apiPersistAsynchronous(List<Asynchronous__c> asyncObjects);
        void apiPersistAsynchronous(List<Asynchronous__c> asyncObjects, List<Map<String, String>> states);
        void apiRemoveAsynchronous(List<Asynchronous__c> asyncObject);
        void apiPersistAsynchronousError(AsynchronousException__c asyncError);
    }

    public Asynchronous__c apiGetObject(Id asyncObjectId) {
        Assert.isNotNull(asyncObjectId, 'parameter; AsynchronousDAO.apiGetObject.asyncObjectId');

        final List<Asynchronous__c> asyncObjects = [
                SELECT Id, OwnerId, Status__c, Reference__c, Runnable__c, MaximumRetries__c, RetryInterval__c,
                        RetryNumber__c, ScheduledRunTime__c, LastRunTime__c,
                        (SELECT Content__c FROM AsynchronousStates__r ORDER BY ChunkNumber__c)
                FROM Asynchronous__c
                WHERE Id = :asyncObjectId
                WITH USER_MODE
                LIMIT 1
        ];

        Assert.areEqual(1, asyncObjects.size(), 'Asynchronous object with Id ' + asyncObjectId + ' not found');

        return asyncObjects[0];
    }

    public Asynchronous__c apiGetNextScheduled() {
        final List<Asynchronous__c> scheduledAsyncObjects = [
                SELECT Id, ScheduledRunTime__c, RetryNumber__c, Status__c
                FROM Asynchronous__c
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
            final List<Asynchronous__c> lockedAsyncObjects = [
                    SELECT Id, OwnerId, Status__c, Reference__c, Runnable__c, MaximumRetries__c, RetryInterval__c,
                            RetryNumber__c, ScheduledRunTime__c, LastRunTime__c,
                            (SELECT Content__c FROM AsynchronousStates__r ORDER BY ChunkNumber__c)
                    FROM Asynchronous__c
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
        Assert.isNotNull(scheduledOnly, 'parameter; AsynchronousDAO.apiCountScheduledObjects.scheduledOnly');

        if (scheduledOnly) {
            return [
                    SELECT COUNT()
                    FROM Asynchronous__c
                    WHERE OwnerId = :UserInfo.getUserId()
                    AND ScheduledRunTime__c <= :Datetime.now()
                    AND Status__c = :Asynchronous.Status.QUEUED.name()
                    AND Runnable__c != :AsynchronousScheduler.class.getName()
                    WITH USER_MODE
            ];
        } else {
            return [
                    SELECT COUNT()
                    FROM Asynchronous__c
                    WHERE OwnerId = :UserInfo.getUserId()
                    AND Status__c = :Asynchronous.Status.QUEUED.name()
                    AND Runnable__c != :AsynchronousScheduler.class.getName()
                    WITH USER_MODE
            ];
        }
    }

    public Integer apiCountActiveObjects(final Asynchronous__c asyncJob) {
        Assert.isNotNull(asyncJob, 'parameter; AsynchronousDAO.apiCountActiveObjects.asyncJob');

        return [
                SELECT COUNT()
                FROM Asynchronous__c
                WHERE OwnerId = :UserInfo.getUserId()
                AND Runnable__c = :asyncJob.Runnable__c
                AND Status__c = :Asynchronous.Status.RUNNING.name()
                WITH USER_MODE
        ];
    }

    public void apiPersistAsynchronous(final List<Asynchronous__c> asyncObjects, final List<Map<String, String>> states) {
        Assert.isNotNull(asyncObjects, 'parameter; AsynchronousDAO.apiPersistAsynchronous.asyncObjects');
        Assert.isNotNull(states, 'parameter; AsynchronousDAO.apiPersistAsynchronous.states');
        Assert.areEqual(asyncObjects.size(), states.size(), 'The number of Asynchronous objects does not match the number of states');

        Database.upsert(asyncObjects, AccessLevel.USER_MODE);

        final Set<Id> allIds = new Set<Id>();
        final List<AsynchronousState__c> newStates = new List<AsynchronousState__c>();
        for (Integer i = 0; i < asyncObjects.size(); i++) {
            final Asynchronous__c asynchronousObject = asyncObjects[i];
            allIds.add(asynchronousObject.Id);
            newStates.addAll(AsynchronousHelper.encodeState(asynchronousObject, states[i]));
        }

        Database.delete(
                [SELECT Id FROM AsynchronousState__c WHERE Asynchronous__c IN :allIds WITH USER_MODE],
                AccessLevel.USER_MODE
        );

        Database.upsert(newStates, AccessLevel.USER_MODE);
    }

    public void apiPersistAsynchronous(final List<Asynchronous__c> asyncObjects) {
        Assert.isNotNull(asyncObjects, 'parameter; AsynchronousDAO.apiPersistAsynchronous.asyncObjects');
        Database.upsert(asyncObjects, AccessLevel.USER_MODE);
    }

    public void apiRemoveAsynchronous(final List<Asynchronous__c> asynchronousObjects) {
        Assert.isNotNull(asynchronousObjects, 'parameter; AsynchronousDAO.apiRemoveAsynchronous.asynchronousObjects');
        Database.delete(asynchronousObjects, AccessLevel.USER_MODE);
    }

    public void apiPersistAsynchronousError(AsynchronousException__c asyncError) {
        Assert.isNotNull(asyncError, 'parameter; AsynchronousDAO.apiPersistAsynchronousError.asyncError');
        Database.insert(asyncError, AccessLevel.USER_MODE);
    }

    public static Asynchronous__c getObject(final Id asyncObjectId) {
        return INSTANCE.apiGetObject(asyncObjectId);
    }

    public static Asynchronous__c getNextScheduled() {
        return INSTANCE.apiGetNextScheduled();
    }

    public static Integer countScheduledObjects(final Boolean scheduledOnly) {
        return INSTANCE.apiCountScheduledObjects(scheduledOnly);
    }

    public static Integer countActiveObjects(final Asynchronous__c asyncJob) {
        return INSTANCE.apiCountActiveObjects(asyncJob);
    }

    public static void persistAsynchronous(final List<Asynchronous__c> asyncObjects) {
        INSTANCE.apiPersistAsynchronous(asyncObjects);
    }

    public static void persistAsynchronous(final List<Asynchronous__c> asyncObjects, final List<Map<String, String>> states) {
        INSTANCE.apiPersistAsynchronous(asyncObjects, states);
    }

    public static void removeAsynchronous(final List<Asynchronous__c> asyncObjects) {
        INSTANCE.apiRemoveAsynchronous(asyncObjects);
    }

    public static void persistAsynchronousError(AsynchronousException__c asyncError) {
        INSTANCE.apiPersistAsynchronousError(asyncError);
    }

    /**
     * @description
     * Class providing check on Binding made to AsynchronousDAO.API.
     */
    public with sharing class BindingCheck implements Injection.BindingCheck {

        /**
         * @description
         * Checks that a valid binding has been made to AsynchronousDAO.API.
         *
         * @param forType The type being bound to, AsynchronousDAO.API.
         * @param withImpl The implementation being bound to AsynchronousDAO.API.
         *
         * @return The result of the validation.
         */
        public Injection.ValidationResult validate(Type forType, Type withImpl) {
            if (TypeHelper.newInstance(withImpl) instanceof AsynchronousDAO.API) {
                return new Injection.ValidationResult(true, null);
            } else {
                return new Injection.ValidationResult(
                        false,
                        'Class ' + withImpl.getName() + ' does not implement ' + forType.getName()
                );
            }
        }
    }

    // Set the default implementation of the API. This can be overridden using an Injection Binding.
    static {
        Injection.bind(API.class, AsynchronousDAO.class);
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
                INSTANCE = (API) Injection.wire(API.class);
            }
            return INSTANCE;
        }
        private set;
    }
}