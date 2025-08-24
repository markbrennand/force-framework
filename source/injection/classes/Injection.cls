/**
 * @deprecated
 * @description
 * <p/>
 * This class has been deprecated and replaced by the DependencyV1 class.
 * <p/>
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../LICENSE target="_blank">MIT License</a>.
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
        return DependencyV1.inject(forType);
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
        return DependencyV1.inject(forType, action);
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
        return DependencyV1.isBound(forType);
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
        return DependencyV1.isBound(forType, action);
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
        DependencyV1.bind(forType, withImpl);
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
        DependencyV1.bind(forType, action, withImpl);
    }
}
