/**
 * @description
 * Class providing Apex Type related functionality.
 * <br><br>
 * Types may be loaded from their class name.
 * <br><br>
 * The Factory interface may be used by an implementing class to hide the construction of the Object instance in
 * the newInstance method. For example, say a class has a private constructor which cannot be changed to public. The
 * newInstance method would be unable to construct the class. If the class with a private constructor adds an inner
 * class that implements Factory, then the inner class could be public or global and its newInstance method could
 * create a new instance of the private constructor class and return it.
 *
 * Examples
 * <br>
 * <code>
 * public class Example {
 *      private Example() {}
 *
 *      public class ExampleFactory implements Types.Factory {
 *          public Object newInstance() {
 *              return new Example();
 *          }
 *      }
 * }
 *
 * // This call would return a new instance of the Example class.
 * Object obj = Types.newInstance(Type.forName('Example.ExampleFactory'));
 * </code>
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
            throw new TypeException('Class ' + typeName + ' does not exist');
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
            throw new TypeException('Class ' + type.getName() + ' could not be constructed' ,e);
        }
    }

    /**
     * @description
     * Exception thrown when a type related operation fails.
     */
    global with sharing class TypeException extends Exception {}
}