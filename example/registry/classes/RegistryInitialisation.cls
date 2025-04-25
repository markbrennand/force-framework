/**
 * @description
 * Examples of registry initialisation.
 *
 * @author Mark Brennand
 */

public with sharing class RegistryInitialisation {

    /**
     * @description
     * Example of programmatic initialisation of the registry.
     */
    public static void programmatic() {

        // Add the bindings to the registry.
        Registry.add(Query.class, UserModeQueryImpl.class);
        Registry.add(Query.class, 'SYSTEM', SystemModeQueryImpl.class);

        // When this method is run, debug will record;
        // DEBUG|Querying in USER_MODE
        // DEBUG|Querying in SYSTEM_MODE
        List<SObject> userModeRecords = ((Query) Registry.wire(Query.class)).query(
                'SELECT Id FROM Account WHERE Name != :ignoreName',
                new Map<String, Object> { 'ignoreName' => 'Fred Bloggs' }
        );

        List<SObject> systemModeRecords = ((Query) Registry.wire(Query.class, 'SYSTEM')).query(
                'SELECT Id FROM Account WHERE Name != :ignoreName',
                new Map<String, Object> { 'ignoreName' => 'Fred Bloggs' }
        );
    }

    /**
     * @description
     * Example of initialisation of the registry from the Binding__c custom object.
     */
    public static void custom() {
        delete [SELECT Id FROM Binding__c WHERE Type__c = 'Query'];

        // Add the custom objects to create the bindings in the registry.
        insert new Binding__c(Type__c = 'Query', Implementation__c = 'UserModeQueryImpl');
        insert new Binding__c(Type__c = 'Query', Action__c = 'SYSTEM', Implementation__c = 'SystemModeQueryImpl');

        // When this method is run, debug will record;
        // DEBUG|Querying in USER_MODE
        // DEBUG|Querying in SYSTEM_MODE
        List<SObject> userModeRecords = ((Query) Registry.wire(Query.class)).query(
                'SELECT Id FROM Account WHERE Name != :ignoreName',
                new Map<String, Object> { 'ignoreName' => 'Fred Bloggs' }
        );

        List<SObject> systemModeRecords = ((Query) Registry.wire(Query.class, 'SYSTEM')).query(
                'SELECT Id FROM Account WHERE Name != :ignoreName',
                new Map<String, Object> { 'ignoreName' => 'Fred Bloggs' }
        );

        delete [SELECT Id FROM Binding__c WHERE Type__c = 'Query'];
    }

    /**
     * @description
     * Example of the biding check logic used to detect an incorrect registry assignment when registry
     * initialised programmatically.
     */
    public static void programmaticValidationFailure() {
        // User class does not implement the Query interface. The QueryValidator class will detect this.
        Registry.add(Query.class, 'SYSTEM', User.class);
    }
    /**
     * @description
     * Example of the biding check logic used to detect an incorrect registry assignment when registry
     * initialised from custom object.
     */
    public static void customValidationFailure() {
        delete [SELECT Id FROM Binding__c WHERE Type__c = 'Query'];

        // User class does not implement the Query interface. The QueryValidator class will detect this.
        insert new Binding__c(Type__c = 'Query', Action__c = 'SYSTEM', Implementation__c = 'User');
    }

    /**
     * @description
     * Class providing validation of any bindings made to the Query interface.
     *
     * A custom metadata record for the BindingCheck__mdt type is used to register the validator.
     */
    public class QueryValidator implements Registry.BindingCheck {
        public Registry.ValidationResult validate(Type forType, Type withImpl) {
            if (TypeHelper.newInstance(withImpl) instanceof Query) {
                return new Registry.ValidationResult(true, null);
            } else {
                return new Registry.ValidationResult(
                        false,
                        'Class "' + withImpl.getName() + '" does not implement "Query"'
                );
            }
        }
    }
}