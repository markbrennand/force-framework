/**
 * @description
 * <p>
 * Helper class for Trigger API.
 * <p>
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../LICENSE target="_blank">MIT License</a>.
 * 
 * @author Mark Brennand
 */
public with sharing class TriggerHelper {

    /**
     * @description
     * <p>
     * Determines whether the subscriber defined by a trigger definition is bound to receive the event for the
     * current trigger action.
     *
     * @param triggerDefinition The trigger definition to check.
     * @param operation The operation being performed.
     * @param isBefore True if trigger before action is being called.
     *
     * @return True if the subscriber is bound the action.
     */
    public static Boolean isSubscriberBoundToAction(
            final Trigger__mdt triggerDefinition,
            final TriggerV1.Operation operation,
            final Boolean isBefore)
    {
        switch on operation {
            when INSERTING {
                return isBefore ? triggerDefinition.BeforeInsert__c : triggerDefinition.AfterInsert__c;
            }
            when UPDATING {
                return isBefore ? triggerDefinition.BeforeUpdate__c : triggerDefinition.AfterUpdate__c;
            }
            when DELETING {
                return isBefore ? triggerDefinition.BeforeDelete__c : triggerDefinition.AfterDelete__c;
            }
        }
        return false;
    }

    /**
     * @description
     * <p>
     * Builds the Map of object name to its associated Trigger metadata records.
     */
    public with sharing class TriggerDefinitionMapBuilder extends ArrayV1.Callback {
        public override OptionalV1 function(final Object element, final OptionalV1 currentValue, final Integer index) {
            final Map<String, List<Trigger__mdt>> triggerDefinitions = (Map<String, List<Trigger__mdt>>) currentValue.get();
            final Trigger__mdt triggerDefinition  = (Trigger__mdt) element;
            final String objectName = getObjectName(triggerDefinition.ObjectName__c);

            if (triggerDefinitions.containsKey(objectName)) {
                triggerDefinitions.get(objectName).add(triggerDefinition);
            } else {
                triggerDefinitions.put(objectName, new List<Trigger__mdt> { triggerDefinition });
            }

            return OptionalV1.of(triggerDefinitions);
        }

        private String getObjectName(final String name) {
            return String.isEmpty(CommonHelper.getSObjectNamespace())
                    ? name.replace(CommonHelper.NAMESPACE + '__', '') : name;
        }

    }
}