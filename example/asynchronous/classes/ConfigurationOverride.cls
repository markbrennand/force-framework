/**
 * @description
 * @author Mark Brennand
 */
public with sharing class ConfigurationOverride implements TypeHelper.Factory {
    public Object newInstance() {
        return new Map<String, Integer> {
                'maxSchedulers' => 1,
                'maximumActive' => 32,
                'succeedOnRetryNumber' => 5,
                'noJobsToRunDelay' => 7500
        };
    }
}