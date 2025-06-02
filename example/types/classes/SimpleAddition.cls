/**
 * @description
 * Class showing how the SimpleAdditionAPI can be used to make a class O(pen/closed).
 *
 * @author Mark Brennand
 */

// The top level class implements the API so it can be mocked.
// And is virtual so it can be extended to add new methods.
// It must only have public methods that implement the API. This prevents an application casting the class instance
// to gain access to methods it shouldn't.
public with sharing virtual class SimpleAddition implements SimpleAdditionAPI {

    static {
        // Use the Factory to create the class so direct construction of the class can be prevented.
        Dependency.bind(SimpleAdditionAPI.class, SimpleAdditionFactory.class);
    }

    // TestVisible and not final so it can be overridden from a unit test to mock it.
    @TestVisible
    private static SimpleAdditionAPI INSTANCE = (SimpleAdditionAPI) Dependency.inject(SimpleAdditionAPI.class);

    // Hide the actual implementation from any access outside this class.
    private final Implementation impl = new Implementation();

    // The protected prevents construction from outside this class.
    // It allows a sub-class to call super().
    protected SimpleAddition() {}

    // Use the logic in the implementation hidden from access.
    public Integer add(final Integer value1, final Integer value2) {
        return impl.add(value1, value2);
    }

    // Hide the implementation from all access outside this class.
    private with sharing class Implementation implements SimpleAdditionAPI {

        // The implementation of the API method.
        public Integer add(final Integer value1, final Integer value2) {
            return value1 + value2;
        }
    }

    // Factory to create the class implementing the API.
    public with sharing class SimpleAdditionFactory implements Types.Factory {
        public Object newInstance() {
            return new SimpleAddition();
        }
    }

    // Accessor method for the API imeplmentation.
    public static SimpleAdditionAPI getInstance() {
        return INSTANCE;
    }

    // Called on registry initialisation to check bindings to SimpleAdditionAPI are valid.
    public with sharing class Validator implements Dependency.BindingCheck {
        public Dependency.ValidationResult validate(final Type forType, final Type withImpl) {
            if (Types.newInstance(withImpl) instanceof SimpleAdditionAPI) {
                return new Dependency.ValidationResult(true, null);
            } else {
                return new Dependency.ValidationResult(false, 'Type ' + forType.getName() + ' does not implement SimpleAdditionAPI');
            }
        }
    }
}