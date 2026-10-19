/**
 * @description
 * <p>
 * Helper class providing common utility methods.
 * <p>
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../LICENSE target="_blank">MIT License</a>.
 *
 * @author Mark Brennand
 */
public with sharing class CommonHelper {

    /**
     * @description The name of the namespace when packaged.
     */
    public static final String NAMESPACE = 'forcefw';

    /**
     * @description
     * <p>
     * Mockable time.
     */
    @TestVisible
    @SuppressWarnings('PMD.FieldNamingConventions')
    private static Datetime NOW {
        private get {
            if (Test.isRunningTest() && NOW != null) {
                return NOW;
            } else {
                return Datetime.now();
            }
        }
        private set;
    }

    /**
     * @description
     * <p>
     * Returns the namespace prefix for objects in the source code for the framework.
     *
     * @return The namespace of the objects, including the __.
     */
    public static String getSObjectNamespace() {
        return Binding__c.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).name.replace('Binding__c', '');
    }

    /**
     * @description
     * <p>
     * Returns the namespace prefix for Apex in the source code for the framework.
     *
     * @return The namespace of the Apex, including the .
     */
    public static String getApexNamespace() {
        return getSObjectNamespace().replace('__', '.');
    }

    /**
     * @description
     * <p>
     * Returns the current date and time.
     * <p>
     * The value can be mocked in a unit test by setting the when variable.
     *
     * @return The current date time.
     */
    public static Datetime now() {
        return NOW != null ? NOW : Datetime.now();
    }

    /**
     * @description
     * <p>
     * Creates a new List of the same type as the source List.
     *
     * @param source The List giving the type to be created.
     *
     * @return A new List of the same type as the source.
     */
    public static List<Object> newListOfSameType(final List<Object> source) {
        final List<Object> cloned = source.clone();
        cloned.clear();
        return cloned;
    }

    /**
     * @description
     * <p>
     * Converts a collection element to its String equivalent.
     */
    public with sharing class ToString extends ArrayV1.Callback {

        /**
         * @description
         * <p>
         * Callback function to convert an element of a List to its String value and add it to a return List.
         *
         * @param element The element to convert to a String.
         * @param currentValue The List to return.
         * @param index The positional index of the element in the List.
         *
         * @return The List of Strings.
         */
        public override OptionalV1 function(final Object element, final OptionalV1 currentValue, final Integer index) {
            final Object collection = currentValue.get();
            if (collection instanceof List<String>) {
                ((List<String>) collection).add(element.toString());
            } else {
                ((Set<String>) collection).add(element.toString());
            }
            return currentValue;
        }
    }

    /**
     * @description
     * Adds elements of an Iterable of unknown type to a List of a specific type.
     */
    public with sharing class ToList implements OptionalV1.Function {
        private final List<Object> result;

        /**
         * @description
         * <p>
         * Constructor.
         *
         * @param result The List to add the elements to.
         */
        public ToList(final List<Object> result) {
            this.result = result;
        }

        /**
         * @description
         * <p>
         * Given an Optional containing a Collection, the elements in the Collection are added to the List.
         *
         * @param value An Optional containing the Collection of elements.
         *
         * @return An Optional containing a List built from the Collection's elements.
         */
        public OptionalV1 apply(final OptionalV1 value) {
            if (!value.isPresent()) {
                return value;
            }

            return OptionalV1.of(((ImmutableV1.Collection) value.get()).toList(result));
        }
    }
}