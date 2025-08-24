# Overview
A suite of APIs that have been developed to aid in Apex development.

Built with SOLID Principles, Separation of Concerns and Clean code in mind.

See [Documentation](https://markbrennand.github.io/force-framework/) for navigable project documentation pages.

#### SOLID Principles
SOLID is a set of five design principles in object-oriented programming that helps developers create more maintainable,
extensible, and understandable software. These principles are: Single Responsibility Principle, Open/Closed Principle,
Liskov Substitution Principle, Interface Segregation Principle, and Dependency Inversion Principle.

#### Separation of Concerns
Separation of Concerns (SoC) is a design principle in software development that encourages breaking down a complex
program into distinct, independent, and manageable parts. Each part, or "concern," focuses on a specific aspect of the
program, reducing overlap and making the code more maintainable and easier to understand.

#### Clean Code
Clean code, in essence, is software that is written in a way that is easy to read, understand, and maintain. It's about
prioritizing readability and maintainability, making it easier for other developers (or even yourself in the future) to
modify or extend the code. Clean code follows established conventions, standards, and practices to ensure it's simple,
concise, and expressive.

# Getting Started
See [here](GETTINGSTARTED.md) for information on how to deploy the code or package to an org, configure the org
for _Force Framework_ use, and set up the example code.

# Framework APIs
The Force Framework comprises the following APIs. 

See the reference [Apex docs](docs/SfApexDocs/index.html) for all the APIs in the suite.

## Types
The S of SOLID is Single Use Only. The API for access to Apex types allows classes to be developed which are not
publicly accessible and allow only the use of the methods defined in the interface they implement.

This provides Separation of Concern, as an application will be limited to calling ony the methods of the interface.
An application will be unable to construct an instance of the concrete class providing the interface. This helps to
prevent the use of the class for something other than its single use.

See [Types](source/types/README.md)

## Dependency Injection
The D of SOLID is Dependency Inversion. This requires that functionality is abstracted into interfaces or abstract
classes. An application must then only use the interface rather than its concrete implementation. To aid in this,
frameworks such as Spring for Java, support Dependency Injection. This allows the implementation of the interface to be
bound into the application at run time.

This is not something supported natively by Apex. This API  allows the initialisation of a registry either
programmatically or from a custom object. Once initialised, dependencies can be injected into an Apex application from
the Apex _Type_ of the interface the application wants to use.

See [Dependency Injection](source/dependency/README.md)

## Asynchronous
Apex provides the ability to run code asynchronously using the _Queueable_ interface and _System.enqueueJob_.
Determining why a job failed is not easy. Re-running the job on failure is not something supported
by Apex Jobs. Any concurrency restrictions for the Apex Job would need to be coded in the application. 

These issues, and more, are addressed by the Asynchronous API. Jobs can be started using the _Asynchronous_ class and
their progress can be monitored from a custom object. The API will guarantee that the number of jobs running will
always be the maximum concurrency set for the type of job or less. The API will re-try a job on failure upto the
maximum number of re-tries set for the job on its creation.

See [Asynchronous](source/asynchronous/README.md)

## Mocker
In a unit test, mock objects can simulate the behavior of complex, real objects and are therefore useful when a real
object is impractical or impossible to incorporate into a unit test. The Force Framework suite includes an API for 
mocking.

In most mocking solutions, methods and their expected arguments are defined individually. There is redundancy
in that solution as methods in a class may take the same arguments. For example, a class may have several getter
methods, all of which have no argument. The Mocker API first defines the arguments (including no arguments) and then
the methods expecting those arguments are assigned to them. The solution is defined to be chained allowing  a full
mocking for a class to be defined in a single statement.

See [Mocker](source/mocker/README.md)

## Trigger
A lightweight API for Trigger development. The _TriggersV1.Subscriber_ class can be implemented to code the logic for
a trigger. A subscriber can be bound to the object type it wishes to receive events for by creating a _Trigger__mdt_
custom metadata record for it. The object's trigger should be set to receive on before and on after notifications
for all three of the operations. To send an event representing the trigger to each subscriber bound to the object
type the trigger fired for, it must call the _TriggerV1.publish_ method. The Trigger API will then create an event
and send it to all the subscribers.

Should the trigger perform DML that causes the same trigger to be fired, this is classed as a recursive call. The
_Trigger__mdt__ custom metadatga record defines the maximum recursive depth for each subscriber. If set (value > 0),
when exceeded, the metadata record also defines;
- Whether an _Exception_ is thrown.
- Whether to ignore the recursive call by not sending the event to the subscriber. 

See [Trigger](source/trigger/README.md)

## Array
The Array API provides a new way to iterate over array elements and process them. It is styled on the non-mutating
Javascript methods, e.g. _forEach_ and _reduce_. As Apex does not support passing a function by reference or
anyonymous inner classes, the callback method used in the Javascript methods is replaced by the
_ArrayIteratorV1.Callback_ class. The _function_ method of this class must be overridden to code the required logic.

See [Array](source/array/README.md)

## Optional
The use of null to represent an undefined value is bad practice. Apex lacks the _undefined_ variable value of Javascript.
A solution to this problem was added to Java several versions ago. The Optional class. This class allows a value
to be represented, including no value. The static _empty_, _of_ and _ofNullable_ methods may be used to create an
Optional representing no value by the first method, and a value by the remaining methods. Use the _isPresent_
method to determine whether the Optional has a value. Use _get_ to obtain the value. An _NoSuchElelemtException_
will be thrown if an attempt is made to get an undefined value from an Optional.

See [Optional](source/optional/README.md)

## Query
TBD.

See [Query](source/query/README.md)

## Collection
TBD.

See [Collection](source/collection/README.md)
