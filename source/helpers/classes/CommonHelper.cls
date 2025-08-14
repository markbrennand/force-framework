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
     * @description
     * <p>
     * Mockable time.
     */
    @TestVisible
    @SuppressWarnings('PMD.FieldNamingConventions')
    private static Datetime NOW;

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
     * Converts a List element to its String equivalent.
     */
    public with sharing class ToString extends ArrayV1.Callback {
        public override OptionalV1 function(Object element, OptionalV1 currentValue, Integer index) {
            final Object collection = currentValue.get();
            if (collection instanceof List<String>) {
                ((List<String>) collection).add(element.toString());
            } else {
                ((Set<String>) collection).add(element.toString());
            }
            return currentValue;
        }
    }
}