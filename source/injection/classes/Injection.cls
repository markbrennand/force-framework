/**
 * @deprecated
 * @description
 * This class has been deprecated and replaced by the Dependency class.
 *
 * @author Mark Brennand
 */
public with sharing virtual class Injection {

    /**
     * @deprecated
     * @description
     * Kept for backward compatibility.
     *
     * Please replace any calls with Dependency.inject.
     *
     * @param forType Deprecated.
     *
     * @return Deprecated.
     */
    public static Object wire(final Type forType) {
        return Dependency.inject(forType);
    }

    /**
     * @deprecated
     * @description
     * Kept for backward compatibility.
     *
     * Please replace any calls with Dependency.inject.
     *
     * @param forType Deprecated.
     * @param action Deprecated.
     *
     * @return Deprecated.
     */
    public static Object wire(final Type forType, final String action) {
        return Dependency.inject(forType, action);
    }

    /**
     * @deprecated
     * @description
     * Kept for backward compatibility.
     *
     * Please replace any calls with Dependency.isBound.
     *
     * @param forType Deprecated.
     *
     * @return Deprecated.
     */
    public static Boolean has(final Type forType) {
        return Dependency.isBound(forType);
    }

    /**
     * @deprecated
     * @description
     * Kept for backward compatibility.
     *
     * Please replace any calls with Dependency.isBound.
     *
     * @param forType Deprecated.
     * @param action Deprecated.
     *
     * @return Deprecated.
     */
    public static Boolean has(final Type forType, final String action) {
        return Dependency.isBound(forType, action);
    }

    /**
     * @deprecated
     * @description
     * Kept for backward compatibility.
     *
     * Please replace any calls with Dependency.bind.
     *
     * @param forType Deprecated.
     * @param withImpl Deprecated.
     */
    public static void add(final Type forType, final Type withImpl) {
        Dependency.bind(forType, withImpl);
    }

    /**
     * @deprecated
     * @description
     * Kept for backward compatibility.
     *
     * Please replace any calls with Dependency.bind.
     *
     * @param forType Deprecated.
     * @param action Deprecated.
     * @param withImpl Deprecated
     */
    public static void add(final Type forType, final String action, final Type withImpl) {
        Dependency.bind(forType, action, withImpl);
    }
}
