/**
 * @description
 * @author Mark Brennand
 */
public with sharing class ConfigurationOverride implements TypeHelper.Factory {
    public Object newInstance() {
        return new Map<String, Integer> {
                'maxSchedulers' => 256,
                'maximumActive' => 256,
                'noJobsToRunDelay' => 9000
        };
    }
}