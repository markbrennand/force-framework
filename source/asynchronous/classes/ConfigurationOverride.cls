/**
 * @description
 * @author Mark Brennand
 */

public with sharing class ConfigurationOverride implements TypeHelper.Factory {
    public Object newInstance() {
        return new Map<String, Integer> {
                'maxSchedulers' => 32,
                'maximumActive' => 32,
                'noJobsToRunDelay' =>  5000
        };
    }
}