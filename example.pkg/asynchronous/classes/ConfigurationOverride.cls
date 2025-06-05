/**
 * @description
 * @author Mark Brennand
 */
global  with sharing class ConfigurationOverride implements forcefw.Types.Factory {
    public Object newInstance() {
        return new Map<String, Integer> {
                'maximumJobsToStart' => 1,
                'maximumActive' => 64,
                'succeedOnRetryNumber' => 5,
                'noJobsToRunDelay' => 1000
        };
    }
}
