/**
 * @description
 * @author Mark Brennand
 */

public with sharing class ExampleRunnable extends AsynchronousRunnable {

    static {
        Injection.add(Map<String, Integer>.class, 'ExampleRunnable', Configuration.class);
        Injection.reload();
    }

    private final Map<String, Integer> configuration =
            (Map<String, Integer>) Injection.wire(Map<String, Integer>.class, 'ExampleRunnable');

    public ExampleRunnable() {
        super(ExampleRunnable.class);
    }

    public override void run(Asynchronous.Job job) {
        Assert.isNotNull(job.getRetryNumber());

        if (job.getRetryNumber() == configuration.get('succeedOnRetryNumber')) {
            return;
        }

        if (job.getState().get('action') == 'soql-201') {
            for (Integer i = 0; i < 201; i++) {
                List<Account> accounts = [SELECT Id FROM Account];
            }
        }
    }

    public override Integer getMaximumActive() {
        return configuration.get('maximumActive');
    }

    public override Asynchronous.Status onError(Asynchronous.job job, Exception exc) {
        return Asynchronous.Status.QUEUED;
    }

    public override Boolean onCancellation(Asynchronous.Job asyncJob) {
        return true;
    }

    public class Configuration implements TypeHelper.Factory {
        public Object newInstance() {
            return new Map<String, Integer> { 'maximumActive' => 1 };
        }
    }
}