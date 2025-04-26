/**
 * @description
 * Helper methods for Type related operations.
 *
 * @author Mark Brennand
 */
global with sharing class TypeHelper {

    /**
     * @description
     * Supports use of a factory when instantiating a class.
     *
     * If an instantiated class implements this interface then the newInstance method will create the actual instance.
     */
    global interface Factory {

        /**
         * @description
         * Builds a new instance of the class the factory is acting for.
         *
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
    public static Type loadType(final String typeName) {
        Assert.isNotNull(typeName, 'TypeHelper.loadType.typeName');

        Type type = Type.forName(typeName);
        if (type == null) {
            throw new TypeException('Type "' + typeName + '" does not exist');
        } else {
            return type;
        }
    }

    /**
     * @description
     * Creates an object instance for the given type.
     *
     * The type must have a no-op constructor.
     *
     * @param type The type for which a new object instance is to be created.
     *
     * @return The new instance of an object for the given type. Or an exception if an instance could not be
     * constructed.
     */
    public static Object newInstance(final Type type) {
        try {
            Object instance =  type.newInstance();
            if (instance instanceof Factory) {
                return ((Factory) instance).newInstance();
            } else {
                return instance;
            }
        } catch(Exception e) {
            throw new TypeException('Type "' + type.getName() + '" could not be constructed' ,e);
        }
    }

    public with sharing class TypeException extends Exception {}
}