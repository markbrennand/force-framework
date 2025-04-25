# Registry
A registry allowing interfaces and abstract classes to be bound to their concrete implementations. The binding can be
wired into an application. This allows for the same implementation class to be used in many places in the code base.
It also allows for the implementation to be changed application wide easily.

By default, the class wired into an application will be a singleton. For this reason, the implementation class must
not have state that may change in use.

If an implementation class is required to have state, then the class must implement the ```Registry.Prototype```
interface.

## Binding Type
Two typs of binding are available in the registry.
* A binding to an interface or abstract class.
* A binding to an interface or abstract class with an associated action.

For the first type, the interface or abstract class can only have one binding in the registry.

The second type can have multiple bindings of the interface or abstract class in the registry as long as each has
a unique action.

## Example Code
The following information will be used in the examples in the remainder of this document.

An application has an interface for querying.
```
public interace Query {
    List<SObject> query(String query, Map<String, Object> bindVariables
}
```
And two implementations of the interface.
```
public class UserModeQueryImpl implements Query {
    public List<SObject> query(String query, Map<String, Object> bindVars) {
        System.debug('Querying in USER_MODE');
        return Database.queryWithBinds(query, bindVars, AccessLevel.USER_MODE);
    }
}
```
```
public class SystemModeQueryImpl implements Query {
    public List<SObject> query(String query, Map<String, Object> bindVars) {
        System.debug('Querying in SYSTEM_MODE');
        return Database.queryWithBinds(query, bindVars, AccessLevel.SYSTEM_MODE);
    }
}
```

The source code for all the examples can be found in the example/registry directory.

## Initialisation
The registry may be initialised either programmatically or through the ```Binding__c``` custom object.
#### Programmatic Initialisation
The ```Registry.add``` methods can be called to add a registry entry. If an application requires a default registry
to be setup, the setup method must call these methods to configure the default registry.

The following snippet taken from ```example/classes/RegisstryInitalisation.cls``` shows the initialisation of a
default registry.
```
public static void programmatic() {

        // Add the bindings to the registry.
        Registry.add(Query.class, UserModeQueryImpl.class);
        Registry.add(Query.class, 'SYSTEM', SystemModeQueryImpl.class);
```
#### Custom Object Initialisation
The registry can be configured using the ```Binding__c``` custom object. The values in the custom object records will
override the values currently in the registry.

The three fields in the custom object are;
* Type__c -- The class name of the interface or abstract class to be bound.
* Action__c -- Optional field giving an action to be used in combination with the Type__c field to identity the binding.
* Implementation__c -- The class name of the concrete class that implements the interface.

The following snippet taken from ```example/classes/RegisstryInitalisation.cls``` shows the initialisation of a custom
registry.
```
public static void custom() {
        clean();

        // Add the custom objects to create the bindings in the registry.
        insert new Binding__c(Type__c = 'Query', Implementation__c = 'UserModeQueryImpl');
        insert new Binding__c(Type__c = 'Query', Action__c = 'SYSTEM', Implementation__c = 'SystemModeQueryImpl');
```
## Binding Validation
Validation of the implementations bound to an interface or abstract class can be performed by writing a class that
implements the ```BindingCheck``` interface.

The ```BindingCheck__mdt``` custome metadata object holds a mapping from the interface or abstract class to its
```BindingCheck``` validator.

In the example code, a ```BindingCheck``` is added to the custom metadata which validates the implementation assigned
the ```Query``` interface.

The ```BindingCheck.check``` method must return a ```Registry.ValidationResult``` object which notifies the caller
of the result of the validation. If a failure notification is returned, a ```Registry.APIException``` is thrown
with the message set to the value recorded in the ```ValidationResult.errorMessage``` field.

The following snippet taken from ```example/classes/RegisstryInitalisation.cls``` shows the ```BindingCheck```
implementation used to validate that the ```Query``` interface has been assigned to a concrete class that
implements it.
```
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
```

## Wiring
Wiring is the action of using a binding in an application.

For example, 
