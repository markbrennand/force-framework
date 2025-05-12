/**
 * @description
 * Class providing asynchronous job creation and management.
 *
 * @author Mark Brennand
 */
global with sharing virtual class Asynchronous implements API {

    /**
     * @description
     * Defines the state of a AsynchronousJob__c under the control of this framework.
     *
     * A job can only be in a single state at any one time.
     *
     * CREATED - The job has been created but no AsynchronousJob__c object has been persisted for it.
     *
     * QUEUED - The AsynchronousJob__c has been queued for processing.
     *
     * RUNNING - An Apex job has been created for the AsynchronousJob__c and scheduled.
     *
     * REQUEUED - The Apex Job for the AsynchronousJob__c failed and the AsynchronousJob__c can be re-tried.
     *
     * FINISHED - The Apex Job for the AsynchronousJob__c ran successfully.
     *
     * FAILED - The last Apex Job for the AsynchronousJob__c failed to run and the maximum number of retries has been exceeded.
     */
    global enum State {
        CREATED,
        QUEUED,
        RUNNING,
        REQUEUED,
        FINISHED,
        FAILED,
        CANCELLED
    }

    global interface API {
        Job createJob(
                Type forType,
                String withReference,
                Integer withMaxRetries,
                Integer withRetryInterval,
                Map<String, String> arguments
        );
    }

    global interface Runnable {
        Type getType();
        void run(Job job);
        Boolean onSuccess(Job job);
        Boolean onFailure(Job job);
        Boolean onCancel(Job job);
        State onError(Job job, Exception error);
    }

    global interface Job {
        State getState();
        String getOwnerId();
        Integer getMaxRetries();
        Integer getRetriesRemaining();
        Runnable getRunnable();
        Map<String, String> getArguments();
    }

    /**
     * @description
     * Exception thrown when an asynchronous operation fails.
     */
    global with sharing class APIException extends Exception {}

    global with sharing abstract class AbstractRunnable implements Runnable {
        private final Type type;

        global AbstractRunnable(final Type type) {
            this.type = type;
        }

        global Type getType() {
            return type;
        }

        global virtual Boolean onSuccess(Job job) {
            return true;
        }

        global virtual Boolean onFailure(Job job) {
            return true;
        }

        global virtual Boolean onCancel(Job job) {
            return true;
        }

        global virtual State onError(Job job, Exception error) {
            return State.REQUEUED;
        }
    }

    protected Asynchronous() {}

    public Job createJob(
            final Type forType,
            final String withReference,
            final Integer withMaxRetries,
            final Integer withRetryInterval,
            final Map<String, String> arguments
    ) {
        return new JobImpl(forType.getName(), State.CREATED, withReference, withMaxRetries, withRetryInterval, arguments);
    }

    public static Job create(
            final Type forType,
            final String withReference,
            final Integer withMaxRetries,
            final Integer withRetryInterval,
            final Map<String, String> withArguments
    ) {
        return INSTANCE.createJob(forType, withReference, withMaxRetries, withRetryInterval, withArguments);
    }

    private with sharing class JobImpl implements Job, Queueable {

        /**
         * @description
         * The Id of the user who created the job.
         */
        private final String ownerId;

        /**
         * @description
         * The maximum number of retries that will be attempted to re-run the job successfully after the first
         * failure.
         */
        private final Integer maxRetries;

        /**
         * @description
         * The interval in milliseconds between re-tries.
         */
        private final Integer retryInterval;

        private final Map<String, String> arguments;
        private final String reference;
        private final State state;
        private final Runnable runnable;

        /**
         * @description
         * Class providing
         *
         * @param runnable
         * @param maxRetries
         * @param retryInterval
         */
        public JobImpl(
                final String runnableTypeName,
                final State state,
                final String reference,
                final Integer maxRetries,
                final Integer retryInterval,
                final Map<String, String> arguments
        ) {
            final Object runnable = runnableTypeName != null
                    ? TypeHelper.newInstance(TypeHelper.loadType(runnableTypeName))
                    : null;

            Assert.isTrue(
                    runnable != null && runnable instanceof Runnable,
                    'Runnable class must be defined and must implement Runnable'
            );

            Assert.isTrue(state != null, 'State must be defined');
            Assert.isTrue(maxRetries != null &&  maxRetries >= 0, 'Max retries must be defined and be 0 or more');
            Assert.isTrue(retryInterval != null && retryInterval >= 0, 'Retry interval must be defined and be 0 or more');
            Assert.isTrue(arguments != null, 'Arguments must be defined');

            this.ownerId = UserInfo.getUserId();
            this.state = state;
            this.runnable = (Runnable) runnable;
            this.reference = reference;
            this.maxRetries = maxRetries;
            this.retryInterval = retryInterval;
            this.arguments = arguments;
        }

        /**
         * @description
         * Gets the id of the owner of the job.
         *
         * @return The id of the user.
         */
        public String getOwnerId() {
            return this.ownerId;
        }

        /**
         * @description
         * The maximum number of instances of a sub-class that may be running concurrently.
         *
         * @return The maximum number,
         */
        public Integer getConcurrency() {
            return 10;
        }

        public State getState() {
            return state;
        }

        public Integer getMaxRetries() {
            return maxRetries;
        }

        public Integer getRetriesRemaining() {
            return 0;
        }

        public Runnable getRunnable() {
            return runnable;
        }

        public Map<String, String> getArguments() {
            return arguments;
        }

        public void execute(final QueueableContext context) {
            runnable.run(this);
        }
    }

    public with sharing class Factory implements TypeHelper.Factory {
        public Object newInstance() {
            return new Asynchronous();
        }
    }

    public static void isRunnable(final List<Asynchronous__c> records) {
        for (Asynchronous__c record : records) {
            try {
                if (!(TypeHelper.newInstance(TypeHelper.loadType(record.Runnable__c)) instanceof Asynchronous.Runnable)) {
                    record.addError('Class ' + record.Runnable__c + ' does not implement Asynchronous.Runnable');
                }
            } catch(Exception e) {
                record.addError(e.getMessage());
            }
        }
    }

    /**
     * @description
     * Class providing check on Binding made to Asynchronous.API.
     */
    public with sharing class BindingCheck implements Injection.BindingCheck {

        /**
         * @description
         * Checks that a valid binding has been made to Asynchronous.API.
         *
         * @param forType The type being bound to, Asynchronous.API.
         * @param withImpl The implementation being bound to Asynchronous.API.
         *
         * @return The result of the validation.
         */
        public Injection.ValidationResult validate(Type forType, Type withImpl) {
            if (TypeHelper.newInstance(withImpl) instanceof Asynchronous.API) {
                return new Injection.ValidationResult(true, null);
            } else {
                return new Injection.ValidationResult(
                        false,
                        'Class ' + withImpl.getName() + ' does not implement ' + forType.getName()
                );
            }
        }
    }

    /**
     * @description
     * Active API instance.
     *
     * The instance is wired in from the registry.
     *
     * The instance is test visible so it can be mocked.
     */
    @TestVisible
    private static API INSTANCE {
        private get {
            if (INSTANCE == null) {
                INSTANCE = (API) Injection.wire(API.class);
            }
            return INSTANCE;
        }
        private set;
    }

    public class TestRunnable extends AbstractRunnable {
        public TestRunnable() {
            super(TestRunnable.class);
        }

        public void run(Job job) {
            System.debug('TestRunnable.run ' + job);
        }
    }

    public class TestFactoryRunnable implements TypeHelper.Factory {
        public Object newInstance() {
            return new TestRunnable();
        }
    }
}