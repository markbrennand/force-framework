/**
 * @description
 * Class showing how an API can be defined.
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
     */
    global with sharing class BindingCheck implements forcefw.Dependency.BindingCheck {
        public forcefw.Dependency.ValidationResult validate(final Type forType, final Type withImpl) {
            if (forcefw.TypesV1.newInstance(withImpl) instanceof API) {
                return new forcefw.Dependency.ValidationResult(true, null);
            } else {
                return new forcefw.Dependency.ValidationResult(false, 'Type ' + withImpl.getName() + ' does not implement SimpleAddition.API');
            }
        }
    }
}
