/**
 * @description
 * @author Mark Brennand
 */
public with sharing class ExtendedDependency extends Dependency {

    public static AsynchronousDAO inject() {
        return (AsynchronousDAO) inject(AsynchronousDAO.class);
    }
}