/**
 * @description
 * Class to be run by Asynchronous API that will set values in Account and Contact.
 *
 * @author Mark Brennand
 */
global with sharing class AccountContactTotals extends forcefw.AsynchronousV1.Runnable {

    /**
     * @description
     * Inject the configuration for the class.
     */
    private final Map<String, Integer> configuration =
            (Map<String, Integer>) forcefw.DependencyV1.inject(Map<String, Integer>.class, 'AccountContactTotals');

    /**
     * @description
     * Constructor for class.
     *
     * Note that it doesn't need to be public or global as it is constructed from a Factory in this class.
     *
     * The Type passed to the super class must be the Factory so it can be constructed when run by the Asynchronous
     * Scheduler.
     */
    private AccountContactTotals() {
        super(Executor.class);
    }

    /**
     * @description
     * Called when the Asynchronous API Job is being run as an Apex job.
     *
     * @param job The Asynchronous API job being run.
     * @param apexJobId The Id of the Apex Job that is running the job
     */
    public override void run(final forcefw.Asynchronous.Job job, final String apexJobId) {
        if (job.getRetryNumber() < configuration.get('succeedOnRetryNumber')) {
            throw new forcefw.Asynchronous.APIException('Failed on retry ' + job.getRetryNumber());
        }

        final String accountId = job.getState().get('accountId');
        final Map<String, String> newState = new Map<String, String>();

        if (accountId != null) {
            final Integer total = [SELECT COUNT() FROM Contact WHERE AccountId = :accountId];

            final Account account = new Account(Id = accountId, TotalContacts__c = total);
            upsert account;

            final List<Contact> contacts = [SELECT Id FROM Contact WHERE AccountId = :accountId];
            for (Contact contact : contacts) {
                contact.NumberOfPeers__c = total - 1;
            }

            upsert contacts;

            Set<Id> contactIds = new Map<Id, Contact>(contacts).keySet();

            newState.put('accountUpdated', String.valueOf(accountId));
            newState.put('contactsUpdated', String.valueOf(contactIds));
        }

        final String orphanedContactId = job.getState().get('orphanedContactId');
        if (orphanedContactId != null) {
            final Contact contact = new Contact(Id = Id.valueOf(orphanedContactId), NumberOfPeers__c = 0);
            upsert contact;

            newState.put('contactUpdated', orphanedContactId);
        }

        job.setState(newState);
    }

    /**
     * @description
     * The number of jobs of this type that may be active concurrently.
     *
     * @return The maximum number of concurrent jobs.
     */
    public override Integer getMaximumActive() {
        return configuration.get('maximumActive');
    }

    /**
     * @description
     * Factory to construct an instance of the Runnable class.
     *
     * The class is global so it can be constructed from the forcefw namespace by the Force Framework package.
     *
     * The constructor does not need to be global as it is being called via the Types.Factory interface which is
     * global.
     */
    global with sharing class Executor implements forcefw.TypesV1.Factory {

        public Object newInstance() {
            return new AccountContactTotals();
        }
    }

    /**
     * @description
     * Called by Contact trigger to start an Asynchronous Job to update Contact(s).
     *
     * @param contacts The modified Contacts.
     * @param oldValues The original values of the modified Contacts.
     */
    public static void startCalculationJob(final List<Contact> contacts, final forcefw.TriggersV1.Event event) {
        final List<Account> accounts = new List<Account>();
        final Set<Id> orphanedContactIds = new Set<Id>();

        if (contacts == null) {
            for (Contact deletedContact : (List<Contact>) event.getOldValues()) {
                if (deletedContact.AccountId != null) {
                    accounts.add(new Account(Id = deletedContact.AccountId));
                }
            }

        } else {
            for (Contact contact : contacts) {
                if (contact.AccountId == null) {
                    orphanedContactIds.add(contact.Id);
                }

                if (event.hasOldValue(contact)) {
                    final Contact oldValue = (Contact) event.getOldValue(contact);
                    if (contact.AccountId != oldValue.AccountId) {
                        if (contact.AccountId != null) {
                            accounts.add(new Account(Id = contact.AccountId));
                        }

                        if (oldValue.AccountId != null) {
                            accounts.add(new Account(Id = oldValue.AccountId));
                        }
                    }
                } else if (contact.AccountId != null) {
                    accounts.add(new Account(Id = contact.AccountId));
                }
            }
        }

        startCalculationJob(accounts, orphanedContactIds);
    }

    /**
     * @description
     * Called by Account trigger to start an Asynchronous Job to update Account(s).
     *
     * @param accounts The modified Accounts.
     * @param orphanedContactIds The Ids of the Contacts that have been orphaned by the modification of them.
     */
    public static void startCalculationJob(final List<Account> accounts, final Set<Id> orphanedContactIds) {

        // The update to Account from the Asynchronous Job causes the trigger to fire and would cause another
        // job to be queued.
        if (System.isQueueable() || System.isFuture() || System.isScheduled()) {
            return;
        }

        final Set<id> accountIds = new Set<Id>();
        for (Account account : accounts) {
            accountIds.add(account.Id);
        }

        final List<forcefw.Asynchronous.Job> jobs = new List<forcefw.Asynchronous.Job>();

        for (Id accountId : accountIds) {
            jobs.add(
                    forcefw.AsynchronousV1.createJob(
                            Executor.class,
                            accountId,
                            10,
                            15,
                            new Map<String, String> { 'accountId' => accountId }
                    )
            );
        }

        for (Id orphanedContactId : orphanedContactIds) {
            jobs.add(
                    forcefw.AsynchronousV1.createJob(
                            Executor.class,
                            orphanedContactId,
                            10,
                            15,
                            new Map<String, String> { 'orphanedContactId' => orphanedContactId }
                    )
            );
        }

        forcefw.AsynchronousV1.queueJobs(jobs);
    }

    /**
     * @description
     * Class providing base configuration.
     */
    public class Configuration implements forcefw.TypesV1.Factory {
        public Object newInstance() {
            return new Map<String, Integer> { 'succeedOnRetryNumber' => 0, 'maximumActive' => 1 };
        }
    }

    // Setup a default registry entry for the configuration for the class.
    // The configuration can be overridden by adding a custom binding.
    static {
        forcefw.DependencyV1.bind(Map<String, Integer>.class, 'AccountContactTotals', Configuration.class);
        forcefw.DependencyV1.reload();
    }
}