[back](../../README.md)
# Dependency Injection
Dependency Injection (DI) is a software design pattern where an object receives its dependencies from an external source
rather than creating them internally. This promotes loose coupling, making code more modular, testable, and easier to
maintain. Instead of a class creating its own dependencies, it receives them as arguments (constructor injection),
properties (setter injection), or through an interface (abstract entity injection).  The term "abstract entity" used
in this document shall refer to either an interface or abstract class.

Thg _DependencyV1_ class allows an abstract entity to be bound to a concrete implementation. It supports setter
and abstract entity injection. An application can use  one of the _inject_ methods to perform injection. This allows
the same implementation class to be used in many places in the code base. It allows for the`implementation to be
changed application wide easily.

The custom object, _Binding__c_, may be used to configure the binding from the property or abstract entity to a
concrete class.

By default, the class injected into an application will be a singleton. For this reason, the implementation class must
not have state that may change in use.

If an implementation class is required to have state, then the class must implement the _DependencyV1.Prototype_
interface.

See the reference [Apex docs](../../docs/SfApexDocs/dependencyv1.html) for the API. It is suggested that you keep a page open with the
Apex docs loaded for your reference whilst reading this page.

If you wish to try the _Dependency Injection_ example code, see [Geting Started](../../GETTINGSTARTED.md).

## Bindings
A binding is the mapping from a property or abstract entity to its concrete implementation. The bindings are stored in
the _DependencyV1_ class as a _Map_ called the registry. The key to the registry is the _Type_ of the property or
abstract entity.

Two types of binding are supported.
* A binding to an abstract entity. **Property injection is not supported for this binding.**
* A binding to a property or abstract entity with an associated action.

For the first type, the abstract entity can only have one binding in the registry.

The second type can have multiple bindings of the property or abstract entity in the registry. Each must have a unique
action.

## Implementation Classes
Each implementation class must have a public or global no-op constructor. An exception will be thrown if an attempt
is made to bind an abstract entity to a class that doesn't. To allow a class to be bound that has a private or
protected no-op constructor, the _TypesV1.Factory_ interface can be used. Create an inner class in the class to be
registered that implements the interface.

See [Types](../types/README.md) for more information.

## Initialisation
The registry may be initialised either programmatically or through the _Binding__c_ custom object.

See [BindingInitialisation.cls](https://github.com/markbrennand/force-frameworks/tree/gh-pages/example/dependency/classes/BindingInitialisation.cls)
for examples of programmatic and custom object binding initialisation.

### Programmatic Initialisation
Programmatic initialisation can be performed using the _DependencyV1.bind_ method. If an application requires a
default registry to be setup, the application must call these methods to add the bindings.

### Custom Object Initialisation
The bindings can be configured using the _Binding__c_ custom object. The values in the custom object records will
override the bindings currently in the registry.

The fields of the custom object are.

| Field             | Type      | Description                                                                          |
|-------------------|-----------|--------------------------------------------------------------------------------------|
| Type__c           | Mandatory | The class name of the property or abstract entity to be bound.                       |
| Implementation__c | Mandatory | The class name of the concrete class that implements the abstract entity.            |
| Action__c         | Optional  | The action to be used in combination with the Type__c field to identity the binding. |

## Binding Validation
All _Types_ to be bound to an implementation will be validated as they are bound. Any new _Type_ to be bound must have
a validator registered for the _Type_. To do this, a new _BindingCheck_ metadata record must be added which defines the
validator used to validate the _Type_.

Validation of the implementation bound to a _Type_ is performed by adding a class that implements the
_Dependency.BindingCheck_ interface and registering it in a custom metadata for the _Type_.
record.

The _BindingCheck__mdt_ custom metadata object has the following fields;

| Field           |Type | Description                                                                                             |
|-----------------|-----|---------------------------------------------------------------------------------------------------------|
| Type__c         | Mandatory | The class name of the property or abstract entity to be validated.                                      |                                               
| BindingCheck__c | Mandatory | The class name of the _BindingCheck_ implementation to validate the binding. |
| IsUnitTest__c   | Mandatory | If true, the _BindingCheck_ is for unit test use only.                                              |

The _BindingCheck.validate_ method returns a _Dependency.ValidationResult_ object which notifies the caller
of the result of the validation. If a failure notification is returned, a _DependencyV1.APIException_ is thrown
with the message set to the value recorded in the _ValidationResult.errorMessage_ field.

The _classes/BindingChecks.cls_ class and _customMetadata_ directory in the
[example](https://github.com/markbrennand/force-frameworks/tree/gh-pages/example/dependency) directory show how to
register a _BindingCheck_ for each of the example classes.

**Important: An Exception will be thrown on the first use of the _DependencyV1_ class if any of the bindings added to it
either programmatically, or from the custom object, do not have a _BindingCheck_ class to validate it.**

## Injection
Injection is the import of the concrete class bound to the _Type_ into an application . The binding can be assigned to
an interface or abstract class (abstract entity binding) or to a variable or member variable (property binding).

### Abstract Entity Injection
Implementations of interfaces and abstract classes defined in the registry can be injected into an application. The
abstract entity implementation should provide functionality restricted to an interface or abstract class. To meet the
Single Use of SOLID and Separation of Concerns requirements, it must not be possible to cast the injected abstract
entity to its implementation class to access additional functionality.

See [AbstractEntityInjection.cls](https://github.com/markbrennand/force-frameworks/tree/gh-pages/example/dependency/classes/AbstractEntityInjection.cls)
for an example of injecting an abstract entity.

The default binding in the example has been configured to create the _Account_ synchronously.

Run _AbstractEntityInjection.reset_ in Anonymous Apex to clear any current Bindings for _AccountManager_.

Run _AbstractEntityInjection.example('Joe Blogs)_ in Anonymous Apex. You will see the following debug output. The
_Account_ has been created in the scope of the current request and can be SELECTed using SOQL.
```
USER_DEBUG|[23]|DEBUG|Account:{Name=Joe Bloggs, Id=****************}
DEBUG|(Account:{Id=****************, Name=Joe Bloggs})
```

There may be a use case for a customer where they don't want the new _Account_ to be returned by a SOQL SELECT
in the scope of the request. With the synchronous implementation of the interface, the _Account_
is created in the scope of the current request so will always be returned by a SOQL SELECT.

How can we defer creation of the _Account_ till after the current request is completed? We can use an Apex Job.
Add an Apex Job to create the _Account_ and the job will be run when the current request returns control to
Salesforce.

To try this out, add the binding to enable the creation of the _Account_ asynchronously. Log on to your org. From the
_App Launcher_ select _Force Framework_. Select the _Dependency Bindings_ tab. Create a new record. Assign it the
following values.

| Field | Value                              |
| ----- |------------------------------------|
| Type | AccountClasses.AccountManager      |
| Implementation | AccountClasses.AsyncAccountManager |

Run _AbstractEntityInjection.example('Joe Blogs)_ in Anonymous Apex, you will see the following debug output.
```
USER_DEBUG|[23]|DEBUG|null
DEBUG|DEBUG|()
```
The second DEBUG statement shows that the _Account_ has not been created in the scope of the current request.

Confirm that an _Account_ named _Joe Bloggs_ has been created. And use _Setup > Apex Jobs_ to confirm that
a _Queueable_ of class _AccountClasses_ ran recently which created the _Account_.

For any customers who want the _Account_ to be created outside the scope of the current request, you can enable
that by simply adding a _Binding_ to their org. No application logic needs to be changed.

### Property Injection
Values can be injected into an application as assignments to variables, including member variables.

See [PropertyInjection.cls](https://github.com/markbrennand/force-frameworks/tree/gh-pages/example/dependency/classes/PropertyInjection.cls)
for an example of injecting a property.

The default registry entry for the _animals_ _Map_ has 100 sheep, 50 cows and 2000 hens. If you run
_PropertyInjection.run_ in Anonymous Apex, you will see the following debug output.
```
DEBUG|The farm has 100 sheep
DEBUG|The farm has 50 cows
DEBUG|The farm has 2000 hens
```

There is an inner class named _NewConfiguration_ in the _PropertyInjection_ class. This can be used to override the base
registry binding for the _Map_ setup in the test.

Run the following DML in Anonymous Apex. If using the Force Framework package, you will need to add the package
namespace, forcefw__, to the object and the fields.
```
insert new Binding__c(Type__c = (Map<String, Integer>.class).getName(), Action__c = 'animals', Implementation__c = PropertyInjection.NewConfiguration.class.getName());```
```
The new registry entry for the _animals_ _Map_ has 1 sheep, 2 cows and 3 hens. If you run _PropertyInjection.run_ in Anonymous Apex, you will see the following debug output.
```
DEBUG|The farm has 1 sheep
DEBUG|The farm has 2 cows
DEBUG|The farm has 3 hens
```
The new values have been successfully injected into the application.

