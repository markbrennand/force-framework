/**
 * @description
 * Examples of bindings initialisation.
 *
 * @author Mark Brennand
 */

public with sharing class BindingInitialisation {

    /**
     * @description
     * Example of programmatic initialisation of the registry.
     */
    public static void programmatic() {

        // Add the bindings to the registry.
        Injection.add(QueryClasses.QueryInterface.class, QueryClasses.UserQueryInterfaceImpl.class);
        Injection.add(QueryClasses.AbstractQuery.class, QueryClasses.UserAbstractQueryImpl.class);
        Injection.add(QueryClasses.QueryInterface.class, 'SYSTEM', QueryClasses.SystemQueryInterfaceImpl.class);
        Injection.add(QueryClasses.AbstractQuery.class, 'SYSTEM', QueryClasses.SystemAbstractQueryImpl.class);

        // Check the bindings have been added.
        Assert.isTrue(Injection.has(QueryClasses.QueryInterface.class));
        Assert.isTrue(Injection.has(QueryClasses.AbstractQuery.class));
        Assert.isTrue(Injection.has(QueryClasses.QueryInterface.class, 'SYSTEM'));
        Assert.isTrue(Injection.has(QueryClasses.AbstractQuery.class, 'SYSTEM'));

        // Check the bindings have been bound correctly.
        Assert.isTrue(Injection.wire(QueryClasses.QueryInterface.class) instanceof QueryClasses.UserQueryInterfaceImpl);
        Assert.isTrue(Injection.wire(QueryClasses.AbstractQuery.class) instanceof QueryClasses.UserAbstractQueryImpl);
        Assert.isTrue(Injection.wire(QueryClasses.QueryInterface.class, 'SYSTEM') instanceof QueryClasses.SystemQueryInterfaceImpl);
        Assert.isTrue(Injection.wire(QueryClasses.AbstractQuery.class, 'SYSTEM') instanceof QueryClasses.SystemAbstractQueryImpl);

        // When this method is run, debug will record;
        // DEBUG|Querying in USER_MODE
        // DEBUG|Querying in USER_MODE
        // DEBUG|Querying in SYSTEM_MODE
        // DEBUG|Querying in SYSTEM_MODE
        ((QueryClasses.QueryInterface) Injection.wire(QueryClasses.QueryInterface.class)).query(
                'SELECT Id FROM Account WHERE Name != :ignoreName',
                new Map<String, Object> { 'ignoreName' => 'Fred Bloggs' }
        );

        ((QueryClasses.AbstractQuery) Injection.wire(QueryClasses.AbstractQuery.class)).query(
                'SELECT Id FROM Account WHERE Name != :ignoreName',
                new Map<String, Object> { 'ignoreName' => 'Fred Bloggs' }
        );

        ((QueryClasses.QueryInterface) Injection.wire(QueryClasses.QueryInterface.class, 'SYSTEM')).query(
                'SELECT Id FROM Account WHERE Name != :ignoreName',
                new Map<String, Object> { 'ignoreName' => 'Fred Bloggs' }
        );

        ((QueryClasses.AbstractQuery) Injection.wire(QueryClasses.AbstractQuery.class, 'SYSTEM')).query(
                'SELECT Id FROM Account WHERE Name != :ignoreName',
                new Map<String, Object> { 'ignoreName' => 'Fred Bloggs' }
        );
    }

    /**
     * @description
     * Example of initialisation of the bindings from the Binding__c custom object.
     */
    public static void custom() {
        clean();

        // Add the custom objects to create the bindings in the registry.
        insert new Binding__c(Type__c = 'QueryClasses.QueryInterface', Implementation__c = 'QueryClasses.UserQueryInterfaceImpl');
        insert new Binding__c(Type__c = 'QueryClasses.AbstractQuery', Implementation__c = 'QueryClasses.UserAbstractQueryImpl');
        insert new Binding__c(Type__c = 'QueryClasses.QueryInterface', Action__c = 'SYSTEM', Implementation__c = 'QueryClasses.SystemQueryInterfaceImpl');
        insert new Binding__c(Type__c = 'QueryClasses.AbstractQuery', Action__c = 'SYSTEM', Implementation__c = 'QueryClasses.SystemAbstractQueryImpl');

        // Check the bindings have been added.
        Assert.isTrue(Injection.has(QueryClasses.QueryInterface.class));
        Assert.isTrue(Injection.has(QueryClasses.AbstractQuery.class));
        Assert.isTrue(Injection.has(QueryClasses.QueryInterface.class, 'SYSTEM'));
        Assert.isTrue(Injection.has(QueryClasses.AbstractQuery.class, 'SYSTEM'));

        // Check the bindings have been bound correctly.
        Assert.isTrue(Injection.wire(QueryClasses.QueryInterface.class) instanceof QueryClasses.UserQueryInterfaceImpl);
        Assert.isTrue(Injection.wire(QueryClasses.AbstractQuery.class) instanceof QueryClasses.UserAbstractQueryImpl);
        Assert.isTrue(Injection.wire(QueryClasses.QueryInterface.class, 'SYSTEM') instanceof QueryClasses.SystemQueryInterfaceImpl);
        Assert.isTrue(Injection.wire(QueryClasses.AbstractQuery.class, 'SYSTEM') instanceof QueryClasses.SystemAbstractQueryImpl);

        // When this method is run, debug will record;
        // DEBUG|Querying in USER_MODE
        // DEBUG|Querying in USER_MODE
        // DEBUG|Querying in SYSTEM_MODE
        // DEBUG|Querying in SYSTEM_MODE
        ((QueryClasses.QueryInterface) Injection.wire(QueryClasses.QueryInterface.class)).query(
                'SELECT Id FROM Account WHERE Name != :ignoreName',
                new Map<String, Object> { 'ignoreName' => 'Fred Bloggs' }
        );

        ((QueryClasses.AbstractQuery) Injection.wire(QueryClasses.AbstractQuery.class)).query(
                'SELECT Id FROM Account WHERE Name != :ignoreName',
                new Map<String, Object> { 'ignoreName' => 'Fred Bloggs' }
        );

        ((QueryClasses.QueryInterface) Injection.wire(QueryClasses.QueryInterface.class, 'SYSTEM')).query(
                'SELECT Id FROM Account WHERE Name != :ignoreName',
                new Map<String, Object> { 'ignoreName' => 'Fred Bloggs' }
        );

        ((QueryClasses.AbstractQuery) Injection.wire(QueryClasses.AbstractQuery.class, 'SYSTEM')).query(
                'SELECT Id FROM Account WHERE Name != :ignoreName',
                new Map<String, Object> { 'ignoreName' => 'Fred Bloggs' }
        );

        clean();
    }

    /**
     * @description
     * Example of the binding check logic used to detect an incorrect binding assignment when bindings are
     * initialised programmatically.
     */
    public static void programmaticValidationFailure() {
        // User class does not implement the QueryInterface interface. The QueryValidator class will identify this.
        Injection.add(QueryClasses.QueryInterface.class, 'SYSTEM', User.class);
    }

    /**
     * @description
     * Example of the biding check logic used to detect an incorrect binding assignment when bindings
     * initialised from custom object.
     */
    public static void customValidationFailure() {
        clean();

        // User class does not implement the QueryInterface interface. The QueryValidator class will identify this.
        insert new Binding__c(Type__c = 'QueryClasses.QueryInterface', Action__c = 'SYSTEM', Implementation__c = 'User');
    }

    /**
     * @description
     * Resets the custom bindings.
     */
    private static void clean() {
        delete [
                SELECT Id FROM Binding__c
                WHERE Type__c = 'QueryClasses.QueryInterface' OR Type__c = 'QueryClasses.AbstractQuery'
        ];
    }
}