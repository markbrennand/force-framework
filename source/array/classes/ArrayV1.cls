/**
 * @description
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../../LICENSE target="_blank">MIT License</a>.
 * <br><br>
 * Class providing the Array API.
 * <br><br>
 * See <a href=../../source/array/README.md target="_blank">README</a> for full details of the Array API.
 *
 * @author Mark Brennand
 */
@SuppressWarnings('PMD.AvoidGlobalModifier')
global with sharing class ArrayV1 {

    /**
     * @description
     * Exception thrown when an operation in the Array API fails.
     */
    global with sharing class APIException extends Exception {}

    /**
     * @description
     * Class representing a callback to process each iterated array element.
     * <br><br>
     * The function() method must be overridden to code the logic to be performed on the array element.
     * <br><br>
     * Data shared on initiation of the iterator is accessed using the shared() method.
     */
    global with sharing abstract class Callback {

        /**
         * @description
         * Data shared on Iterator initiation.
         */
        private OptionalV1 shared = OptionalV1.empty();

        /**
         * @description
         * Records the data to be shared in the callback.
         *
         * @param shared The data to be shared.
         */
        global void sharing(final Object shared) {
            this.shared = OptionalV1.ofNullable(shared);
        }

        /**
         * @description
         * Returns the shared data for the callback.
         *
         * @return The shared data.
         */
        global OptionalV1 shared() {
            return shared;
        }

        /**
         * @description
         * This class must be extended to code the logic to be performed on each array element.
         * <br><br>
         * The method will be called for each element. The currentValue will be null, except when the callback
         * is being called from the reduce() method. In this case, its value will be the accumulated result of
         * all the previous callbacks.
         * <br><br>
         * See the iterator methods for details of the return values expected from the callback.
         *
         * @param element The current array element.
         * @param currentValue The value accumulated over the array iteration.
         * @param index The positional index of the array element.
         *
         * @return A value representing the result of the processing.
         */
        global abstract OptionalV1 function(final Object element, final OptionalV1 currentValue, final Integer index);
    }

    /**
     * @description
     * Iterator methods.
     * <br><br>
     * The over() method must be called first to use these methods.
     */
    global interface Methods {

        /**
         * @description
         * Returns the number of elements in the array.
         *
         * @return The number of elements in the array.
         */
        Integer length();

        /**
         * @description
         * Sets the data to be shared between callbacks.
         *
         * @param shared The data to be shared between callbacks.
         *
         * @return The Methods implementation, allowing the call to be chained with over().
         */
        Methods sharing(final Object shared);

        /**
         * @description
         * Calls the callback for each element in the array being iterated over.
         * <br><br>
         * The currentValue argument to the callback function will be null.
         * <br><br>
         * The return value from the callback function is ignored.
         *
         * @param callback The callback class to be invoked for each array element.
         */
        void forEach(final Callback callback);

        /**
         * @description
         * Calls the callback for each element in the array being iterated over.
         * <br><br>
         * In the first call to the callback, the currentValue will be the first element of the array and the
         * element argument will be the second element of the array. In subsequent calls, the currentValue will be
         * the value returned by the last callback.
         *
         * @param callback The callback class to be invoked for each array element.
         *
         * @return The return value from the last element of the array iterated over.
         */
        Object reduce(final Callback callback);

        /**
         * @description
         * Calls the callback for each element in the array iterated over in reverse order.
         * <br><br>
         * In the first call to the callback, the currentValue will be the last element of the array and the
         * element argument will be the second to last element of the array. In subsequent calls, the currentValue will be
         * the value returned by the last callback.
         *
         * @param callback The callback class to be invoked for each array element.
         *
         * @return The return value from the last element of the array iterated over.
         */
        Object reduceRight(final Callback callback);

        /**
         * @description
         * Builds an object based on the processing of each element of the array.
         * <br><br>
         * The currentValue argument of the callback function will be the value of the initialValue argument for
         * the iteration. In subsequent calls, the currentValue will be the last value returned by the callback's
          * function() method.
         *
         * @param callback The callback class to be invoked for each array element.
         * @param initialValue The starting value for the iteration.
         *
         * @return The return value from the last element of the array iterated over.
         */
        Object reduce(final Callback callback, final Object initialValue);

        /**
         * @description
         * Builds an object based on the processing of each element of the array iterated over in reverse order.
         * <br><br>
         * The currentValue argument of the callback function will be the value of the initialValue argument for
         * the iteration. In subsequent calls, the currentValue will be the last value returned by the callback's
          * function() method.
         *
         * @param callback The callback class to be invoked for each array element.
         * @param initialValue The starting value for the iteration.
         *
         * @return The return value from the last element of the array iterated over.
         */
        Object reduceRight(final Callback callback, final Object initialValue);

        /**
         * @description
         * Builds a list of results matching the filter condition.
         * <br><br>
         * The callback function must return true if the array element is to be added to the return list or false if not.
         *
         * @param callback The callback class to be invoked for each array element.
         *
         * @return List of filtered results.
         */
        List<Object> filter(final Callback callback);

        /**
         * @description
         * Builds a list of objects with a transformation applied.
         * <br><br>
         * This is the equivalent of the Javascript map() function.
         * <br><br>
         * The callback function must apply the transformation and return the transformed object.
         * <br><br>
         * The list returned will be of type ANY and as a result may not be cast to the type the list contains.
         *
         * @param callback The callback class to be invoked for each array element.
         *
         * @return The list of transformed objects.
         */
        List<Object> transform(final Callback callback);

        /**
         * @description
         * Builds a list of objects with a transformation applied.
         * <br><br>
         * This is the equivalent of the Javascript map() function.
         * <br><br>
         * The callback function must apply the transformation and return the transformed object.
         * <br><br>
         * The return list must be of the type of the transformed elements. This allows the returned list to
         * be cast to the type of the element.
         *
         * @param callback The callback class to be invoked for each array element.
         * @param returnList The list of the type the transformed elements.
         *
         * @return The list of transformed objects.
         */
        List<Object> transform(final Callback callback, final List<Object> returnList);

        /**
         * @description
         * Appends the given array to the list of objects.
         *
         * @param elements The array to be added to the original.
         *
         * @return The new array.
         */
        List<Object> concat(final List<Object> elements);

        /**
         * @description
         * Returns the element at the given index.
         * <br><br>
         * If index is negative, the element relative to the end of the array is returned. Use -1 for the last element.
         *
         * @param index The positional index of the element to return.
         *
         * @return The new array.
         */
        OptionalV1 at(final Integer index);

        /**
         * @description
         * Returns a string comprised of the array elements joined by the separator.
         *
         * @param separator Separator for array elements in output string.
         *
         * @return The joined array elements.
         */
        String join(final String separator);

        /**
         * @description
         * Returns true if the array contains a value that is matched by the callback function.
         * <br><br>
         * The callback function must return true if the array element is a match.
         *
         * @param callback The callback class to be invoked for each array element.
         *
         * @return True if a matching value is found.
         */
        Boolean some(final Callback callback);

        /**
         * @description
         * Returns true if all the elements of the array have a value that is matched by the callback function.
         * <br><br>
         * The callback function must return true if the array element is a match.
         *
         * @param callback The callback class to be invoked for each array element.
         *
         * @return True if all the elements match.
         */
        Boolean every(final Callback callback);

        /**
         * @description
         * Returns a new array with the elements of the original array in reversed order.
         *
         * @return The new array with the reversed elements.
         */
        List<Object> reverse();

        /**
         * @description
         * Adds the given object to the end of the array.
         *
         * @param obj The object to add to the array.
         */
        void push(final Object obj);

        /**
         * @description
         * Removes the last element from the array and returns it.
         *
         * @return The last element of the array.
         */
        OptionalV1 pop();

        /**
         * @description
         * Removes the first element from the array and returns it.
         *
         * @return The first element of the array.
         */
        OptionalV1 shift();

        /**
         * @description
         * Sorts an array of Comparable objects.
         *
         * @return A new array containing the sorted objects.
         */
        List<Object> sort();

        /**
         * @description
         * Sorts an array using the given Comparable
         *
         * @param comparator The Comparator to use to compare the objects.
         *
         * @return A new array containing the sorted objects.
         */
        List<Object> sort(final Comparator<Object> comparator);
    }

    /**
     * @description
     * Creates the iterator for an array of objects.
     * <br><br>
     * The method to iterate the array with may then be called.
     * <br><br>
     * If data is to be shared between callbacks, call the shared() method before the iterator method.
     *
     * @param objects The array of objects to be iterated.
     *
     * @return The methods that may be called on the array.
     */
    global static Methods over(final List<Object> objects) {
        return ArrayAPI.newInstance(objects);
    }

    /**
     * @description
     * Creates the iterator from an Object.
     * <br><br>
     * If the Object is Iterable a List is built from it, otherwise a List is used with a single element, the object.
     * <br><br>
     * The method to iterate the array with may then be called.
     * <br><br>
     * If data is to be shared between callbacks, call the shared() method before the iterator method.
     *
     * @param source The source object.
     *
     * @return The methods that may be called on the array.
     */
    global static Methods over(final Object source) {
        final List<Object> toIterate;
        if (source instanceof List<Object>) {
            toIterate = (List<Object>) source;
        } else if (source instanceof Iterable<Object>) {
            toIterate = new List<Object>();
            for (Object next : (Iterable<Object>) source) {
                toIterate.add(next);
            }
        } else {
            toIterate = new List<Object> { source };
        }

        return over(toIterate);
    }
}