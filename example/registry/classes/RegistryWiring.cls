/**
 * @description
 * Examples of use of Registry wiring.
 *
 * @author Mark Brennand
 */

public with sharing class RegistryWiring {

    public static void example() {
        delete [SELECT Id FROM Binding__c WHERE Type__c = 'Query'];

        // Default registry binding the User Mode Query implementation.
        Registry.add(Query.class, UserModeQueryImpl.class);
        Registry.add(Query.class, 'EXAMPLE', UserModeQueryImpl.class);

        Assert.isTrue(Registry.wire(Query.class) instanceof UserModeQueryImpl);
        Assert.isTrue(Registry.wire(Query.class, 'EXAMPLE') instanceof UserModeQueryImpl);

        // When this method is run, debug will record;
        // DEBUG|Querying in USER_MODE
        List<SObject> userModeRecords = ((Query) Registry.wire(Query.class)).query(
                'SELECT Id FROM Account WHERE Name != :ignoreName',
                new Map<String, Object> { 'ignoreName' => 'Fred Bloggs' }
        );

        // Add two custom overrides to change the bindings to the System Mode Query implementation.
        insert new Binding__c(Type__c = Query.class.getName(), Implementation__c = SystemModeQueryImpl.class.getName());
        insert new Binding__c(Type__c = Query.class.getName(), Action__c = 'EXAMPLE', Implementation__c = SystemModeQueryImpl.class.getName());

        Assert.isTrue(Registry.wire(Query.class) instanceof SystemModeQueryImpl);
        Assert.isTrue(Registry.wire(Query.class, 'EXAMPLE') instanceof SystemModeQueryImpl);

        // When this method is run, debug will record;
        // DEBUG|Querying in SYSTEM_MODE
        List<SObject> systemModeRecords = ((Query) Registry.wire(Query.class)).query(
                'SELECT Id FROM Account WHERE Name != :ignoreName',
                new Map<String, Object> { 'ignoreName' => 'Fred Bloggs' }
        );

        delete [SELECT Id FROM Binding__c WHERE Type__c = 'Query'];
    }
}