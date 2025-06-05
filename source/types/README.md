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
Dependency Injection as an example, you would need to make any implementation classes global, otherwise
the _Dependency_ class in the _forcefw_ namespace would not be able to construct your class. Making classes global
results in several issues including not being able to make any changes to global methods after they've been released
in a package.

A better solution is for your implementation class to implement an interface with public methods and then have a
global _Factory_ class that returns an instance of your public implementation class from its _newInstance_ method.

In the following example, you can see that the _Types_ API can be used to create an implementation class for an
interface that can be injected into an application using the Force Frameworks package without having to make the
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
global class ExampleInterfaceFactory implements forcefw.Types.Factory {

    // Note that as the interface is being used, we don't have to make the method global.
    public Object newInstance() {
    
        // A new instance of the public class is returned. All the interface methods coded in this class are
        // accessible in any namespace.
        //
        return new ExampleInterfaceImpl();
    }
}
```
### Open/Closed Classes
The pattern for API classes developed in the Framework is for the class to contain an interface which defines
the functionality offered by the class. The class must ensure it only has public methods for the interface
methods. If there were other public methods, an application could cast the interface to the class and use
functionality in the class that is not part of the interface. This would break the Separation of Concern requirement.

The class itself implements the interface defined in the class. Why is this necessary? The reason is mocking.
Apex will not allow you to stub an inner class, and in this case, the interface is an inner class.
So, making the class implement the interface means the class can be stubbed to provide a mock version of it.

The class must be declared as virtual. This allows it to be extended. As the public methods implementing
the interface are not virtual, they cannot be changed. Hence, meeting the Open for extension, closed for modification
of SOLID.

The class must have a _Type.Factory_ inner class that returns a new instance of the class from its _newInstance_
method.

The class's constructor must be protected. This is to prevent the class being constructed from anywhere other than the
_Type.Factory_ inner class. If the class had a public constructor, the application would be able to construct its
own instances of the class and would be able to bypass any Dependency Injection required for the class.

As the class's constructor is protected and the class is virtual, a new class can be written which extends it.

### Example Code
To see an example of the pattern used for an extensible class, deploy the code at the following URL.

https://github.com/markbrennand/force-frameworks/tree/gh-pages/example/types

The _SimpleAddition_ class illustrates the pattern used for classes in the Framework. The _ExtendedAddition_
class shows how the class can be extended to offer additional functionality.

After deploying the code to an org, you can run the following Anonymous Apex to test it.
```
System.debug(SimpleAddition.getInstance().add(1, 2));
System.debug(new ExtendedAddition().add(3, 4));
System.debug(new ExtendedAddition().fibonacci(5));
```


