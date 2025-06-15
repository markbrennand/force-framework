[back](../../README.md)
# Types 
The Types API is used to instantiate an instance of an Apex _Type_.

The _Type_ constructed must have a no-op  constructor.

It supports a feature not available in the Apex _Type.newInstance_ method. This new feature is the
_TypesV1.Factory_ interface. If the _Type_ passed to the _TypesV1.newInstance_ method is an instance of _Factory_,
it will call the _newInstance_ method of the _Factory_ implementation to create the instance.

See the reference [Apex docs](SfApexDocs/typesv1.html) for the API. It is suggested that you keep a page open with
the Apex docs  loaded for your reference whilst reading this page.

If you wish to try the _Types_ example code , see [Geting Started](../../GETTINGSTARTED.md).

### Use Case - Reduce Need For Global Classes
If you're using the Force Framework package, the code for that package is in the _forcefw_ namespace. Taking
Dependency Injection as an example, you would need to make any implementation classes global, otherwise
the _Dependency_ class in the _forcefw_ namespace would not be able to construct your class. Making classes global
results in several issues including not being able to make any changes to global methods after they've been released
in a package.

An alternative solution is for your implementation class to implement an interface with public methods and then have a
global _Factory_ class that returns an instance of your public implementation class from its _newInstance_ method.
The _Factory_ class would be added as a Dependency binding registered for the interface. When the interface
is injected into an application, the _Factory_ class's _newInstance_ method is called and the public implementation
is injected.

In the following example, you can see that the _Types_ API can be used to create an implementation class for an
interface that can be injected into an application using the Force Framework package without having to make the
class global.
```
// The interface needs to be global, so it can be accessed by the forcefw namespace when creating the binding.
//
global interface ExampleInterface {
    void doSomething();
}

// Public class implementation of the interface. It doesn't need to be global as it will be constructed from the
// global ExampleFactory class which is in the same namespace as this class.
//
public class ExampleInterfaceImpl implements ExampleInterface {
    public void doSomething() {
        System.debug('Did something');
    }
}

// Making the class global means it can be constructed in the forecew namespace.
//
global class ExampleInterfaceFactory implements forcefw.TypesV1.Factory {

    // Note that as the interface is being used, we don't have to make the method global.
    public Object newInstance() {
    
        // A new instance of the public class is returned. All the interface methods coded in this class are
        // accessible in any namespace.
        //
        return new ExampleInterfaceImpl();
    }
}
```
### Example Code
The _SimpleAddition_ class in the examples (or examples.pkg) directory shows how to develop an API which is
only accessible to the application through the interface it provides.

After deploying the code to an org, you can run the following Anonymous Apex to test it.
```
System.debug(SimpleAddition.sum(new List<Integer> { 1, 2, 3 ,4 }));
```


