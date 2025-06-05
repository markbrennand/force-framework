# Overview
A suite of APIs that have been developed to aid in Apex development.

Built with SOLID Principles, Separation of Concerns and Clean code in mind.

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

# Framework APIs
The Force Framework comprises the following APIs. 

## Types
The S of SOLID is Single Use Only. The API for access to Apex types allows classes to
be developed which are not publicly accessible and allow only the use of the methods defined in the
interface they implement. This provides Separation of Concern, as an application will
be limited to calling ony the methods of the interface. An application will be unable to construct an instance of the
concrete class providing the interface. This helps to prevent the use of the class for something other than its
single use.

The O of SOLID is Open Closed. A class is Open for extension and Closed for modification. The pattern used in classes
using this API meets this requirement.

See [Types](source/types/README.md)

## Dependency Injection
The D of SOLID is Dependency Inversion. This requires that functionality is abstracted into interfaces or abstract
classes. An application must then only use the interface rather than its concrete implementation. To aid in this,
frameworks such as Spring for Java, support Dependency Injection. This allows the implementation of the interface to be
bound into the application at run time. This is not something supported natively by Apex. This API
allows the initialisation of a registry either programmatically or from a custom object. Once initialised, dependencies
can be injected into an Apex application from the Apex _Type_ of the interface the application wants to use.

See [Dependency Injection](source/dependency/README.md)

## Asynchronous
Apex provides the ability to run code asynchronously using the _Queueable_ interface and _System.enqueueJob_.
Determining why a job failed is not easy. Re-running the job on failure is not something supported
by Apex Jobs. Any concurrency restrictions for the Apex Job would need to be coded in the application.
These issues, and more, are addressed by the Asynchronous API. Jobs can be started
using the _Asynchronous_ class and their progress can be monitored from a custom object. The API
will guarantee that the number of jobs running will always be the maximum concurrency set for the type
of job or less. The API will re-try a job on failure upto the maximum number of re-tries set for
the job on its creation.

See [Asynchronous](source/asynchronous/README.md)

## Mocking
An API for a new way of mocking. In most mocking solutions, methods and their expected arguments are defined.
There is redundancy in that solution as many methods in a class may take the same arguments. In the solution in
this API, first the arguments are defined and then the methods expecting those arguments are listed.

See [Mocking](source/mocker/README.md)

