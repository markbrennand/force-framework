/**
 * @description
 * @author Mark Brennand
 */

public with sharing class ExampleRunnable extends AsynchronousRunnable {

    static {
        Injection.add(Map<String, Integer>.class, 'ExampleRunnable', Configuration.class);
        Injection.reload();
    }

    private final Map<String, Integer> config =
            (Map<String, Integer>) Injection.wire(Map<String, Integer>.class, 'ExampleRunnable');

    public ExampleRunnable() {
        super(ExampleRunnable.class);
    }

    public override void run(Asynchronous.Job job) {
        Assert.isNotNull(job.getRetryNumber());

        if (job.getRetryNumber() == 8) {
            return;
        }

        if (job.getState().get('action') == 'soql-201') {
            for (Integer i = 0; i < 201; i++) {
                List<Account> accounts = [SELECT Id FROM Account];
            }
        }
    }

    public override Integer getMaximumActive() {
        return config.get('maximumActive');
    }

    public override Boolean onSuccess(Asynchronous.job job) {
        return true;
    }

    public class Configuration implements TypeHelper.Factory {
        public Object newInstance() {
            return new Map<String, Integer> { 'maximumActive' => 1 };
        }
    }
}