Log on to your org. From the _App Launcher_ select _Force Framework_. Select the _Dependency Bindings_ tab. If you
choose _All_, you will see the binding that was  added to bind the class with the new configuration to the _animals_
_Map_.

Delete the _Binding_. Then run _PropertyInjection.run_ in Anonymous Apex, you will see that the values displayed
are now the default values.

In the _Dependency Bindings_ tab, create a new record. Assign it the following values.

| Field | Value                              |
| ----- |------------------------------------|
| Type | Map<String,Integer> |
| Action | animals |
| Implementation | PropertyInjection.NewConfiguration |

Run _PropertyInjection.run_ in Anonymous Apex, you will see that the new configuration values are displayed.

If this was production, you'd have just re-configured your application without having to create custom metadata, a custom
object or a custom setting to manage the configuration. To change the configuration, you just need to write a
new Apex class and add a binding to the registry.

#### Checking an Injection Exists
Trying to inject a _Type_ into an application for which there is no binding in the registry will throw an Exception.
The _DependencyV1.isBound_ methods can be used to check if a binding exists.

See [HasInjection.cls](https://github.com/markbrennand/force-frameworks/tree/gh-pages/example/dependency/classes/HasInjection.cls)
for an example of checking for a binding's existence.

Before running any of the example code, run _HasInjection.reset_ from Anonymous Apex. This will clear all the
bindings for _AccountClasses.AccountManager_.

Run _HasInjection.has('Joe Bloggs')_ from Anonymous Apex. You should see the following DEBUG message. This shows
that no Binding exists for the _AccountClasses.AccountManager_ interface.

```
DEBUG|Injection for AccountClasses.AccountManager does not exist
```

Log on to your org. From the _App Launcher_ select _Force Framework_. Select the _Dependency Bindings_ tab. Create a
new record. Assign it the following values;

| Field | Value                             |
| ----- |-----------------------------------|
| Type | AccountClasses.AccountManager     |
| Implementation | AccountClasses.SyncAccountManager |

Run _HasInjection.has('Joe Bloggs')_ from Anonymous Apex. You should no longer see the DEBUG message recording
a non-existent binding. And an _Account_ named _Joe Bloggs_ should have been added to the org.

Run _HasInjection.action('Joe Bloggs')_ from Anonymous Apex. You should see the following DEBUG message. This shows
that no Binding exists for the _AccountClasses.AccountManager_ interface with an action of ASYNC.
```
DEBUG|Injection for AccountClasses.AccountManager with action ASYNC does not exist
```

Log on to your org. From the _App Launcher_ select _Force Framework_. Select the _Dependency Bindings_ tab. Create a
new record. Assign it the following  values.

| Field | Value                              |
| ----- |------------------------------------|
| Type | AccountClasses.AccountManager      |
| Action | ASYNC |
| Implementation | AccountClasses.AsyncAccountManager |


Run _HasInjection..action('Joe Bloggs')_ from Anonymous Apex. You should no longer see the DEBUG message recording
a non-existent binding. And an _Account_ named _Joe Bloggs_ should have been added to the org.

To check the _Account_ was added asynchronously, go to _Setup > Apex Jobs_ and confirm a _Queueable_
of class _AccountClasses_ was run.
