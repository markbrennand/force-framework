# SF-Frameworks
A suite of frameworks that have been developed to aid in APEX development.

Built with SOLID principles and clean code in mind.

## Injection
The D of SOLID is Dependency Injection. This is not something supported natively by APEX. The framework developed
allows the initialisation of a registry either programmatically or from a custom object. Once initialised, dependencies
can be wired into APEX code.

See [Injection](source/injection/README.md)