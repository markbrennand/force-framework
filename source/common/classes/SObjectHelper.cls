/**
 * @description
 * <p>
 * Helper class for SObject oprerations.
 * <p>
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../LICENSE target="_blank">MIT License</a>.
 * 
 * @author Mark Brennand
 */
public with sharing class SObjectHelper {

    /**
     * @description
     * <p>
     * Function called from an Optional to delete objects.
     */
    public with sharing class Deleter implements OptionalV1.Function {
        private final AccessLevel mode;

        /**
         * @description
         * <p>
         * Constructs an instance of the class to delete objects in the given mode
         *
         * @param mode The access mode to delete the objects in.
         */
        public Deleter(final AccessLevel mode) {
            this.mode = mode;
        }

        /**
         * @description
         * <p>
         * Deletes the objects given by the Optional value.
         *
         * @param value The Optional containing the objects to delete.
         *
         * @return The Optional passed in as argument.
         */
        @SuppressWarnings('PMD.ApexCRUDViolation')
        public OptionalV1 apply(final OptionalV1 value) {
            if (!value.isPresent()) {
                return OptionalV1.of(new List<SObject>());
            }

            final List<SObject> toDelete = (List<SObject>) value.get();
            Database.delete(toDelete, mode);
            return OptionalV1.of(toDelete);
        }
    }

    /**
     * @description
     * <p>
     * Performs the given transformation on an object before updating in the database.
     */
    public with sharing class Transformer implements OptionalV1.Function {
        private final ArrayV1.Callback callback;
        private final AccessLevel mode;

        /**
         * @description
         * Creates an instance of the class for the give transformer.
         * @param callback The transformer.
         * @param mode Mode to perform tghe database update in.
         */
        public Transformer(final ArrayV1.Callback callback, final AccessLevel mode) {
            this.callback = callback;
            this.mode = mode;
        }

        /**
         * @description
         * <p>
         * Transforms the data in the Optional and updates in database.
         *
         * @param value The Optional to be transformed.
         *
         * @return Unused.
         */
        @SuppressWarnings('PMD.ApexCRUDViolation')
        public OptionalV1 apply(final OptionalV1 value) {
            if (value.isPresent()) {
                final List<SObject> toUpdate = (List<SObject>) ArrayV1.over(value.get()).transform(callback, new List<SObject>());
                Database.update(toUpdate, mode);
                return OptionalV1.of(toUpdate);
            }

            return OptionalV1.empty();
        }
    }
}