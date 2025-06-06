/**
 * @description
 * Class providing the Apex Type API.
 * <br><br>
 * An instance of an Apex Type may be constructed by calling the newInstance method.
 * <br><br>
 * If the newInstance method constructs an implementation of the Factory interface then the newInstance method of
 * the Factory implementation is called to construct the object. This can be used to hide the constructor of the
 * object from the application. For example, say we want to prevent construction of a class by the application.
 * A class can be written that has a private constructor. The Type.newInstance method would be unable to construct an
 * instance of the class. To allow construction, the class would add a public inner class implementing Factory.
 * This method can create an instance the class with the private constructor. To construct the class, call
 * Types.newInstance, passing the inner Factory class as argument.
 * <br><br>
 * The Factory is intended to be used to prevent the mis-use of an implementation of an interface. The application's
 * only access to the class would be through the interface it implements. The S of SOLID is Single Use Only. The
 * Factory is a way of enforcing this, as the class implementing the interface will only have the use defined by the
 * interface it
 * implements.
 * <br><br>
 * See <a href=../README.md target="_blank">README</a> for full details of the Types API.
 *
 * @author Mark Brennand
 */
global with sharing class Types {

    /**
     * @description
     * Supports use of a factory when instantiating a class.
     * <br><br>
     * If an instantiated class implements this interface then the newInstance method will create the actual instance.
     */
    global interface Factory {

        /**
         * @description
         * Builds a new instance of the class the factory is acting for.
         * <br><br>
         * This would allow a Factory implementation to return a class which does not have a public constructor.
         *
         * @return The object instance.
         */
        Object newInstance();
    }

    /**
     * @description
     * Loads the class with the given name.
     *
     * @param typeName The name of the class to load.
     *
     * @return The Type for the class. Or an exception if the class doesn't exist.
     */
    public static Type load(final String typeName) {
        Assertion.isNotNull(typeName, 'argument: TypeHelper.loadType.typeName');

        Type type = Type.forName(typeName);
        if (type == null) {
            throw new APIException('Class ' + typeName + ' does not exist');
        } else {
            return type;
        }
    }

    /**
     * @description
     * Creates an object instance for the given type.
     * <br><br>
     * The type must have a no-op constructor.
     *
     * @param type The type for which a new object instance is to be created.
     *
     * @return The new instance of an object for the given type. Or an exception if an instance could not be
     * constructed.
     */
    global static Object newInstance(final Type type) {
        try {
            Object instance =  type.newInstance();
            if (instance instanceof Factory) {
                return ((Factory) instance).newInstance();
            } else {
                return instance;
            }
        } catch(Exception e) {
            throw new APIException('Class ' + type.getName() + ' could not be constructed', e);
        }
    }

    /**
     * @description
     * Exception thrown when a type related operation fails.
     */
    global with sharing class APIException extends Exception {}
}
