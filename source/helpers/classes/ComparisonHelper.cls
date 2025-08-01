/**
 * @description
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../../LICENSE target="_blank">MIT License</a>.
 * <br><br>
 * Helper class providing utility methods for object comparison.
 * <br><br>
 * If the objects are SObjects, or a Collection of SObjects, additional matching logic is applied. Fields of the
 * SObject being compared to the expected one must match all of those in the expected. Fields not defined in the
 * expected may be present in the one being compared.
 *
 * @author Mark Brennand
 */
public with sharing class ComparisonHelper {

    /**
     * @description
     * Default object value comparators
     *
     * Each comparator will be called in turn to try to match two objects.
     */
    private final static List<Comparator<Object>> COMPARATORS = new List<Comparator<Object>> {
            new SObjectComparator(),
            new ObjectComparator()
    };

    /**
     * @description
     * Compares two objects for equality.
     * <br><br>
     * A built in List of comparators is used to check. If a match is made by one of the comparators, the objects
     * are considered equal.
     *
     * @param expected The expect object.
     * @param actual The object to be compared.
     *
     * @return True of objects match.
     */
    public static Boolean compare(final Object expected, final Object actual) {
        return compare(new List<Comparator<Object>>(), expected, actual);
    }

    /**
     * @description
     * Compares two objects for equality using additional comparators.
     * <br><br>
     * The built in List of comparators is supplemented with the additional comparators. When checking for equality,
     * the additional comparators are used before the built ins.
     *
     * @param expected The expect object.
     * @param actual The object to be compared.
     * @param additionalComparators Additional comparators to use when checking for equality.
     *
     * @return True of objects match.
     */
    public static Boolean compare(final List<Comparator<Object>> additionalComparators, final Object expected, final Object actual) {
        final List<Comparator<Object>> allComparators = additionalComparators.clone();
        allComparators.addAll(COMPARATORS);

        if (expected instanceof Iterable<Object> && actual instanceof Iterable<Object>) {
            final Iterator<Object> expectedIter = ((Iterable<Object>) expected).iterator();
            final Iterator<Object> actualIter = ((Iterable<Object>) actual).iterator();

            while (expectedIter.hasNext()) {
                if (!actualIter.hasNext()) {
                    return false;
                }

                if (! compare(expectedIter.next(), actualIter.next())) {
                    return false;
                }
            }

            return !actualIter.hasNext();

        } else {
            for (Comparator<Object> comparator : allComparators) {
                if (comparator.compare(expected, actual) == 0) {
                    return true;
                }
            }

            return false;
        }
    }

    /**
     * @description
     * Compares two SObjects.
     * <br><br>
     * Fields of actualSObject must match all of those in expectedSObject. Fields not defined in expectedSObject
     * may be present in actualSObject.
     *
     * @param expectedSObject The expected SObject.
     * @param actualSObject The SObject to compare it with.
     *
     * @return True if the actual matches the expected.
     */
    private static Boolean compareSObjects(final SObject expectedSObject, final SObject actualSObject) {
        return new RequiredSObject(expectedSObject).equals(actualSObject);
    }

    /**
     * Utility class for comparing two SObjects.
     * <br><br>
     * The object being compared to the required object.
     * - must have field values identical to those set in the required object.
     * - may have values for fields that do not have a value in the required object.
     */
    private with sharing class RequiredSObject {
        private final SObject required;

        public RequiredSObject(final SObject required) {
            this.required = required;
        }

        public override Integer hashCode() {
            return super.hashCode();
        }

        public Boolean equals(final Object other) {
            if (other instanceof SObject) {
                final SObject match = (SObject) other;
                final Map<String, Object> requiredValues = required.getPopulatedFieldsAsMap();
                final Map<String, Object> otherValues = match.getPopulatedFieldsAsMap();

                for (String field : requiredValues.keySet()) {
                    if (requiredValues.get(field) != otherValues.get(field)) {
                        return false;
                    }
                }

                return true;
            } else {
                return false;
            }
        }
    }

    /**
     * @description
     * Comparator for two SObjects.
     */
    public with sharing class SObjectComparator implements Comparator<Object> {

        public Integer compare(final Object param1, final Object param2) {
            return param1 instanceof SObject && !(param1 instanceof Iterable<Object>) &&
                    param2 instanceof SObject && !(param2 instanceof Iterable<Object>) &&
                    compareSObjects((SObject) param1, (SObject) param2) ? 0 : -1;
        }
    }

    /**
     * @description
     * Default Comparator for two Objects.
     */
    private with sharing class ObjectComparator implements Comparator<Object> {
        public Integer compare(final Object param1, final Object param2) {
            try {
                return param1 == param2 ? 0 : -1;
            } catch(Exception e) {
                // Comparisons can throw some strange exceptions. So treat it as a failed match.
                return -1;
            }
        }
    }
}