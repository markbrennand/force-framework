/**
 * @description
 * <p>
 * Helper class for unit tests run against Force Framework.
 * <p>
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../LICENSE target="_blank">MIT License</a>.
 * 
 * @author Mark Brennand
 */
global with sharing class ForceFwTestHelper {

    @TestVisible
    private static void disableAsynchronousScheduler() {
        insert new forcefw__Binding__c(
                forcefw__Type__c = 'Map<String,Integer>',
                forcefw__Action__c = 'AsynchronousScheduler',
                forcefw__Implementation__c = 'ForceFwTestHelper.DisableAsynchronousSchedulerProperties'
        );
    }

    global with sharing class DisableAsynchronousSchedulerProperties implements forcefw.TypesV1.Factory {
        public Object newInstance() {
            return new Map<String, Integer> {
                    'noJobsToRunDelay' => 1000,
                    'maximumJobsToStart' => 0
            };
        }
    }
}