/**
 * MIT License
 *
 * Copyright (c) 2025 Mark Brennand
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */
/**
 * @description
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
public with sharing virtual class AsynchronousDAO implements Asynchronous.DAO {

    /**
     * @description
     * Active API instance.
     *
     * The instance is injected from the Registry.
     */
    @TestVisible
    public static Asynchronous.DAO API {
        public get {
            if (Test.isRunningTest() && API != null) { // API has been mocked.
                return API;
            } else {
                return (Asynchronous.DAO) DependencyV1.inject(Asynchronous.DAO.class);
            }
        }
        private set;
    }

    protected AsynchronousDAO() {}

    /**
     * @description
     * Class providing the implementation of the API.
     */
    private with sharing class Implementation implements Asynchronous.DAO {

        /**
         * @description
         * Given the Id of the AsynchronousJob__c object, the object is retrieved.
         *
         * @param asyncObjectId The Id of the object to retrieve.
         *
         * @return The object.
         */
        public AsynchronousJob__c getObject(Id asyncObjectId) {
            Assertion.isNotNull(asyncObjectId, 'argument: AsynchronousDAO.apiGetObject.asyncObjectId');

            final List<AsynchronousJob__c> asyncObjects = [
                    SELECT Id, OwnerId, Status__c, Reference__c, Runnable__c, MaximumRetries__c, RetryInterval__c,
                            RetryNumber__c, ScheduledRunTime__c, LastRunTime__c, ApexJobId__c,
                    (SELECT Content__c FROM AsynchronousJobState__r ORDER BY ChunkNumber__c)
                    FROM AsynchronousJob__c
                    WHERE Id = :asyncObjectId
                    WITH USER_MODE
                    LIMIT 1
            ];

            Assertion.areEqual(1, asyncObjects.size(), 'Asynchronous object with Id ' + asyncObjectId + ' not found');

            return asyncObjects[0];
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
        public Set<AsynchronousJob__c> getScheduledObjects(final Integer maxJobsToReturn) {
            return new Set<AsynchronousJob__c>([
                    SELECT Id, Runnable__c
                    FROM AsynchronousJob__c
                    WHERE OwnerId = :UserInfo.getUserId()
                    AND ScheduledRunTime__c <= :Datetime.now()
                    AND Runnable__c != :AsynchronousScheduler.RunNextAvailable.class.getName()
                    AND Status__c = :Asynchronous.Status.QUEUED.name()
                    WITH USER_MODE
                    ORDER BY ScheduledRunTime__c
                    LIMIT :maxJobsToReturn
            ]);
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
            final Set<String> SCHEDULABLE_STATUSES = new Set<String> {
                    Asynchronous.Status.QUEUED.name(),
                    Asynchronous.Status.RUNNING.name()
            };

            return [
                    SELECT COUNT()
                    FROM AsynchronousJob__c
                    WHERE OwnerId = :UserInfo.getUserId()
                    AND Status__c IN :SCHEDULABLE_STATUSES
                    AND Runnable__c != :AsynchronousScheduler.RunNextAvailable.class.getName()
                    WITH USER_MODE
            ];
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
            Assertion.isNotNull(asyncObject, 'argument: AsynchronousDAO.apiCountActiveObjects.asyncObject');

            return [
                    SELECT COUNT()
                    FROM AsynchronousJob__c
                    WHERE OwnerId = :UserInfo.getUserId()
                    AND Runnable__c = :asyncObject.Runnable__c
                    AND Status__c = :Asynchronous.Status.RUNNING.name()
                    WITH USER_MODE
            ];
        }

        /**
         * @description
         * Inserts or updates the given AsynchronousJob__c objects.
         *
         * @param asyncObjects The objects to persist.
         */
        public void persistObjects(final List<AsynchronousJob__c> asyncObjects) {
            Assertion.isNotNull(asyncObjects, 'argument: AsynchronousDAO.apiPersistAsynchronous.asyncObjects');

            final Boolean savedSkipTriggers = AsynchronousAPI.skipTriggers;

            AsynchronousAPI.skipTriggers = true;
            Database.upsert(asyncObjects, AccessLevel.USER_MODE);
            AsynchronousAPI.skipTriggers = savedSkipTriggers;
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
            Assertion.isNotNull(asyncObjects, 'argument: AsynchronousDAO.apiPersistAsynchronous.asyncObjects');
            Assertion.isNotNull(states, 'argument: AsynchronousDAO.apiPersistAsynchronous.states');
            Assertion.areEqual(asyncObjects.size(), states.size(), 'The number of Asynchronous objects does not match the number of states');

            final Boolean savedSkipTriggers = AsynchronousAPI.skipTriggers;

            AsynchronousAPI.skipTriggers = false;
            Database.upsert(asyncObjects, AccessLevel.USER_MODE);

            final Set<Id> allIds = new Set<Id>();
            final List<AsynchronousJobState__c> newStates = new List<AsynchronousJobState__c>();
            for (Integer i = 0; i < asyncObjects.size(); i++) {
                final AsynchronousJob__c asynchronousObject = asyncObjects[i];
                allIds.add(asynchronousObject.Id);
                newStates.addAll(AsynchronousHelper.API.encodeState(asynchronousObject, states[i]));
            }

            Database.delete(
                    [SELECT Id FROM AsynchronousJobState__c WHERE AsynchronousJob__c IN :allIds WITH USER_MODE],
                    AccessLevel.USER_MODE
            );

            Database.upsert(newStates, AccessLevel.USER_MODE);

            AsynchronousAPI.skipTriggers = savedSkipTriggers;
        }

        /**
         * @description
         * Deletes the given AsynchronousJob__c objects.
         *
         * @param asyncObjects The objects to remove.
         */
        public void removeObjects(final List<AsynchronousJob__c> asyncObjects) {
            Assertion.isNotNull(asyncObjects, 'argument: AsynchronousDAO.apiRemoveAsynchronous.asynchronousObjects');
            Database.delete(asyncObjects, AccessLevel.USER_MODE);
        }

        /**
         * @description
         * Inserts the given AsynchronousJobException__c object.
         *
         * @param asyncErrorObject The exception object to persist.
         */
        public void persistException(AsynchronousJobException__c asyncErrorObject) {
            Assertion.isNotNull(asyncErrorObject, 'argument: AsynchronousDAO.apiPersistAsynchronousError.asyncErrorObject');
            Database.insert(asyncErrorObject, AccessLevel.USER_MODE);
        }
    }

    /**
     * @description
     * Method is solely for mocking use.
     */
    public AsynchronousJob__c getObject(final Id asyncObjectId) {
        throw new Asynchronous.APIException('Access denied');
    }

    /**
     * @description
     * Method is solely for mocking use.
     */
    public Set<AsynchronousJob__c> getScheduledObjects(final Integer maxJobsToReturn) {
        throw new Asynchronous.APIException('Access denied');
    }

    /**
     * @description
     * Method is solely for mocking use.
     */
    public Integer countSchedulableObjects() {
        throw new Asynchronous.APIException('Access denied');
    }

    /**
     * @description
     * Method is solely for mocking use.
     */
    public Integer countActiveObjects(final AsynchronousJob__c asyncJob) {
        throw new Asynchronous.APIException('Access denied');
    }

    /**
     * @description
     * Method is solely for mocking use.
     */
    public void persistObjects(final List<AsynchronousJob__c> asyncObjects) {
        throw new Asynchronous.APIException('Access denied');
    }

    /**
     * @description
     * Method is solely for mocking use.
     */
    public void persistObjects(final List<AsynchronousJob__c> asyncObjects, final List<Map<String, String>> states) {
        throw new Asynchronous.APIException('Access denied');
    }

    /**
     * @description
     * Method is solely for mocking use.
     */
    public void removeObjects(final List<AsynchronousJob__c> asyncObjects) {
        throw new Asynchronous.APIException('Access denied');
    }

    /**
     * @description
     * Method is solely for mocking use.
     */
    public void persistException(AsynchronousJobException__c asyncError) {
        throw new Asynchronous.APIException('Access denied');
    }

    /**
     * @description
     * Creates the default API implementation.
     *
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
            if (TypesV1.newInstance(withImpl) instanceof Asynchronous.DAO) {
                return new Dependency.ValidationResult(true, null);
            } else {
                return new Dependency.ValidationResult(
                        false,
                        'Class ' + withImpl.getName() + ' does not implement ' + forType.getName()
                );
            }
        }
    }


    // Set the default implementation of the API. This can be overridden using a Dependency Binding.
    static {
        DependencyV1.bind(Asynchronous.DAO.class, Factory.class);
    }
}
