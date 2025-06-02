[back](../../README.md)
# Types
The Types API is used to instantiate an instance of an Apex _Type_.

The _Type_ constructed must have a no-op  constructor.

It supports a feature not available in the Apex _Type.newInstance_ method. This new feature is the
_Types.Factory_ interface. If the _Type_ passed to the _Types.newInstance_ method is an instance of _Factory_,
it will call the _newInstance_ method of the _Factory_ implementation to create the instance.

The Apex docs for the Types API can be viewed [here](SfApexDocs/types.html).

What are the use cases for _Factory_?
### Class Globality
If you're using the Force Frameworks package, the code for that package is in the _forcefw_ namespace. Taking
_Dependency Injection_ as an example, you would need to make any implementation classes global, otherwise
the _Dependency_ class in the _forcefw_ namespace would not be able to construct your class. Making classes global
results in several issues including not being able to make any changes to global methods after they've been released
in a package.

A better solution is for your implementation class to implement an interface with public methods and then have a
global _Factory_ class that returns an instance of your public implementation class from its _getInstance_ method.

In the following example, you can see that the _Types_ API can be used to create an implementation class for an
interface that can be injected into an application using the Force Frameworks package without having to make the
class global.
```
// The interface needs to be global, so it can be accessed by the forcefw namespace when creating the binding.
//
global interface Example {
    void doSomething();
}

// Public class implementation of the interface. It doesn't need to be global as it will be constructed from the
// global ExampleFactory class which is in the same namespace as this class.
//
public class ExampleImpl implements Example {
    public void doSomething() {
        System.debug('Did something');
    }
}

// Making the class global means it can be constructed in the forecew namespace.
//
global class ExampleFactory implements Types.Factory {
    global Object getInstance() {
    
        // A new instance of the public class is returned. All the interface methods coded in this class are
        // accessible in any namespace.
        //
        return new ExampleImpl();
    }
}
### Open/Closed Classes