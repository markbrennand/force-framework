/**
 * @description
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../../LICENSE target="_blank">MIT License</a>.
 * <br><br>
 * Class providing the Array API.
 * <br><br>
 * See <a href=../README.md target="_blank">README</a> for full details of the Array API.
 *
 * @author Mark Brennand
 */
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
        private Optional shared = Optional.empty();

        /**
         * @description
         * Records the data to be shared in the callback.
         *
         * @param shared The data to be shared.
         */
        private void sharing(final Object shared) {
            this.shared = Optional.ofNullable(shared);
        }

        /**
         * @description
         * Returns the shared data for the callback.
         *
         * @return The shared data.
         */
        global Optional shared() {
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
        global abstract Optional function(final Object element, final Optional currentValue, final Integer index);
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
         *
         * @param callback The callback class to be invoked for each array element.
         *
         * @return The list of transformed objects.
         */
        List<Object> transform(final Callback callback);

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
        Optional at(final Integer index);

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
        Optional pop();

        /**
         * @description
         * Removes the first element from the array and returns it.
         *
         * @return The first element of the array.
         */
        Optional shift();
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
        return new MethodsImpl(objects);
    }

    private static void isListValid(final List<Object> objects) {
        Assert.isNotNull(objects);
    }

    private with sharing class MethodsImpl implements Methods {
        private Object shared;
        private final List<Object> objects;
        private Integer length;

        public MethodsImpl(final List<Object> objects) {
            isListValid(objects);
            this.objects = objects;
            this.length = objects.size();
        }

        public Integer length() {
            return length;
        }

        public Methods sharing(final Object shared) {
            this.shared = shared;
            return this;
        }

        public void forEach(final Callback callback) {
            callback.sharing(shared);
            for (Integer i = 0; i < length; i++) {
                callback.function(objects[i], Optional.empty(), i);
            }
        }

        public Object reduce(final Callback callback) {
            return reduce(callback, getOptionalForElement(0), 0, length - 1, 1).get();
        }

        public Object reduceRight(final Callback callback) {
            return reduce(callback, getOptionalForElement(length -1), length - 1, 0, -1).get();
        }

        public Object reduce(final Callback callback, final Object initialValue) {
            return reduce(callback, Optional.of(initialValue), -1, length -1, 1).get();
        }

        public Object reduceRight(final Callback callback, final Object initialValue) {
            return reduce(callback, Optional.of(initialValue), length, 0, -1).get();
        }

        public List<Object> filter(final Callback callback) {
            callback.sharing(shared);
            final List<Object> filtered = newListOfSameType();
            for (Integer i = 0; i < length; i++) {
                final Optional retVal = callback.function(objects[i], null, i);
                if (!retval.isPresent() || !(retval.get() instanceof Boolean)) {
                    throw new APIException('Callback for filter() must return a Boolean');
                }

                if (retval.get() == true) {
                    filtered.add(objects[i]);
                }
            }
            return filtered;
        }

        public List<Object> transform(final Callback callback) {
            callback.sharing(shared);
            final List<Object> mapped = newListOfSameType();
            for (Integer i = 0; i < length; i++) {
                mapped.add(callback.function(objects[i], Optional.empty(), i).get());
            }
            return mapped;
        }

        public List<Object> concat(final List<Object> elements) {
            final List<Object> cloned = newListOfSameType();
            cloned.addAll(objects);
            cloned.addAll(elements);
            return cloned;
        }

        public Optional at(final Integer index) {
            if ((index > 0 && index >= length) ||
                    (index < 0 && (length + index) < 0))
            {
                return Optional.empty();
            }
            return (index >= 0) ? Optional.of(objects[index]) : Optional.of(objects[length + index]);
        }

        public String join(final String separator) {
            return String.join(objects, separator);
        }

        public Boolean some(final Callback callback) {
            callback.sharing(shared);
            for (Integer i = 0; i < length; i++) {
                final Optional retVal = callback.function(objects[i], Optional.empty(), i);
                if (!retval.isPresent() || ! (retval.get() instanceof Boolean)) {
                    throw new APIException('Callback for some() must return a Boolean');
                }

                if (retval.get() == true) {
                    return true;
                }
            }
            return false;
        }

        public Boolean every(final Callback callback) {
            callback.sharing(shared);
            for (Integer i = 0; i < length; i++) {
                final Optional retVal = callback.function(objects[i], null, i);
                if (!retval.isPresent() || !(retval.get() instanceof Boolean)) {
                    throw new APIException('Callback for every() must return a Boolean');
                }

                if (retval.get() != true) {
                    return false;
                }
            }
            return true;
        }

        public List<Object> reverse() {
            final List<Object> cloned = newListOfSameType();
            for (Integer i = length; i > 0; i--) {
                cloned.add(objects[i-1]);
            }
            return cloned;
        }

        public void push(final Object obj) {
            objects.add(obj);
            length++;
        }

        public Optional pop() {
            if (objects.size() == 0) {
                return Optional.empty();
            }

            final Object lastElement = objects[--length];
            objects.remove(length);

            return Optional.of(lastElement);
        }

        public Optional shift() {
            if (objects.size() == 0) {
                return Optional.empty();
            }

            final Object firstElement = objects[0];
            objects.remove(0);
            --length;

            return Optional.of(firstElement);
        }


        private List<Object> newListOfSameType() {
            final List<Object> cloned = objects.clone();
            cloned.clear();
            return cloned;
        }

        private Optional reduce(
                final Callback callback,
                final Optional initialValue,
                final Integer startIndex,
                final Integer lastIndex,
                final Integer increment
        ) {
            callback.sharing(shared);
            Optional value = initialValue;
            for (Integer i = startIndex; i != lastIndex;) {
                i += increment;
                value = callback.function(objects[i], value, i);
            }
            return value;
        }

        private Optional getOptionalForElement(final Integer index) {
            if (length == 0) {
                throw new ArrayV1.APIException('The reduce() method requires an array containing at least one element');
            }
            return Optional.of(objects[index]);
        }
    }
}