/**
 * @description
 * @author Mark Brennand
 */

global with sharing class ExampleRunnable extends forcefw.AsynchronousV1.Runnable {

    static {
        forcefw.DependencyV1.bind(Map<String, Integer>.class, 'ExampleRunnable', Configuration.class);
        forcefw.DependencyV1.reload();
    }

    private final Map<String, Integer> configuration =
            (Map<String, Integer>) forcefw.DependencyV1.inject(Map<String, Integer>.class, 'ExampleRunnable');

    public ExampleRunnable() {
        super(Executor.class);
    }

    public void run(forcefw.AsynchronousV1.Job job, String apexJobId) {
        Assert.isNotNull(job.getRetryNumber(), 'Job has no retry number');
        Assert.isNotNull(apexJobId, 'No Apex Job id');

        String delay = job.getState().get('delay');
        if (!String.isEmpty(delay)) {
            Long endTime = System.currentTimeMillis() + Long.valueOf(delay);
            for (Long now = System.currentTimeMillis(); now < endTime; now = System.currentTimeMillis()) {}
        }

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

    public override forcefw.AsynchronousV1.Status onError(forcefw.AsynchronousV1.job job, Exception exc) {
        return forcefw.AsynchronousV1.Status.QUEUED;
    }

    public override Boolean onCancellation(forcefw.AsynchronousV1.Job asyncJob) {
        return true;
    }

    global class Executor implements forcefw.TypesV1.Factory {

        public Object newInstance() {
            return new ExampleRunnable();
        }
    }

    public class Configuration implements forcefw.TypesV1.Factory {
        public Object newInstance() {
            return new Map<String, Integer> { 'maximumActive' => 1 };
        }
    }
}
