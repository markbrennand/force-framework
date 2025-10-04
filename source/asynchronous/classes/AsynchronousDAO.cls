
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
public with sharing virtual class AsynchronousDAO extends AsynchronousDAOMockable {

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
     * Allow extension but not construction.
     * <p>
     * This is also required to support the Apex mocking classes. A private constructor cannot be mocked.
     */
    @SuppressWarnings('PMD.EmptyStatementBlock')
    protected AsynchronousDAO() {}

    // Set the default implementation of the API. This can be overridden using a Dependency Binding.
    static {
        DependencyV1.bind(API.class, AsynchronousDAOImpl.Factory.class);
    }
}