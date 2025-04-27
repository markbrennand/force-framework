[back](../../README.md)
# Injection
The term "abstract entity" used in this document shall refer to either an interface or abstract class.

Dependency Injection (DI) is a software design pattern where an object receives its dependencies from an external source
rather than creating them internally. This promotes loose coupling, making code more modular, testable, and easier to
maintain. Instead of a class creating its own dependencies, it receives them as arguments (constructor injection),
properties (setter injection), or through an interface (abstract entity injection).

Thg _**Injection**_ class allows an abstract entity to be bound to a concrete implementation. It supports setter
and abstract entity injection. An application can use  one of the _**wire**_ methods to perform injection. This allows
the same implementation class to be used in many places in the code base. It allows for the`implementation to be
changed application wide easily.

A custom object, _**Binding__c**_, may be used to configure the binding from the property or abstract entity to a
concrete class.

By default, the class wired into an application will be a singleton. For this reason, the implementation class must
not have state that may change in use.

If an implementation class is required to have state, then the class must implement the _**Injection.Prototype**_
interface.

## Bindings
A binding is the mapping from a property or abstract entity to its concrete implementation. The bindings are stored in
the _**Injection**_ class as a _**Map**_ called the registry. The key to the registry is the type of the 
property or abstract entity.

Two types of binding are supported.
* A binding to an abstract entity. **Property injection is not supported for this binding.**
* A binding to a property or abstract entity with an associated action.

For the first type, the abstract entity can only have one binding in the registry.

The second type can have multiple bindings of the property or abstract entity in the registry. Each must have a unique
action.

## Implementation Classes
Each implementation class must have a public or global no-op constructor. An exception will be thrown if an attempt
is made to bind an abstract entity to a class that doesn't.

To allow a class to be bound that has a private or protected no-op constructor, the _**TypeHelper.Factory**_
interface can be used. Create an inner class in the class to be registered that implements the interface;
```
global interface Factory {

    /**
     * @description
     * Builds a new instance of the class the factory is acting for.
     *
     * This would allow a Factory implementation to return a class which does not have a public constructor.
     *
     * @return The object instance.
     */
    Object newInstance();
}
```
The _**newInstance**_ method must return a new instance of the class to be bound to the property or abstract entity.
## Example Code
Please deploy the example code in the _**example/injection**_ directory to your org.

You must also assign the _**BindingManager**_ permission set to the user you will run the example code as in
Anonymous APEX.

The classes and interfaces in the _**QueryClasses**_ class will be used in the examples in this document.
## Initialisation
The registry may be initialised either programmatically or through the _**Binding__c**_ custom object.
#### Programmatic Initialisation
The _**Injection.add**_ methods can be called to add a binding to the registry. If an application requires a default
registry to be setup, the application must call these methods to add the bindings.

The following snippet taken from _**example/injection/classes/BindingInitalisation.cls**_ shows the initialisation of
a default registry.
```
 public static void programmatic() {

        // Add the bindings to the registry.
        Injection.add(QueryClasses.QueryInterface.class, QueryClasses.UserQueryInterfaceImpl.class);
        Injection.add(QueryClasses.AbstractQuery.class, QueryClasses.UserAbstractQueryImpl.class);
        Injection.add(QueryClasses.QueryInterface.class, 'SYSTEM', QueryClasses.SystemQueryInterfaceImpl.class);
        Injection.add(QueryClasses.AbstractQuery.class, 'SYSTEM', QueryClasses.SystemAbstractQueryImpl.class);
```
#### Custom Object Initialisation
The bindings can be configured using the _**Binding__c**_ custom object. The values in the custom object records will
override the bindings currently in the registry.

The fields of the custom object are;

| Field             | Type      | Description                                                                          |
|-------------------|-----------|--------------------------------------------------------------------------------------|
| Type__c           | Mandatory | The class name of the property or abstract entity to be bound.                       |
| Implementation__c | Mandatory | The class name of the concrete class that implements the abstract entity.            |
| Action__c         | Optional  | The action to be used in combination with the Type__c field to identity the binding. |

The following snippet taken from _**example/injection/classes/BindingInitalisation.cls**_ shows the initialisation of a
custom registry.
```
public static void custom() {
        clean();

        // Add the custom objects to create the bindings in the registry.
        insert new Binding__c(Type__c = 'QueryClasses.QueryInterface', Implementation__c = 'QueryClasses.UserQueryInterfaceImpl');
        insert new Binding__c(Type__c = 'QueryClasses.AbstractQuery', Implementation__c = 'QueryClasses.UserAbstractQueryImpl');
        insert new Binding__c(Type__c = 'QueryClasses.QueryInterface', Action__c = 'SYSTEM', Implementation__c = 'QueryClasses.SystemQueryInterfaceImpl');
        insert new Binding__c(Type__c = 'QueryClasses.AbstractQuery', Action__c = 'SYSTEM', Implementation__c = 'QueryClasses.SystemAbstractQueryImpl');
```
## Binding Validation
Validation of the implementation bound to a property or abstract entity class can be performed by adding a class that
implements the _**BindingCheck**_ interface;

```
global interface BindingCheck {

    /**
     * @description
     * Given a type to be bound, a class implementing this method must check that the given implementation class
     * can be bound to it.
     *
     * If the for type is an interface then an implementation of this method must check that the implementation
     * class implements the interface.
     *
     * If the for type is an abstract class then an implementation of this method must check that the implementation
     * class extends the abstract class.
     * 
     * If the for type is a class then an implementation of this method must check that the implementation
     * class is of the same class or a super class of it.
     *
     * @param forType The type to be bound.
     * @param withImpl The implementation to bind to the type.
     *
     * @return The result of the validation.
     */
    ValidationResult validate(Type forType, Type withImpl);
}
```

The _**BindingCheck__mdt**_ custom metadata object holds a mapping from the property or abstract entity to its
_**BindingCheck**_ validator.

The fields of the metadata object are;

| Field |Type | Description                                                                                             |
|-------|-----|---------------------------------------------------------------------------------------------------------|
| Type__c | Mandatory | The class name of the property or abstract entity to be validated.                                      |                                               
| Checker__c | Mandatory | The class name of the _**BindingCheck**_ implementation to validate the binding. |
| IsUnitTest__c | Mandatory | If true, the _**BindingCheck**_ is for unit test use only.                                              |

The _**BindingCheck.validate**_ method must return an _**Injection.ValidationResult**_ object which notifies the caller
of the result of the validation. If a failure notification is returned, an _**Injection.APIException**_ is thrown
with the message set to the value recorded in the _**ValidationResult.errorMessage**_ field.

The following snippet taken from _**example/injection/classes/InjectionInitalisation.cls**_ shows the _**BindingCheck**_
implementation used to validate that the _**QueryClasses.QueryInterface**_ interface has been assigned to a concrete
class that implements it.
```
 public class QueryInterfaceValidator implements Injection.BindingCheck {
        public Injection.ValidationResult validate(Type forType, Type withImpl) {
            if (TypeHelper.newInstance(withImpl) instanceof QueryClasses.QueryInterface) {
                return new Injection.ValidationResult(true, null);
            } else {
                return new Injection.ValidationResult(
                        false,
                        'Class "' + withImpl.getName() + '" does not implement "' + forType.getName() + '"'
                );
            }
        }
    }
}
```
_As an exercise, see if you can add a validator for the ```QueryClasses.AbstractQuery``` class._
## Wiring
Wiring is the action of injecting a binding into an application.

##### Property Binding
Values can be wired into an application as assignments to variables, including member variables.

The _**PropertyWiring**_ class in the examples directory shows how to wire a member variable into a class.
```
// The member variable 'properties' value is wired into the class on construction.
public final Map<String, Integer> properties =
        (Map<String, Integer>) Injection.wire(Map<String, Integer>.class, 'animals');
```
The default registry entry for the 'animals' _**Map**_ has 100 sheep, 50 cows and 2000 hens. If you execute
_**PropertyWiring.run()**_ in Anonymous APEX, you will see the following debug output.
```
DEBUG|The farm has 100 sheep
DEBUG|The farm has 50 cows
DEBUG|The farm has 2000 hens
```
You will see there is an inner class named _**NewConfiguration**_ in the _**PropertyWiring**_ class. This can be
used to override the base registry binding for the _**Map**_ setup in the test.

From an Anonymous APEX window, execute the following DML.
```
insert new Binding__c(Type__c = (Map<String, Integer>.class).getName(), Action__c = 'animals', Implementation__c = PropertyWiring.NewConfiguration.class.getName());```
```
The new registry entry for the 'animals' _**Map**_ has 1 sheep, 2 cows and 3 hens. If you execute
_**PropertyWiring.run()**_ in Anonymous APEX, you will see the following debug output.
```
DEBUG|The farm has 1 sheep
DEBUG|The farm has 2 cows
DEBUG|The farm has 3 hens
```
The new values have been successfully wired into the application.

Log on to your org. From the _**App Launcher**_ select Bindings. If you choose All, you will see the binding that was
added to bind the class with the new configuration to the 'animals' _**Map**_.

Delete the binding. Then run _**PropertyWiring.run()**_ in Anonymous APEX, you will see that the values displayed
are now the default values.

In the Bindings page, create a new record. Assign it the following values;
* Type : Map<String,Integer>
* Action: animals
* Implementation: PropertyWiring.NewConfiguration

Run _**PropertyWiring.run()**_ in Anonymous APEX, you will see that the new configuration values are displayed.

If this was production, you've just re-configured your application without having to create custom metadata, a custom
object or a custom setting to manage the configuration. To change the configuration, you just need to write a
new APEX class and add a binding to the registry.
