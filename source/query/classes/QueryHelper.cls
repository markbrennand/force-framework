/**
 * @description
 * <p>
 * Helper class providing utility methods for Query API.
 * <p>
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../LICENSE target="_blank">MIT License</a>.
 *
 * @author Mark Brennand
 */
public with sharing class QueryHelper {

    /**
     * @description
     * <p>
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
     * <p>
     * Callback class to get names of child relationships that match a specific SObject type.
     */
    public with sharing class GetRelationshipName extends ArrayV1.Callback {
        public override OptionalV1 function(final Object element, final OptionalV1 currentValue, final Integer index) {
            final ChildRelationship relationship = (ChildRelationship) element;

            if (relationship.childSObject == (SObjectType) shared().get()) {
                ((List<String>) currentValue.get()).add(relationship.getRelationshipName());
            }

            return currentValue;
        }
    }

    /**
     * @description
     * <p>
     * Converts fields to names.
     */
    public with sharing class FieldToString extends ArrayV1.Callback {
        public override OptionalV1 function(final Object element, final OptionalV1 currentValue, final Integer index) {
            ((Set<String>) currentValue.get()).add(((SObjectField) element).getDescribe().name);
            return currentValue;
        }
    }

    private with sharing class FieldJoiner extends ArrayV1.Callback {
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