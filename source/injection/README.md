[back](../../README.md)
# Injection
The term "abstract entity" used in this document shall refer to either an interface or abstract class.

Dependency Injection (DI) is a software design pattern where an object receives its dependencies from an external source
rather than creating them internally. This promotes loose coupling, making code more modular, testable, and easier to
maintain. Instead of a class creating its own dependencies, it receives them as arguments (constructor injection),
properties (setter injection), or through an interface (abstract entity injection).

Thg _Injection_ class allows an abstract entity to be bound to a concrete implementation. It supports setter
and abstract entity injection. An application can use  one of the _wire()_ methods to perform injection. This allows
the same implementation class to be used in many places in the code base. It allows for the`implementation to be
changed application wide easily.

A custom object, _Binding__c_, may be used to configure the binding from the property or abstract entity to a
concrete class.

By default, the class wired into an application will be a singleton. For this reason, the implementation class must
not have state that may change in use.

If an implementation class is required to have state, then the class must implement the _Injection.Prototype_
interface.

## Bindings
A binding is the mapping from a property or abstract entity to its concrete implementation. The bindings are stored in
the _Injection_ class as a _Map_ called the registry. The key to the registry is the type of the 
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

To allow a class to be bound that has a private or protected no-op constructor, the _TypeHelper.Factory_
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
The _newInstance()_ method must return a new instance of the class to be bound to the property or abstract entity.
## Example Code
Please deploy the example code in the _example/injection_ directory to your org.

You must also assign the _BindingManager_ permission set to the user you will run the example code as in
Anonymous Apex.

## Initialisation
The registry may be initialised either programmatically or through the _Binding__c_ custom object.
### Programmatic Initialisation
The _Injection.add()_ methods can be called to add a binding to the registry. If an application requires a default
registry to be setup, the application must call these methods to add the bindings.

The following snippet taken from _example/injection/classes/BindingInitalisation.cls_ shows the initialisation of
a default registry.
```
 public static void programmatic() {

        // Add the bindings to the registry.
        Injection.add(QueryClasses.QueryInterface.class, QueryClasses.UserQueryInterfaceImpl.class);
        Injection.add(QueryClasses.AbstractQuery.class, QueryClasses.UserAbstractQueryImpl.class);
        Injection.add(QueryClasses.QueryInterface.class, 'SYSTEM', QueryClasses.SystemQueryInterfaceImpl.class);
        Injection.add(QueryClasses.AbstractQuery.class, 'SYSTEM', QueryClasses.SystemAbstractQueryImpl.class);
```
### Custom Object Initialisation
The bindings can be configured using the _Binding__c_ custom object. The values in the custom object records will
override the bindings currently in the registry.

The fields of the custom object are;

| Field             | Type      | Description                                                                          |
|-------------------|-----------|--------------------------------------------------------------------------------------|
| Type__c           | Mandatory | The class name of the property or abstract entity to be bound.                       |
| Implementation__c | Mandatory | The class name of the concrete class that implements the abstract entity.            |
| Action__c         | Optional  | The action to be used in combination with the Type__c field to identity the binding. |

The following snippet taken from _example/injection/classes/BindingInitalisation.cls_ shows the initialisation of a
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
implements the _BindingCheck_ interface;

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

The _BindingCheck__mdt_ custom metadata object holds a mapping from the property or abstract entity to its
_BindingCheck_ validator.

The fields of the metadata object are;

| Field |Type | Description                                                                                             |
|-------|-----|---------------------------------------------------------------------------------------------------------|
| Type__c | Mandatory | The class name of the property or abstract entity to be validated.                                      |                                               
| Checker__c | Mandatory | The class name of the _BindingCheck_ implementation to validate the binding. |
| IsUnitTest__c | Mandatory | If true, the _BindingCheck_ is for unit test use only.                                              |

The _BindingCheck.validate()_ method returns an _Injection.ValidationResult_ object which notifies the caller
of the result of the validation. If a failure notification is returned, an _Injection.APIException_ is thrown
with the message set to the value recorded in the _ValidationResult.errorMessage_ field.

The following snippet taken from _example/injection/classes/InjectionInitalisation.cls_ shows the _BindingCheck_
implementation used to validate that the _QueryClasses.QueryInterface_ interface has been assigned to a concrete
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
As an exercise, see if you can add a validator for the _QueryClasses.AbstractQuery_ class.
## Wiring
Wiring is the act of injecting a binding into an application. The binding can be assigned to an interface or abstract
class (abstract entity binding) or to a variable or member variable (property binding).

### Abstract Entity Wiring
Implementations of interfaces and abstract classes defined in the registry can be wired into an application. The
abstract entity will provide logic which can be invoked by the application, such as creating an _Account_.

The code snippet taken from _examples/injection/classes/AbstractEntityWiring_ class shows how to wire an interface
providing simple _Account_ management into an application.
```
// Application wires in the active AccountManager for the org.
AccountClasses.AccountManager manager =
        (AccountClasses.AccountManager) Injection.wire(AccountClasses.AccountManager.class);

// Then creates the account.
System.debug(manager.newAccount(name));

// And selects it.
System.debug([SELECT Id, Name FROM Account WHERE Name = :name]);
```
The default registry in the example has been configured to create the _Account_ synchronously.
```
// Setup a default registry. The default registry will configure the creation of the Account to be performed
// synchronously.
static {
    Injection.add(AccountClasses.AccountManager.class, AccountClasses.SyncAccountManager.class);
}
```
Run _AbstractEntityWiring.reset()_ in Anonymous Apex to clear any current Bindings for _AccountManager_.

Run _AbstractEntityWiring.example('Joe Blogs)_ in Anonymous Apex. You will see the following debug output. The
_Account_ has been created in the scope of the current request and can be SELECTed using SOQL.
```
USER_DEBUG|[23]|DEBUG|Account:{Name=Joe Bloggs, Id=****************}
DEBUG|(Account:{Id=****************, Name=Joe Bloggs})
```
There may be a use case for a customer where they don't want the new _Account_ to be returned by a SOQL SELECT
in the scope of the request. With the synchronous implementation of the interface, the _Account_
is created in the scope of the current request so will be returned by a SOQL SELECT.

How can we defer creation of the _Account_ till after the current request is completed? We can use an Apex Job.
We add an Apex Job to create the _Account_ and the job is run when the current request returns control to
Salesforce.

First, add the Binding to enable the creation of the _Account_ asynchronously. Log on to your org. From the
_App Launcher_ select Bindings. Create a new record. Assign it the following values;
* Type : AccountClasses.AccountManager
* Implementation: AsyncAccountClasses.AsyncAccountManager

Run _AbstractEntityWiring.example('Joe Blogs)_ in Anonymous Apex, you will see the following debug output.
```
USER_DEBUG|[23]|DEBUG|null
DEBUG|DEBUG|()
```
The second DEBUG statement shows that the _Account_ has not been created in the scope of the current request.

Confirm that an _Account_ named _Joe Bloggs_ has been created. And use _Setup > Apex Jobs_ to confirm that
a _Queueable_ of class _AccountClasses_ ran recently which created the _Account_.

For any customers who want the _Account_ to be created outside the scope of the current request, you can enable
that by simply adding a _Binding_ to their org. **No application logic needs to be changed.**

### Property Wiring
Values can be wired into an application as assignments to variables, including member variables.

This code snippet taken from _examples/injection/classes/PropertyWiring_ shows how to wire a member variable
into a class.
```
// The member variable 'properties' value is wired into the class on construction.
public final Map<String, Integer> properties =
        (Map<String, Integer>) Injection.wire(Map<String, Integer>.class, 'animals');
```
The default registry entry for the '_animals_' _Map_ has 100 sheep, 50 cows and 2000 hens. If you run
_PropertyWiring.run()_ in Anonymous Apex, you will see the following debug output.
```
DEBUG|The farm has 100 sheep
DEBUG|The farm has 50 cows
DEBUG|The farm has 2000 hens
```
You will see there is an inner class named _NewConfiguration_ in the _PropertyWiring_ class. This can be
used to override the base registry binding for the _Map_ setup in the test.

Run the following DML in Anonymous Apex.
```
insert new Binding__c(Type__c = (Map<String, Integer>.class).getName(), Action__c = 'animals', Implementation__c = PropertyWiring.NewConfiguration.class.getName());```
```
The new registry entry for the '_animals_' _Map_ has 1 sheep, 2 cows and 3 hens. If you run
_PropertyWiring.run()_ in Anonymous Apex, you will see the following debug output.
```
DEBUG|The farm has 1 sheep
DEBUG|The farm has 2 cows
DEBUG|The farm has 3 hens
```
The new values have been successfully wired into the application.

Log on to your org. From the _App Launcher_ select _Bindings_. If you choose _All_, you will see the binding that was
added to bind the class with the new configuration to the '_animals_' _Map_.

Delete the _Binding_. Then run _PropertyWiring.run()_ in Anonymous Apex, you will see that the values displayed
are now the default values.

In the _Bindings_ tab, create a new record. Assign it the following values;
* Type : Map<String,Integer>
* Action: animals
* Implementation: PropertyWiring.NewConfiguration

Run _PropertyWiring.run()_ in Anonymous Apex, you will see that the new configuration values are displayed.

If this was production, you've just re-configured your application without having to create custom metadata, a custom
object or a custom setting to manage the configuration. To change the configuration, you just need to write a
new Apex class and add a binding to the registry.

#### Checking a Wiring Exists
Trying to wire a _Type_ into an application for which there is no binding in the registry will throw an exception.
The _Injection.has()_ methods can be used to check if a binding exists.

The _examples/injection/classes/HasWiring_ class shows how to check whether a binding exists before wiring it
into an application.

Before running any of the example code, run _HasWiring.reset()_ from Anonymous Apex. This will clear all the
bindings for _AccountClasses.AccountManager_.

This code snippet from the _has()_ method shows how to test if a default binding exists.
```
// Check if a Binding exists for the AccountManager interface.
if (Injection.has(AccountClasses.AccountManager.class)) {
    
    // The Binding exists, it can be wired in and called.
    ((AccountClasses.AccountManager) Injection.wire(AccountClasses.AccountManager.class)).newAccount(name);
} else {
    System.debug('Wiring for AccountClasses.AccountManager does not exist');
}
```
Run _HasWiring.has('Joe Bloggs')_ from Anonymous Apex. You should see the following DEBUG message. This shows
that no Binding exists for the _AccountClasses.AccountManager_ interface.
```
DEBUG|Wiring for AccountClasses.AccountManager does not exist
```
Log on to your org. From the _App Launcher_ select _Bindings_. Create a new record. Assign it the following values;
* Type : AccountClasses.AccountManager
* Implementation: AccountClasses.SyncAccountManager

Run _HasWiring.has('Joe Bloggs')_ from Anonymous Apex. You should no longer see the DEBUG message recording
a non-existent binding. And an _Account_ named _Joe Bloggs_ should have been added to the org.

This code snippet from the _action()_ method shows how to test if a binding exists for a _Type_ and action.
In this example, the _Account_ will be created asynchronously using an Apex Job.
```
// Check if a Binding exists for the AccountManager interface with action ASYNC.
if (Injection.has(AccountClasses.AccountManager.class, 'ASYNC')) {

    // The Binding exists, it can be wired in and called.
    ((AccountClasses.AccountManager) Injection.wire(AccountClasses.AccountManager.class, 'ASYNC')).newAccount(name);
} else {
    System.debug('Wiring for AccountClasses.AccountManager with action ASYNC does not exist');
}
```
Run _HasWiring.action('Joe Bloggs')_ from Anonymous Apex. You should see the following DEBUG message. This shows
that no Binidng exists for the _AccountClasses.AccountManager_ interface.
```
DEBUG|Wiring for AccountClasses.AccountManager with action ASYNC does not exist
```
Log on to your org. From the _App Launcher_ select _Bindings_. Create a new record. Assign it the following values;
* Type : AccountClasses.AccountManager
* Action: ASYNC
* Implementation: AccountClasses.AsyncAccountManager

Run _HasWiring.action('Joe Bloggs')_ from Anonymous Apex. You should no longer see the DEBUG message recording
a non-existent binding. And an _Account_ named _Joe Bloggs_ should have been added to the org.

To check the _Account_ was added asynchronously, go to _Setup > Apex Jobs_ and confirm a _Queueable_
of class _AccountClasses_ was run.