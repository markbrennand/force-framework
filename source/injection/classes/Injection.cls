/**
 * MIT License
 *
 * Copyright (c) 2025 Mark Brennand
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */
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
