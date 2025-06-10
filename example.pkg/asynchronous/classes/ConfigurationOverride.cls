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
global with sharing class ConfigurationOverride implements forcefw.Types.Factory {
    public Object newInstance() {
        return new Map<String, Integer> {
                'maximumJobsToStart' => 64, // Configures AsynchronousScheduler.
                'noJobsToRunDelay' => 7500, // Configures AsynchronousScheduler.
                'maximumActive' => 32,      // Configures AccountContactTotals and ExampleRunnable
                'succeedOnRetryNumber' => 0 // Configures AccountContactTotals and ExampleRunnable
        };
    }
}
