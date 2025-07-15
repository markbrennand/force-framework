/**
 * @description
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../../LICENSE target="_blank">MIT License</a>.
 * <br><br>
 * Helper class providing common utility methods.
 *
 * @author Mark Brennand
 */
public with sharing class CommonHelper {

    /**
     * @description
     * Returns the namespace prefix for objects in the source code for the framework.
     *
     * @return The namespace of the objects, including the __.
     */
    public static String getSObjectNamespace() {
        return Binding__c.SObjectType.getDescribe().name.replace('Binding__c', '');
    }

    /**
     * @description
     * Returns the namespace prefix for Apex in the source code for the framework.
     *
     * @return The namespace of the Apex, including the .
     */
    public static String getApexNamespace() {
        return getSObjectNamespace().replace('__', '.');
    }
}