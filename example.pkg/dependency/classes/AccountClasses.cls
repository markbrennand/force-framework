/**
 * @description
 * Classes used in the abstract entity injection example which uses the Account record.
 *
 * @author Mark Brennand
 */
global with sharing class AccountClasses {

    global interface AccountManager {
        Account newAccount(String name);
    }

    global class SyncAccountManager implements AccountManager {
        public Account newAccount(String name) {
            Account acc = new Account(Name = name);
            insert acc;
            return acc;
        }
    }

    global class AsyncAccountManager implements AccountManager, Queueable {
        private String name;

        public void execute(QueueableContext context) {
            new SyncAccountManager().newAccount(name);
        }

        public Account newAccount(String name) {
            this.name = name;
            System.enqueueJob(this);
            return null;
        }
    }
}
