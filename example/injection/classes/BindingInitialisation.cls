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
        Injection.add(Query.class, UserModeQueryImpl.class);
        Injection.add(Query.class, 'SYSTEM', SystemModeQueryImpl.class);

        Assert.isTrue(Injection.wire(Query.class) instanceof UserModeQueryImpl);
        Assert.isTrue(Injection.wire(Query.class, 'SYSTEM') instanceof SystemModeQueryImpl);

        // When this method is run, debug will record;
        // DEBUG|Querying in USER_MODE
        // DEBUG|Querying in SYSTEM_MODE
        List<SObject> userModeRecords = ((Query) Injection.wire(Query.class)).query(
                'SELECT Id FROM Account WHERE Name != :ignoreName',
                new Map<String, Object> { 'ignoreName' => 'Fred Bloggs' }
        );

        List<SObject> systemModeRecords = ((Query) Injection.wire(Query.class, 'SYSTEM')).query(
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
        insert new Binding__c(Type__c = 'Query', Implementation__c = 'UserModeQueryImpl');
        insert new Binding__c(Type__c = 'Query', Action__c = 'SYSTEM', Implementation__c = 'SystemModeQueryImpl');

        Assert.isTrue(Injection.wire(Query.class) instanceof UserModeQueryImpl);
        Assert.isTrue(Injection.wire(Query.class, 'SYSTEM') instanceof SystemModeQueryImpl);

        // When this method is run, debug will record;
        // DEBUG|Querying in USER_MODE
        // DEBUG|Querying in SYSTEM_MODE
        List<SObject> userModeRecords = ((Query) Injection.wire(Query.class)).query(
                'SELECT Id FROM Account WHERE Name != :ignoreName',
                new Map<String, Object> { 'ignoreName' => 'Fred Bloggs' }
        );

        List<SObject> systemModeRecords = ((Query) Injection.wire(Query.class, 'SYSTEM')).query(
                'SELECT Id FROM Account WHERE Name != :ignoreName',
                new Map<String, Object> { 'ignoreName' => 'Fred Bloggs' }
        );

        clean();
    }

    /**
     * @description
     * Example of the biding check logic used to detect an incorrect binding assignment when bindings
     * initialised programmatically.
     */
    public static void programmaticValidationFailure() {
        // User class does not implement the Query interface. The QueryValidator class will identify this.
        Injection.add(Query.class, 'SYSTEM', User.class);
    }

    /**
     * @description
     * Example of the biding check logic used to detect an incorrect binding assignment when bindings
     * initialised from custom object.
     */
    public static void customValidationFailure() {
        clean();

        // User class does not implement the Query interface. The QueryValidator class will identify this.
        insert new Binding__c(Type__c = 'Query', Action__c = 'SYSTEM', Implementation__c = 'User');
    }

    /**
     * @description
     * Class providing validation of any bindings made to the Query interface.
     *
     * A custom metadata record for the BindingCheck__mdt type is used to register the validator.
     */
    public class QueryValidator implements Injection.BindingCheck {
        public Injection.ValidationResult validate(Type forType, Type withImpl) {
            if (TypeHelper.newInstance(withImpl) instanceof Query) {
                return new Injection.ValidationResult(true, null);
            } else {
                return new Injection.ValidationResult(
                        false,
                        'Class "' + withImpl.getName() + '" does not implement "Query"'
                );
            }
        }
    }

    /**
     * @description
     * Resets the custom bindings.
     */
    private static void clean() {
        delete [SELECT Id FROM Binding__c WHERE Type__c = 'Query'];
    }
}