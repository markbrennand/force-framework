/**
 * @description
 * Examples of use of wiring.
 *
 * @author Mark Brennand
 */

public with sharing class AbstractEntityWiring {

    public static void example() {
        clean();

        /*
        delete [SELECT Id FROM Binding__c WHERE Type__c = 'Query'];

        // Default bindings the User Mode Query implementation.
        Injection.add(QueryClasses.QueryInterface.class, QueryClasses.UserQueryInterfaceImpl.class);
        Injection.add(QueryClasses.QueryInterface.class, 'EXAMPLE', QueryClasses.UserQueryInterfaceImpl.class);

        Assert.isTrue(Injection.wire(QueryClasses.QueryInterface.class) instanceof QueryClasses.UserQueryInterfaceImpl);
        Assert.isTrue(Injection.wire(QueryClasses.class, 'EXAMPLE') instanceof UserModeQueryImpl);

        // When this method is run, debug will record;
        // DEBUG|Querying in USER_MODE
        ((QueryClasses.QueryInterface) Injection.wire(QueryClasses.class)).query(
                'SELECT Id FROM Account WHERE Name != :ignoreName',
                new Map<String, Object> { 'ignoreName' => 'Fred Bloggs' }
        );

        // Add two custom overrides to change the bindings to the System Mode Query implementation.
        insert new Binding__c(Type__c = QueryClasses.class.getName(), Implementation__c = SystemModeQueryImpl.class.getName());
        insert new Binding__c(Type__c = QueryClasses.class.getName(), Action__c = 'EXAMPLE', Implementation__c = SystemModeQueryImpl.class.getName());

        Assert.isTrue(Injection.wire(QueryClasses.class) instanceof SystemModeQueryImpl);
        Assert.isTrue(Injection.wire(QueryClasses.class, 'EXAMPLE') instanceof SystemModeQueryImpl);

        // When this method is run, debug will record;
        // DEBUG|Querying in SYSTEM_MODE
        List<SObject> systemModeRecords = ((QueryClasses) Injection.wire(QueryClasses.class)).query(
                'SELECT Id FROM Account WHERE Name != :ignoreName',
                new Map<String, Object> { 'ignoreName' => 'Fred Bloggs' }
        );
         */

        clean();
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