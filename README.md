# SF-Frameworks
A suite of frameworks that have been developed to aid in APEX development.

Built with SOLID principles and clean code in mind.

## Dependency Injection
The D of SOLID is Dependency Injection. This is not something supported natively by APEX. The framework developed
allows the initialisation of a registry either programmatically or from a custom object. Once initialised, dependencies
can be wired into APEX code.

See [Dependency Injection](source/dependency/README.md)

## Asynchronous
Apex provides the ability to run code asynchronously using the _Queueable_ interface and _System.enqueueJob_.
Determining why a job failed is not easy. Re-running the job on failure is not something supported
by Apex Jobs. Any concurrency restrictions for the Apex Job would need to be coded in the application.
These issues, and more, are addressed by the Asynchronous framework. Jobs can be started
using the _Asynchronous_ class and their progress can be monitored from a custom object. The framework
will guarantee that the number of jobs running will always be the maximum concurrency set for the type
of job or less. The framework will re-try a job on failure upto the maximum number of re-tries set for
the job on its creation.

See [Asynchronous](source/asynchronous/README.md)

## Mocking
A Framework for a new way of mocking is included. Rather than defining the method and arguments expected, as
is the normal way of mocking. Redundancy was identified in the arguments in those definitions. In the solution in
this framework, first the arguments are defined and then the methods expecting those arguments are defined.

See [Mocking](source/mocker/README.md)

