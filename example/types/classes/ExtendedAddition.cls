/**
 * @description
 * Example of extending an existing class.
 *
 * @author Mark Brennand
 */

// Note: we cannot override the add() method in the base class, as it is not declared virtual.
// This makes the classes truly O(open/closed). The base class can be extended but not modified.
public with sharing class ExtendedAddition extends SimpleAddition implements ExtendedAdditionAPI {

    // For this example, we're not going to hide the class from unwanted access.
    public ExtendedAddition() {
        super();
    }

    // Provide the implementation of the new method.
    public Integer fibonacci(final Integer count) {
        Integer value = 0;
        Integer prev1 = 1;
        Integer prev2 = 0;

        for (Integer i = 0; i < count; i++) {
            // Use the method in the base class.
            value = add(prev1, prev2);

            prev2 = prev1;
            prev1 = value;
        }

        return value;
    }
}