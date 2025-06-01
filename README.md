# Overview
A suite of APIs that have been developed to aid in Apex development.

Built with SOLID principles and clean code in mind.

## Dependency Injection
The D of SOLID is Dependency Injection. This is not something supported natively by Apex. The API developed
allows the initialisation of a registry either programmatically or from a custom object. Once initialised, dependencies
can be wired into Apex code.

See [Dependency Injection](source/dependency/README.md)

## Types
The S of SOLID is Single Use Only. The API developed for access to Apex types allows classes to
be developed which are not publicly accessible and allow only the use of the methods defined in the
interface they implement by an application.

See [Types](source/types/README.md)

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

