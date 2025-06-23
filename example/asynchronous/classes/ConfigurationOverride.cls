/**
 * @description
 * Class that can be used to override configuration settings.
 *
 * The class can be used to configure the following components by creating a custom Binding of type
 * Map&lt;String, Integer&gt; with an action name matching the component;
 * - AsynchronousScheduler
 * - AccountContactTotals
 * - ExampleRunnable
 *
 * @author Mark Brennand
 */
public with sharing class ConfigurationOverride implements TypesV1.Factory {
    public Object newInstance() {
        return new Map<String, Integer> {
                'maximumJobsToStart' => 4,  // Configures AsynchronousScheduler.
                'noJobsToRunDelay' => 7500, // Configures AsynchronousScheduler.
                'maximumActive' => 16,       // Configures AccountContactTotals and ExampleRunnable
                'succeedOnRetryNumber' => 2 // Configures AccountContactTotals and ExampleRunnable
        };
    }
}
