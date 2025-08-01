/**
 * @description
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../../LICENSE target="_blank">MIT License</a>.
 * <br><br>
 * Helper class providing utility methods for Query API.
 *
 * @author Mark Brennand
 */
public with sharing class QueryHelper {

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

    private with sharing class FieldJoiner extends ArrayV1.Callback {

        public override OptionalV1 function(Object element, OptionalV1 currentValue, Integer index) {
            final String relationshipName = (String) shared().get();
            final Set<String> fields = (Set<String>) currentValue.get();
            final SObjectField field = (SObjectField) element;

            fields.add((String) ArrayV1.over(new List<String> { relationshipName, field.getDescribe().getName() })
                    .join('.'));

            return OptionalV1.of(fields);
        }
    }

    public with sharing class SObjectDeleter implements OptionalV1.Function {
        private final AccessLevel mode;

        public SObjectDeleter(final AccessLevel mode) {
            this.mode = mode;
        }

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
            if (!value.isPresent()) {
                return OptionalV1.of(new List<SObject>());
            }

            final List<SObject> toUpdate = (List<SObject>) ArrayV1.over(value.get()).transform(callback, new List<SObject>());
            Database.update(toUpdate, mode);
            return OptionalV1.of(toUpdate);
        }
    }
}