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

The example below shows the setup of a default registry which uses ```USER_MODE``` for the wiring of the
```Query``` interface with no action and ```SYSTEM_MODE``` when the interface is wired with an action of SYSTEM.
```
public void createDefaultRegistry() {
    Registry.add(Query.class, UserModeQueryImpl.class);
    Reistgry.add(Query.class, 'SYSTEM', SystemModeQueryImpl.class);
}
```
#### Custom Object Initialisation
The registry can be configured using the ```Binding__c``` custom object. The values in the custom object records will
override the values currently in the registry.

The three fields in the custom object are;
* Type__c -- The class name of the interface or abstract class to be bound.
* Action__c -- Optional field giving an action to be used in combination with the Type__c field to identity the binding.
* Implemention__c -- The class name of the class that implements the interface.
## Wiring
Wiring is the action of using a binding in an application.

For example, 
