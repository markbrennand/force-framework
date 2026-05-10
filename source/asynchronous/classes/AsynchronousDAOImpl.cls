/**
 * @description
 * <p>
 * Implementation of Asynchronous DAO.
 * <p>
 * Implementation class is private to prevent re-use.
 * <p>
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../LICENSE target="_blank">MIT License</a>.
 * 
 * @author Mark Brennand
 */
public with sharing class AsynchronousDAOImpl {

    /**
     * @description
     * <p>
     * Class providing the implementation of the API.
     */
    private with sharing class API implements AsynchronousDAO.API {

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
            return ((AsynchronousJob__c) ((ImmutableV1.Collection) matches.get()).get(0));
        }

        /**
         * @description
         * <p>
         * Builds a List of the AsynchronousJob__c objects that are scheduled to run.
         * <p>
         * The AsynchronousJob__c objects are ordered by ScheduledRunTime__c. This ensures that the list returned
         * is in chronological order, with the first entry being the job that has been waiting the longest to run.
         * <p>
         * Any queued Sweeper job(s) must take priority over others.
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
         * Builds a List of the objects that can be swept.
         * <p>
         * A sweepable object is one that has been running or finalizing for more than the given number of seconds.
         * This situation occurs occasionally when the Finalizer for the Apex Job is not run by Salesforce.
         * <p>
         * The List returned must be ordered chronologically, with the first entry being the job that has been
         * waiting the longest to run.
         *
         * @param maxJobsToReturn The maximum number of objects to return.
         * @param windowSize The number of seconds in the past before which the sweepable job must have been run.
         *
         * @return The objects.
         */
        public List<AsynchronousJob__c> getSweepableObjects(final Integer maxJobsToReturn, final Integer windowSize) {
            final Map<String, AsynchronousJob__c> jobMap = (Map<String, AsynchronousJob__c>) QueryV1.of(AsynchronousJob__c.SObjectType)
                    .security(AccessLevel.SYSTEM_MODE)
                    .returning(new Set<SObjectField>{
                            AsynchronousJob__c.Id,
                            AsynchronousJob__c.ApexJobId__c,
                            AsynchronousJob__c.Runnable__c,
                            AsynchronousJob__c.ApexJobId__c,
                            AsynchronousJob__c.Status__c,
                            AsynchronousJob__c.RetryNumber__c
                    })
                    .matching('OwnerId = :ownerId AND Status__c IN :activeStatuses AND LastRunTime__c != null AND LastRunTime__c < :windowStart')
                    .bindings(new Map<String, Object>{
                            'ownerId' => UserInfo.getUserId(),
                            'activeStatuses' => new Set<String>{
                                    AsynchronousV1.Status.RUNNING.name(),
                                    AsynchronousV1.Status.FINALIZING.name()
                            },
                            'windowStart' => CommonHelper.now().addSeconds(-windowSize)
                    })
                    .max(maxJobsToReturn)
                    .execute()
                    .collection(new List<AsynchronousJob__c>())
                    .reduce(new MapAsynchronousJobToApexJob(), new Map<String, AsynchronousJob__c>());

            final ImmutableV1.Collection apexJobs = QueryV1.of(AsyncApexJob.SObjectType)
                    .security(AccessLevel.SYSTEM_MODE)
                    .returning(AsyncApexJob.Id)
                    .matching('Id IN :jobIds AND Status IN :activeStatuses')
                    .bindings(new Map<String, Object> {
                            'jobIds' => jobMap.keySet(),
                            'activeStatuses' => new Set<String> { 'Queued', 'Processing'}
                    })
                    .execute()
                    .collection(new List<AsyncApexJob>());

            return (List<AsynchronousJob__c>)
                    ((Map<String, AsynchronousJob__c>) apexJobs.reduce(new RemoveActiveApexJobs(), jobMap)).values();
        }

        /**
         * @description
         * <p>
         * Determines the number os AsynchronousJob__c objects that remain to be run.
         * <p>
         * The AsynchronousJob__c objects are queried by QUEUED and RUNNING status.
         *
         * @param maximumToCount The maximum number of jobs to include in the count.
         * @param activeWindowSize The number of seconds in the past before which a running or finalizing job should
         * not be included in the count.
         *
         * @return The number of objects that are scheduled or are running.
         */
        public Integer countSchedulableObjects(final Integer maximumToCount, final Integer activeWindowSize) {
            return (Integer) QueryV1.count(AsynchronousJob__c.SObjectType)
                    .security(AccessLevel.USER_MODE)
                    .matching(
                            'OwnerId = :ownerId AND Runnable__c != :schedulerClass' +
                                    + ' AND (Status__c = :queuedStatus '
                                    + '      OR (LastRunTime__c >= :windowStart AND Status__c IN :activeStatuses)' +
                                    ')')
                    .bindings(new Map<String, Object> {
                            'ownerId' => UserInfo.getUserId(),
                            'queuedStatus' => AsynchronousV1.Status.QUEUED.name(),
                            'activeStatuses' => new Set<String> {
                                    AsynchronousV1.Status.RUNNING.name(),
                                    AsynchronousV1.Status.FINALIZING.name()
                            },
                            'windowStart' => CommonHelper.now().addSeconds(-activeWindowSize),
                            'schedulerClass' => AsynchronousScheduler.RunNextAvailable.class.getName()
                    })
                    .max(maximumToCount)
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
         * @param activeWindowSize The number of seconds in the past before which a running or finalizing job should
         * not be included in the count.
         *
         * @return The concurrency for the object.
         */
        public Integer countActiveObjects(final AsynchronousJob__c asyncObject, final Integer activeWindowSize) {
            AssertionV1.isNotNull(asyncObject, 'argument: AsynchronousDAO.apiCountActiveObjects.asyncObject');

            return (Integer) QueryV1.count(AsynchronousJob__c.SObjectType)
                    .security(AccessLevel.USER_MODE)
                    .matching('OwnerId = :ownerId AND LastRunTime__c >= :windowStart AND Runnable__c = :runnableClass AND Status__c IN :runningStatuses')
                    .bindings(new Map<String, Object> {
                            'ownerId' => UserInfo.getUserId(),
                            'runnableClass' => asyncObject.Runnable__c,
                            'runningStatuses' => new Set<String> {
                                    AsynchronousV1.Status.RUNNING.name(),
                                    AsynchronousV1.Status.FINALIZING.name()
                            },
                            'windowStart' => CommonHelper.now().addSeconds(-activeWindowSize)
                    })
                    .execute()
                    .orElse(0);
        }

        /**
         * @description
         * <p>
         * Determines the time at which the Scheduler is next due to be active.
         * <p>
         * If there are running or finalizing jobs, this will be the time at which the first job was started.
         *
         * @param activeWindowSize The number of seconds in the past before which a running or finalizing job should
         * not be included in the count.
         *
         * @return The concurrency for the object.
         */
        public Datetime getWhenNextRequired(final Integer activeWindowSize) {
            final OptionalV1 firstRunningJob = QueryV1.of(AsynchronousJob__c.SObjectType)
                    .returning(QueryV1.aggregatedField('MIN', AsynchronousJob__c.LastRunTime__c, 'lastRunTime'))
                    .matching('Status__c IN :activeStatuses AND LastRuntime__c >= :activeWindow AND Runnable__c != :schedulerClass')
                    .bindings(new Map<String, Object> {
                            'activeStatuses' => new Set<String> {
                                    AsynchronousV1.Status.RUNNING.name(),
                                    AsynchronousV1.Status.FINALIZING.name()
                            },
                            'activeWindow' => CommonHelper.now().addSeconds(-activeWindowSize),
                            'schedulerClass' => AsynchronousScheduler.RunNextAvailable.class.getName()
                    })
                    .execute();

            final Datetime lastRunTime = (Datetime)
                    ((AggregateResult) ((ImmutableV1.Collection) firstRunningJob.get()).get(0)).get('lastRunTime');

            if (lastRunTime != null) {
                return lastRunTime;
            }

            final OptionalV1 nextScheduledJob = QueryV1.of(AsynchronousJob__c.SObjectType)
                    .returning(QueryV1.aggregatedField('MIN', AsynchronousJob__c.ScheduledRunTime__c, 'scheduledRunTime'))
                    .matching('Status__c = :queuedStatus AND Runnable__c != :schedulerClass')
                    .bindings(new Map<String, Object> {
                            'queuedStatus' => AsynchronousV1.Status.QUEUED.name(),
                            'schedulerClass' => AsynchronousScheduler.RunNextAvailable.class.getName()
                    })
                    .execute();

            final Datetime scheduledRunTime = (Datetime)
                    ((AggregateResult) ((ImmutableV1.Collection) nextScheduledJob.get()).get(0)).get('scheduledRunTime');

            return scheduledRunTime != null ? scheduledRunTime : CommonHelper.now().addDays(1);
        }

        /**
         * @description
         * <p>
         * Inserts or updates the given AsynchronousJob__c objects.
         *
         * @param asyncObjects The objects to persist.
         * @param withTrigger Is trigger on asynchronous job object to fire.
         */
        public void persistObjects(final List<AsynchronousJob__c> asyncObjects, final Boolean withTrigger) {
            AssertionV1.isNotNull(asyncObjects, 'argument: AsynchronousDAO.apiPersistAsynchronous.asyncObjects');

            final Boolean subscriberEnabled = TriggerV1.isEnabled(AsynchronousJob__c.SObjectType);

            if (withTrigger) {
                TriggerV1.enable(AsynchronousJob__c.SObjectType);
            } else {
                TriggerV1.disable(AsynchronousJob__c.SObjectType);
            }

            try {
                Database.upsert(asyncObjects, AccessLevel.USER_MODE);
            } finally {
                if (subscriberEnabled) {
                    TriggerV1.enable(AsynchronousJob__c.SObjectType);
                } else {
                    TriggerV1.disable(AsynchronousJob__c.SObjectType);
                }
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

            final Boolean subscriberEnabled = TriggerV1.isEnabled(AsynchronousJob__c.SObjectType);
            TriggerV1.enable(AsynchronousJob__c.SObjectType);

            try {
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
                        .then(new SObjectHelper.Deleter(AccessLevel.USER_MODE));

                Database.upsert(newStates, AccessLevel.USER_MODE);
            } finally {
                if (!subscriberEnabled) {
                    TriggerV1.disable(AsynchronousJob__c.SObjectType);
                }
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
     * Creates the default Asynchronous DAO implementation.
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

    /**
     * @description
     * <p>
     *
     * Maps each AsynchronousJob__c record to its AsyncApexJob Id key.
     * <p>
     * This callback is used during a reduction over a collection of AsynchronousJob__c
     * records to build a Map<String, AsynchronousJob__c> where the key is the
     * AsynchronousJob__c.ApexJobId__c and the value is the corresponding job record.
     * <p>
     * This facilitates subsequent filtering by removing entries that still have an
     * active AsyncApexJob, leaving only orphaned/runnable jobs for sweeping.
     */
    private with sharing class MapAsynchronousJobToApexJob extends ArrayV1.Callback {
        public override OptionalV1 function(Object element, OptionalV1 currentValue, Integer index) {
            final AsynchronousJob__c job = (AsynchronousJob__c) element;
            final Map<String, AsynchronousJob__c> jobMap = (Map<String, AsynchronousJob__c>) currentValue.get();
            jobMap.put(job.ApexJobId__c, job);
            return OptionalV1.of(jobMap);
        }
    }

    /**
     * @description
     * <p>
     * Removes entries from a Map<String, AsynchronousJob__c> for which an active AsyncApexJob
     * record is still present. This callback is intended to be used in a reduction over a
     * collection of AsyncApexJob records to filter out AsynchronousJob__c entries that are
     * still actively queued or processing in the platform.
     * <p>
     * After reduction, the map contains only AsynchronousJob__c records that do not have a
     * corresponding active AsyncApexJob, i.e., candidates for sweeping.
     */
    private with sharing class RemoveActiveApexJobs extends ArrayV1.Callback {
        public override OptionalV1 function(Object element, OptionalV1 currentValue, Integer index) {
            final AsyncApexJob apexJob = (AsyncApexJob) element;
            final Map<String, AsynchronousJob__c> jobMap = (Map<String, AsynchronousJob__c>) currentValue.get();
            jobMap.remove(apexJob.Id);
            return OptionalV1.of(jobMap);
        }
    }
}