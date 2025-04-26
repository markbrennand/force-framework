/**
 * @description
 * Examples of use of Registry wiring.
 *
 * @author Mark Brennand
 */

public with sharing class Wiring {

    public static void example() {
        delete [SELECT Id FROM Binding__c WHERE Type__c = 'Query'];

        // Default bindings the User Mode Query implementation.
        Injection.add(Query.class, UserModeQueryImpl.class);
        Injection.add(Query.class, 'EXAMPLE', UserModeQueryImpl.class);

        Assert.isTrue(Injection.wire(Query.class) instanceof UserModeQueryImpl);
        Assert.isTrue(Injection.wire(Query.class, 'EXAMPLE') instanceof UserModeQueryImpl);

        // When this method is run, debug will record;
        // DEBUG|Querying in USER_MODE
        List<SObject> userModeRecords = ((Query) Injection.wire(Query.class)).query(
                'SELECT Id FROM Account WHERE Name != :ignoreName',
                new Map<String, Object> { 'ignoreName' => 'Fred Bloggs' }
        );

        // Add two custom overrides to change the bindings to the System Mode Query implementation.
        insert new Binding__c(Type__c = Query.class.getName(), Implementation__c = SystemModeQueryImpl.class.getName());
        insert new Binding__c(Type__c = Query.class.getName(), Action__c = 'EXAMPLE', Implementation__c = SystemModeQueryImpl.class.getName());

        Assert.isTrue(Injection.wire(Query.class) instanceof SystemModeQueryImpl);
        Assert.isTrue(Injection.wire(Query.class, 'EXAMPLE') instanceof SystemModeQueryImpl);

        // When this method is run, debug will record;
        // DEBUG|Querying in SYSTEM_MODE
        List<SObject> systemModeRecords = ((Query) Injection.wire(Query.class)).query(
                'SELECT Id FROM Account WHERE Name != :ignoreName',
                new Map<String, Object> { 'ignoreName' => 'Fred Bloggs' }
        );

        delete [SELECT Id FROM Binding__c WHERE Type__c = 'Query'];
    }
}