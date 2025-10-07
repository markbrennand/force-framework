/**
 * @description
 * <p>
 * Class providing implementation of Trigger Event.
 * <p>
 * The implementation  class is private to prevent re-use.
 * <p>
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../LICENSE target="_blank">MIT License</a>.
 * 
 * @author Mark Brennand
 */
public with sharing class TriggerEvent {


    /**
     * @description
     * <p>
     * Implementation of the Event interface.
     */
    private with sharing class Event implements TriggerV1.Event {
        private final ImmutableV1.Collection records;
        private final OptionalV1 oldRecords;
        private final Boolean isBefore;
        private final TriggerV1.Operation operation;
        private final Integer recursiveDepth;

        /**
         * @description
         * <p>
         * Constructs an event representing the DML operation.
         *
         * @param records The new values for the records resulting from the DML.
         * @param oldRecords  The original values for the records prior to the DML.
         * @param isBefore If true, the event is for the DML operation prior to persisting the data.
         * @param operation The DML operation being performed.
         * @param recursiveDepth The number of times the trigger has been invoked as a result of the top level DML.
         */
        public Event(
                final List<SObject> records,
                final OptionalV1 oldRecords,
                final Boolean isBefore,
                final TriggerV1.Operation operation,
                final Integer recursiveDepth
        ) {
            this.records =  ImmutableV1.of(records);
            this.oldRecords = oldRecords;
            this.isBefore = isBefore;
            this.operation  = operation;
            this.recursiveDepth = recursiveDepth;
        }

        /**
         * @description
         * <p>
         * Is a before operation being performed.
         *
         * @return True if Event represents a before operation.
         */
        public Boolean isBefore() {
            return isBefore;
        }

        /**
         * @description
         * <p>
         * Is an after operation being performed.
         *
         * @return True if Event represents aa after operation.
         */
        public Boolean isAfter() {
            return !isBefore();
        }

        /**
         * @description
         * <p>
         * The type of DML operation being performed.
         *
         * @return The operation being performed.
         */
        public TriggerV1.Operation getOperation() {
            return operation;
        }

        /**
         * @description
         * <p>
         * The objects the DML operation is being performed on.
         *
         * @return An immutable list of the objects the DML operation is being performed on.
         */
        public ImmutableV1.Collection getRecords() {
            return records;
        }

        /**
         * @description
         * <p>
         * Tests whether the given object has a previous value.
         * <p>
         * This method will only return true for a DML update.
         *
         * @param record The object to check.
         *
         * @return True if the object has a previous value.
         */
        public Boolean hasOldValue(final SObject record) {
            return oldRecords.isPresent() && ((ImmutableV1.ReadOnlyMap) oldRecords.get()).containsKey(record.Id);
        }

        /**
         * @description
         * <p>
         * Gets the original value of a record being updated.
         *
         * @param record The object to get the previous value of.
         *
         * @return The previous value of the object or an optional representing undefined.
         */
        public OptionalV1 getOldValue(final SObject record) {
            return oldRecords.isPresent()
                    ? OptionalV1.ofNullable(((ImmutableV1.ReadOnlyMap) oldRecords.get()).get(record.Id))
                    : OptionalV1.empty();
        }

        /**
         * @description
         * <p>
         * Gets the values of the records prior to update.
         *
         * @return An immutable map of the old record values, or an optional representing undefined.
         */
        public OptionalV1 getOldValues() {
            return oldRecords;
        }

        /**
         * @description
         * <p>
         * Gets the number of times the trigger has been called within the scope of the top level trigger invocation.
         *
         * @return The recursive depth.
         */
        public Integer getRecursiveDepth() {
            return recursiveDepth;
        }
    }

    /**
     * @description
     * <p>
     * Creates a new Event.
     *
     * @param records The new values for the records resulting from the DML.
     * @param oldRecords  The original values for the records prior to the DML.
     * @param isBefore If true, the event is for the DML operation prior to persisting the data.
     * @param operation The DML operation being performed.
     * @param recursiveDepth The number of times the trigger has been invoked as a result of the top level DML.
     *
     * @return The new Event.
     */
    public static TriggerV1.Event newEvent(
            final List<SObject> records,
            final OptionalV1 oldRecords,
            final Boolean isBefore,
            final TriggerV1.Operation operation,
            final Integer recursiveDepth
    ) {
        return new Event(records, oldRecords, isBefore, operation, recursiveDepth);
    }
}