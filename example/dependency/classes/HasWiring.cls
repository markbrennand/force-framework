/**
 * @description
 * Examples of use of Injection.has methods to test if a binding exists.
 *
 * @author Mark Brennand
 */
public with sharing class HasWiring {

    /**
     * @description
     * Example of checking existence of a Binding before wiring.
     *
     * @param name Name of Account to create.
     */
    public static void has(String name) {

        // Check if a Binding exists for the AccountManager interface.
        if (Dependency.isBound(AccountClasses.AccountManager.class)) {

            // The Binding exists, it can be injected and called.
            ((AccountClasses.AccountManager) Dependency.inject(AccountClasses.AccountManager.class)).newAccount(name);
        } else {
            System.debug('Wiring for AccountClasses.AccountManager does not exist');
        }
    }

    /**
     * @description
     * Example of checking existence of a Binding before wiring.
     *
     * @param name Name of Account to create.
     */
    public static void action(String name) {

        // Check if a Binding exists for the AccountManager interface with action ASYNC.
        if (Dependency.isBound(AccountClasses.AccountManager.class, 'ASYNC')) {

            // The Binding exists, it can be injected and called.
            ((AccountClasses.AccountManager) Dependency.inject(AccountClasses.AccountManager.class, 'ASYNC')).newAccount(name);
        } else {
            System.debug('Wiring for AccountClasses.AccountManager with action ASYNC does not exist');
        }
    }

    /**
     * @description
     * Clears any Bindings of the AccountManager interface.
     */
    public static void reset() {
        delete [SELECT Id FROM Binding__c WHERE Type__c = 'AccountClasses.AccountManager'];
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
