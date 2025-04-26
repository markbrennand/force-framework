# Injection
Dependency Injection (DI) is a software design pattern where an object receives its dependencies from an external source
rather than creating them internally. This promotes loose coupling, making code more modular, testable, and easier to
maintain. Instead of a class creating its own dependencies, it receives them as arguments (constructor injection),
properties (setter injection), or through an interface (interface injection).

The term "abstract entity" used in this document shall refer to either an interface or abstract class.

Thg ```Injection``` class allows an abstract entity to be bound to a concrete implementation. An application can use
one of the ```wire``` methods to perform interface injection. This allows the same implementation class to be used
in many places in the code base. It allows for the implementation to be changed application wide easily. A custom
object is used to configure the binding from the abstract entity to concrete class.

By default, the class wired into an application will be a singleton. For this reason, the implementation class must
not have state that may change in use.

If an implementation class is required to have state, then the class must implement the ```Injection.Prototype```
interface.

## Bindings
A binding is the mapping from an abstract entity to its concrete implementation. The bindings are stored in
the ```Injection``` class as a ```Map``` called the registry. The key to the registry is the abstract entity.

Two types of binding are supported.
* A binding to an abstract entity.
* A binding to an abstract entity with an associated action.

For the first type, the abstract entity can only have one binding in the registry.

The second type can have multiple bindings of the abstract entity in the registry. Each must have a unique action.

## Example Code
The following information will be used in the examples in the remainder of this document.

An application has an interface for querying and two implemenations.
```
public interace Query {
    List<SObject> query(String query, Map<String, Object> bindVariables
}

public class UserModeQueryImpl implements Query {
    public List<SObject> query(String query, Map<String, Object> bindVars) {
        System.debug('Querying in USER_MODE');
        return Database.queryWithBinds(query, bindVars, AccessLevel.USER_MODE);
    }
}

public class SystemModeQueryImpl implements Query {
    public List<SObject> query(String query, Map<String, Object> bindVars) {
        System.debug('Querying in SYSTEM_MODE');
        return Database.queryWithBinds(query, bindVars, AccessLevel.SYSTEM_MODE);
    }
}
```

The source code for all the examples can be found in the example/injection directory.

## Initialisation
The registry may be initialised either programmatically or through the ```Binding__c``` custom object.
#### Programmatic Initialisation
The ```Injection.add``` methods can be called to add a binding to the registry. If an application requires a default
registry to be setup, the application must call these methods to add the bindings.

The following snippet taken from ```example/injection/classes/BindingInitalisation.cls``` shows the initialisation of
a default registry.
```
 public static void programmatic() {

        // Add the bindings to the registry.
        Injection.add(Query.class, UserModeQueryImpl.class);
        Injection.add(Query.class, 'SYSTEM', SystemModeQueryImpl.class);
```
#### Custom Object Initialisation
The bindings can be configured using the ```Binding__c``` custom object. The values in the custom object records will
override the values currently in the bindings.

The fields of the custom object are;

| Field             | Type      | Description                                                                           |
|-------------------|-----------|---------------------------------------------------------------------------------------|
| Type__c           | Mandatory | The class name of the abstract entity to be bound.                                    |
| Implementation__c | Mandatory | The class name of the concrete class that implements the abstract entity.             |
| Action__c         | Optional  | T he action to be used in combination with the Type__c field to identity the binding. |

The following snippet taken from ```example/injection/classes/BindingInitalisation.cls``` shows the initialisation of a
custom registry.
```
public static void custom() {
        clean();

        // Add the custom objects to create the bindings in the registry.
        insert new Binding__c(Type__c = 'Query', Implementation__c = 'UserModeQueryImpl');
        insert new Binding__c(Type__c = 'Query', Action__c = 'SYSTEM', Implementation__c = 'SystemModeQueryImpl');
```
## Binding Validation
Validation of the implementation bound to an interface or abstract class can be performed by adding a class that
implements the ```BindingCheck``` interface;

```
global interface BindingCheck {
        /**
         * @description 
         * Given an interface or abstract type, a class implementing this method checks that the given
         * implementation class can be bound to it.
         * 
         * If the for type is an interface then an implementation of this method must check that the implementation
         * class implements the interface.
         * 
         * If the for type is an abstract class then an implementation of this method must check that the implementation
         * class extends the abstract class.
         * 
         * @param forType The interface or abstract class being validated.
         * @param withImpl The implementation to assign to the interface or abstract class.
         *
         * @return The result of the validation.
         */
        ValidationResult validate(Type forType, Type withImpl);
    }
```

The ```BindingCheck__mdt``` custom metadata object holds a mapping from the abstract entity to its ```BindingCheck```
validator.

The fields of the metadata object are;

| Field |Type | Description                                                                                             |
|-------|-----|---------------------------------------------------------------------------------------------------------|
| Type__c | Mandatory | The class name of the abstract entity to be validated. !                                                
| Checker__c | Mandatory | The class name of the ```BindingCheck``` implementation to validate the binding of the abstract entity. |
| IsUnitTest__c | Mandatory | If true, the ```BindingCheck``` is for unit test use only. |

The ```BindingCheck.check``` method must return a ```Registry.ValidationResult``` object which notifies the caller
of the result of the validation. If a failure notification is returned, an ```Injection.APIException``` is thrown
with the message set to the value recorded in the ```ValidationResult.errorMessage``` field.

The following snippet taken from ```example/injection/classes/InjectionInitalisation.cls``` shows the ```BindingCheck```
implementation used to validate that the ```Query``` interface has been assigned to a concrete class that
implements it.
```
public class QueryValidator implements Injection.BindingCheck {
        public Injection.ValidationResult validate(Type forType, Type withImpl) {
            if (TypeHelper.newInstance(withImpl) instanceof Query) {
                return new Registry.ValidationResult(true, null);
            } else {
                return new Injection.ValidationResult(
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
