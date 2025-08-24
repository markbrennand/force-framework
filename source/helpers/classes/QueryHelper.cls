/**
 * @description
 * <p/>
 * Helper class providing utility methods for Query API.
 * <p/>
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../LICENSE target="_blank">MIT License</a>.
 *
 * @author Mark Brennand
 */
public with sharing class QueryHelper {

    /**
     * @description
     * <p/>
     * Builds the fully qualified names of the fields to be returned in a query from a related object.
     *
     * @param joinField The Id field that links to the related object.
     * @param fields The names of the fields to be returned from the related object.
     *
     * @return The fully qualified field names to be returned.
     */
    public static Set<String> buildJoinFields(final SObjectField joinField, final Set<SObjectField> fields) {
        final String relationshipName = joinField.getDescribe().getRelationshipName();
        if (relationshipName == null) {
            throw new QueryException('Join field must be the Id field of the SObject to join');
        }

        return (Set<String>) ArrayV1.over(fields).sharing(relationshipName).reduce(
                new FieldJoiner(),
                new Set<String>()
        );
    }

    /**
     * @description
     * <p/>
     * Function called from an Optional to delete objects.
     */
    public with sharing class SObjectDeleter implements OptionalV1.Function {
        private final AccessLevel mode;

        /**
         * @description
         * <p/>
         * Constructs an instance of the class to delete objects in the given mode
         *
         * @param mode The access mode to delete the objects in.
         */
        public SObjectDeleter(final AccessLevel mode) {
            this.mode = mode;
        }

        /**
         * @description
         * <p/>
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

    public with sharing class SObjectTransformAndUpdate implements OptionalV1.Function {
        private final ArrayV1.Callback callback;
        private final AccessLevel mode;

        public SObjectTransformAndUpdate(final ArrayV1.Callback callback, final AccessLevel mode) {
            this.callback = callback;
            this.mode = mode;
        }

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

    private with sharing class FieldJoiner extends ArrayV1.Callback {

        @SuppressWarnings('PMD.EmptyStatementBlock')
        public FieldJoiner() {}

        public override OptionalV1 function(final Object element, final OptionalV1 currentValue, final Integer index) {
            final String relationshipName = (String) shared().get();
            final Set<String> fields = (Set<String>) currentValue.get();
            final SObjectField field = (SObjectField) element;

            fields.add((String) ArrayV1.over(new List<String> { relationshipName, field.getDescribe().getName() })
                    .join('.'));

            return OptionalV1.of(fields);
        }
    }
}