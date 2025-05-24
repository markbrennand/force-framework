/**
 * @description
 * Helper class providing utility methods for object comparison.
 *
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
            new SObjectCollectionComparator(),
            new SObjectComparator(),
            new ObjectComparator()
    };

    /**
     * @description
     * Compares two objects for equality.
     *
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
     *
     * The built in List of comparators is supplemented with the additional comparators. When checking for equality,
     * the additional comparators are used before the built ins.
     *
     * @param expected The expect object.
     * @param actual The object to be compared.
     * @param additionalComparators Additional comparators to use when checking for equality.
     *
     * @return True of objects match.
     */
    public static Boolean compare(final List<Comparator<Object>> additionalComparators, Object expected, final Object actual) {
        final List<Comparator<Object>> allComparators = additionalComparators.clone();
        allComparators.addAll(COMPARATORS);

        for (Comparator<Object> comparator : allComparators) {
            if (comparator.compare(expected, actual) == 0) {
                return true;
            }
        }

        return false;
    }

    /**
     * @description
     * Compares two SObjects.
     *
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
     * @description
     * Compares two Iterables of SObjects.
     *
     * Fields of actualSObject must match all of those in expectedSObject. Fields not defined in expectedSObject
     * may be present in actualSObject.
     *
     * @param expectedSObjects The Iterable of expected SObjects.
     * @param actualSObjects The Iterable of SObjects to compare it with.
     *
     * @return True if the actual matches the expected.
     */
    private static Boolean compareSObjects(final Iterable<SObject> expectedSObjects, final Iterable<SObject> actualSObjects) {

        if (count(expectedSObjects) != count(actualSObjects)) {
            return false;
        }

        final Iterator<SObject> iter = actualSObjects.iterator();
        for (SObject expectedSObject : expectedSObjects) {
            if (!compareSObjects(expectedSObject, iter.next())) {
                return false;
            }
        }

        return true;
    }

    /**
     * @description
     * Counts the number of items in an iterable.
     *
     * @param iter The iterable to have its items counted.
     *
     * @return The number of items in the iterable.
     */
    private static Integer count(final Iterable<Object> iter) {
        Integer count = 0;

        for (Object next : iter) {
            count++;
        }

        return count;
    }

    /**
     * Utility class for comparing two SObjects.
     *
     * The object being compared to the required object.
     * - must have field values identical to those set in the required object.
     * - may have values for fields that do not have a value in the required object.
     */
    private with sharing class RequiredSObject {
        private final SObject required;

        public RequiredSObject(final SObject required) {
            this.required = required;
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
            return (param1 instanceof SObject && (!(param1 instanceof List<SObject>) && !(param1 instanceof Set<SObject>)))
                && (param2 instanceof SObject && (!(param2 instanceof List<SObject>) && !(param2 instanceof Set<SObject>)))
                && compareSObjects((SObject) param1, (SObject) param2) ? 0 : -1;
        }
    }

    /**
     * @description
     * Comparator for two collections of SObjects.
     */
    public with sharing class SObjectCollectionComparator implements Comparator<Object> {

        public Integer compare(final Object param1, final Object param2) {

            return (param1 instanceof List<SObject> || param1 instanceof Set<SObject>)
                    && (param2 instanceof List<SObject> || param2 instanceof Set<SObject>)
                    && compareSObjects((Iterable<SObject>) param1, (Iterable<SObject>) param2) ? 0 : -1;
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