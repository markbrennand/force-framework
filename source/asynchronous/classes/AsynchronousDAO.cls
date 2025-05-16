/**
 * @description
 * API providing all SOQL and DML access for the Asyncnhronous framework.
 *
 * @author Mark Brennand
 */
public with sharing class AsynchronousDAO implements API {

    static {
        Injection.add(API.class, AsynchronousDAO.class);
    }

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

    public interface API {
        Asynchronous__c getAsynchronous(Id asyncOjectId);
        List<Asynchronous__c> lockForExecution(Id asyncOjectId);
        Integer countScheduledJobs();
        Integer countActiveJobs(final Asynchronous__c asyncJob);
        List<Asynchronous__c> getScheduledJobs();
        void persistAsynchronous(List<Asynchronous__c> asyncObjects);
        void persistAsynchronous(List<Asynchronous__c> asyncObjects, List<Map<String, String>> states);
        void removeAsynchronous(List<Asynchronous__c> asyncObject);
        void persistAsynchronousError(AsynchronousError__c asyncError);
    }

    public Asynchronous__c getAsynchronous(Id asyncObjectId) {
        Assert.isNotNull(asyncObjectId, 'parameter; AsynchronousDAO.getAsynchronous.asyncObjectId');

        return [
                SELECT Id, OwnerId, Status__c, Reference__c, Runnable__c, MaximumRetries__c, RetryInterval__c,
                        RetryNumber__c, ScheduledRunTime__c, LastRunTime__c,
                        (SELECT Content__c FROM AsynchronousStates__r ORDER BY ChunkNumber__c)
                FROM Asynchronous__c
                WHERE Id = :asyncObjectId
                WITH USER_MODE
                LIMIT 1
        ];
    }

    public List<Asynchronous__c> lockForExecution(final Id asyncObjectId) {
        Assert.isNotNull(asyncObjectId, 'parameter; AsynchronousDAO.lockForExecution.asyncObjectId');

        try {
            return [
                    SELECT Id, OwnerId, Status__c, Reference__c, Runnable__c, MaximumRetries__c, RetryInterval__c,
                            RetryNumber__c, ScheduledRunTime__c, LastRunTime__c,
                            (SELECT Content__c FROM AsynchronousStates__r ORDER BY ChunkNumber__c)
                    FROM Asynchronous__c
                    WHERE Id = :asyncObjectId
                    AND Status__c = :Asynchronous.Status.QUEUED.name()
                    WITH USER_MODE
                    FOR UPDATE
            ];
        } catch(Exception exc) {
            if (exc.getMessage().startsWith('Record Currently Unavailable')) {
                return new List<Asynchronous__c>();
            } else {
                throw exc;
            }
        }
    }

    public Integer countScheduledJobs() {
        return [
                SELECT COUNT()
                FROM Asynchronous__c
                WHERE OwnerId = :UserInfo.getUserId()
                AND Status__c = :Asynchronous.Status.QUEUED.name()
                AND Runnable__c != :AsynchronousScheduler.class.getName()
                WITH USER_MODE
        ];
    }

    public Integer countActiveJobs(final Asynchronous__c asyncJob) {
        Assert.isNotNull(asyncJob, 'parameter; AsynchronousDAO.countActiveJobs.asyncJob');

        return [
                SELECT COUNT()
                FROM Asynchronous__c
                WHERE Runnable__c = :asyncJob.Runnable__c
                AND OwnerId = :UserInfo.getUserId()
                AND Status__c = :Asynchronous.Status.RUNNING.name()
                WITH USER_MODE
        ];
    }

    public List<Asynchronous__c> getScheduledJobs() {
        return [
                SELECT Id
                FROM Asynchronous__c
                WHERE ScheduledRunTime__c <= :Datetime.now()
                AND OwnerId = :UserInfo.getUserId()
                AND Runnable__c != :AsynchronousScheduler.class.getName()
                AND Status__c = :Asynchronous.Status.QUEUED.name()
                WITH USER_MODE
                ORDER BY ScheduledRunTime__c
                LIMIT 50
        ];
    }

    public void persistAsynchronous(final List<Asynchronous__c> asyncObjects, final List<Map<String, String>> states) {
        Assert.isNotNull(asyncObjects, 'parameter; AsynchronousDAO.persistAsynchronous.asyncObjects');
        Assert.isNotNull(states, 'parameter; AsynchronousDAO.persistAsynchronous.states');
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

    public void persistAsynchronous(final List<Asynchronous__c> asyncObjects) {
        Assert.isNotNull(asyncObjects, 'parameter; AsynchronousDAO.persistAsynchronous.asyncObjects');
        Database.upsert(asyncObjects, AccessLevel.USER_MODE);
    }

    public void removeAsynchronous(final List<Asynchronous__c> asynchronousObjects) {
        Assert.isNotNull(asynchronousObjects, 'parameter; AsynchronousDAO.removeAsynchronous.asynchronousObjects');
        Database.delete(asynchronousObjects, AccessLevel.USER_MODE);
    }

    public void persistAsynchronousError(AsynchronousError__c asyncError) {
        Assert.isNotNull(asyncError, 'parameter; AsynchronousDAO.removeAsynchronous.asyncError');
        Database.insert(asyncError, AccessLevel.USER_MODE);
    }

    public static Asynchronous__c get(final Id asyncObjectId) {
        return INSTANCE.getAsynchronous(asyncObjectId);
    }

    public static List<Asynchronous__c> lock(final Id asyncObjectId) {
        return INSTANCE.lockForExecution(asyncObjectId);
    }

    public static Integer countScheduled() {
        return INSTANCE.countScheduledJobs();
    }

    public static Integer countActive(final Asynchronous__c asyncJob) {
        return INSTANCE.countActiveJobs(asyncJob);
    }

    public static List<Asynchronous__c> getScheduled() {
        return INSTANCE.getScheduledJobs();
    }

    public static void persist(final List<Asynchronous__c> asyncObjects) {
        INSTANCE.persistAsynchronous(asyncObjects);
    }

    public static void persist(final List<Asynchronous__c> asyncObjects, final List<Map<String, String>> states) {
        INSTANCE.persistAsynchronous(asyncObjects, states);
    }

    public static void remove(final List<Asynchronous__c> asyncObjects) {
        INSTANCE.removeAsynchronous(asyncObjects);
    }

    public static void persist(AsynchronousError__c asyncError) {
        INSTANCE.persistAsynchronousError(asyncError);
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
}