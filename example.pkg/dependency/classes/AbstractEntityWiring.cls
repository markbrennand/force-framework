/**
 * @description
 * Examples of use of wiring of an abstract entity.
 *
 * @author Mark Brennand
 */
public with sharing class AbstractEntityWiring {

    // Setup a default registry. The default registry will configure the creation of the Account to be performed
    // synchronously.
    static {
        forcefw.Dependency.bind(AccountClasses.AccountManager.class, AccountClasses.SyncAccountManager.class);
    }

    public static void example(String name) {
        clean(name);

        // Application injects in the active AccountManager for the org.
        AccountClasses.AccountManager manager =
                (AccountClasses.AccountManager) forcefw.Dependency.inject(AccountClasses.AccountManager.class);

        // Then creates the account.
        System.debug(manager.newAccount(name));

        // And selects it.
        System.debug([SELECT Id, Name FROM Account WHERE Name = :name]);
    }

    /**
     * @description
     * Clears any Bindings of the AccountManager interface.
     */
    public static void reset() {
        delete [SELECT Id FROM forcefw__Binding__c WHERE forcefw__Type__c = 'AccountClasses.AccountManager'];
    }

    /**
     * @description
     * Deletes the account.
     */
    private static void clean(String name) {
        if (name != null) {
            delete [SELECT Id FROM Account WHERE Name = :name];
        }
    }
}
