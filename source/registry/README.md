# Registry
A registry allowing interfaces and abstract classes to be bound to their concrete implementations. The binding can be
wired  into an application. This allows for the same implementation class to be used in many places in the code base.
It also allows for the implementation to be changed application wide easily.

By default, the class wired into an application will be a singleton. For this reason, the implementation class must
not have state that may change in use.

If an implementation class is required to have state, then the class must implement the ```Registry.Prototype```
interface.

## Wiring
Wiring is the action of using a binding in an application.

For example, say the application has an interface for querying.
```
public interace Query {
    List<SObject> query(String query, Map<String, Object> bindVariables
}
```
And an implementation of the interface.
```
public class QueryImpl implements Query {
    public List<SObject> query(String query, Map<String, Object> bindVars) {
        return Database.queryWithBinds(query, bindVars, AccessLevel.USER_MODE);
    }
}
```