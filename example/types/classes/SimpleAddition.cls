/**
 * @description
 * Class showing how an API can be defined.
 *
 * The class enforces Separation of Concern by ensuring the only access to the API is through the global
 * method that calls the API itself.
 *
 * @author Mark Brennand
 */
global with sharing class SimpleAddition {

    /**
     * @description
     * The interface defining the methods that form the class's API.
     *
     * The interface has to be global so it can be injected when the Force Framework package is in use and the
     * Dependency class is in a different namespace.
     */
    global interface API {

        /**
         * @description
         * Returns the sum of the given integers.
         *
         * @param values The integers to sum.
         *
         * @return The sum of the values.
         */
        Integer sum(List<Integer>  values);
    }


    /**
     * @description
     * Method providing application access to API.
     */
    global static Integer sum(List<Integer> values) {
        return SimpleAdditionImpl.INJECT.sum(values);
    }

    /**
     * @description
     * Called on registry initialisation to check bindings to SimpleAddition.API are valid.
     *
     * It is global as when called from Dependency class in Force Framework package, this class will be in a
     * different namespace.
     */
    global with sharing class BindingCheck implements DependencyV1.BindingCheck {
        public DependencyV1.ValidationResult validate(final Type forType, final Type withImpl) {
            if (TypesV1.newInstance(withImpl) instanceof API) {
                return new DependencyV1.ValidationResult(true, null);
            } else {
                return new DependencyV1.ValidationResult(false, 'Type ' + withImpl.getName() + ' does not implement SimpleAddition.API');
            }
        }
    }
}
