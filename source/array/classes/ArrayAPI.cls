/**
 * @description
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../LICENSE target="_blank">MIT License</a>.
 * <br><br>
 * Class providing the Array API implementation.
 * <br><br>
 * See <a href=../README.md target="_blank">README</a> for full details of the Array API.
 *
 * @author Mark Brennand
 */
public with sharing class ArrayAPI {

    /**
     * @description
     * Provides implementation of the methods that may be called to iterate over an array of objects.
     */
    private with sharing class Implementation implements ArrayV1.Methods {
        private Object shared;
        private final List<Object> objects;
        private Integer length;

        /**
         * @description
         * Constructs an instance of the class managing the given list.
         *
         * @param objects The objects comprising the array.
         */
        public Implementation(final List<Object> objects) {
            isListValid(objects);
            this.objects = objects.clone();
            this.length = objects.size();
        }

        /**
         * @description
         * Returns the number of elements of the array.
         *
         * @return The number of objects in the array.
         */
        public Integer length() {
            return length;
        }

        /**
         * @description
         * Sets the data to be shared in the callback.
         *
         * @param shared The object to be shared.
         *
         * @return The instance so it can be chained.
         */
        public ArrayV1.Methods sharing(final Object shared) {
            this.shared = shared;
            return this;
        }

        /**
         * @description
         * Iterates the elements of the array, invoking the callback for each.
         *
         * @param callback The callback to be invoked for each element.
         */
        public void forEach(final ArrayV1.Callback callback) {
            Assert.isNotNull(callback, 'Callback for method must be defined');
            callback.sharing(shared);
            for (Integer i = 0; i < length; i++) {
                callback.function(objects[i], OptionalV1.empty(), i);
            }
        }

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
        public Object reduce(final ArrayV1.Callback callback) {
            Assert.isNotNull(callback, 'Callback for method must be defined');
            return reduce(callback, getOptionalForElement(0), 1).get();
        }

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
        public Object reduceRight(final ArrayV1.Callback callback) {
            Assert.isNotNull(callback, 'Callback for method must be defined');
            return reduceRight(callback, getOptionalForElement(length -1), length - 1).get();
        }

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
        public Object reduce(final ArrayV1.Callback callback, final Object initialValue) {
            Assert.isNotNull(callback, 'Callback for method must be defined');
            return reduce(callback, OptionalV1.of(initialValue), 0).get();
        }

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
        public Object reduceRight(final ArrayV1.Callback callback, final Object initialValue) {
            Assert.isNotNull(callback, 'Callback for method must be defined');
            return reduceRight(callback, OptionalV1.of(initialValue), length).get();
        }

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
        public List<Object> filter(final ArrayV1.Callback callback) {
            Assert.isNotNull(callback, 'Callback for method must be defined');
            callback.sharing(shared);
            final List<Object> filtered = newListOfSameType(objects);
            for (Integer i = 0; i < length; i++) {
                if (isTrue(callback.function(objects[i], null, i))) {
                    filtered.add(objects[i]);
                }
            }
            return filtered;
        }

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
        public List<Object> transform(final ArrayV1.Callback callback) {
            Assert.isNotNull(callback, 'Callback for method must be defined');
            callback.sharing(shared);
            final List<Object> transformed = new List<Object>();
            for (Integer i = 0; i < length; i++) {
                transformed.add(callback.function(objects[i], OptionalV1.empty(), i).get());
            }
            return transformed;
        }

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
        public List<Object> transform(final ArrayV1.Callback callback, final List<Object> returnList) {
            Assert.isNotNull(callback, 'Callback for method must be defined');
            callback.sharing(shared);
            final List<Object> transformed = newListOfSameType(returnList);
            for (Integer i = 0; i < length; i++) {
                transformed.add(callback.function(objects[i], OptionalV1.empty(), i).get());
            }
            return transformed;
        }

        /**
         * @description
         * Appends the given array to the list of objects.
         *
         * @param elements The array to be added to the original.
         *
         * @return The new array.
         */
        public List<Object> concat(final List<Object> elements) {
            final List<Object> cloned = newListOfSameType(objects);
            cloned.addAll(objects);
            cloned.addAll(elements);
            return cloned;
        }

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
        public OptionalV1 at(final Integer index) {
            if ((index > 0 && index >= length) || (index < 0 && (length + index) < 0)) {
                return OptionalV1.empty();
            }
            return (index >= 0) ? OptionalV1.of(objects[index]) : OptionalV1.of(objects[length + index]);
        }

        /**
         * @description
         * Returns a string comprised of the array elements joined by the separator.
         *
         * @param separator Separator for array elements in output string.
         *
         * @return The joined array elements.
         */
        public String join(final String separator) {
            return String.join(objects, separator);
        }

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
        public Boolean some(final ArrayV1.Callback callback) {
            Assert.isNotNull(callback, 'Callback for method must be defined');
            callback.sharing(shared);
            for (Integer i = 0; i < length; i++) {
                if (isTrue(callback.function(objects[i], OptionalV1.empty(), i))) {
                    return true;
                }
            }
            return false;
        }

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
        public Boolean every(final ArrayV1.Callback callback) {
            Assert.isNotNull(callback, 'Callback for method must be defined');
            callback.sharing(shared);
            for (Integer i = 0; i < length; i++) {
                if (!isTrue(callback.function(objects[i], null, i))) {
                    return false;
                }
            }
            return true;
        }

        /**
         * @description
         * Returns a new array with the elements of the original array in reversed order.
         *
         * @return The new array with the reversed elements.
         */
        public List<Object> reverse() {
            final List<Object> cloned = newListOfSameType(objects);
            for (Integer i = length; i > 0; i--) {
                cloned.add(objects[i-1]);
            }
            return cloned;
        }

        /**
         * @description
         * Adds the given object to the end of the array.
         *
         * @param obj The object to add to the array.
         */
        public void push(final Object obj) {
            objects.add(obj);
            length++;
        }

        /**
         * @description
         * Removes the last element from the array and returns it.
         *
         * @return The last element of the array.
         */
        public OptionalV1 pop() {
            if (length == 0) {
                return OptionalV1.empty();
            }

            final Object lastElement = objects[--length];
            objects.remove(length);

            return OptionalV1.of(lastElement);
        }

        /**
         * @description
         * Removes the first element from the array and returns it.
         *
         * @return The first element of the array.
         */
        public OptionalV1 shift() {
            if (length == 0) {
                return OptionalV1.empty();
            }

            final Object firstElement = objects[0];
            objects.remove(0);
            --length;

            return OptionalV1.of(firstElement);
        }

        /**
         * @description
         * Sorts an array of Comparable objects.
         *
         * @return A new array containing the sorted objects.
         */
        public List<Object> sort() {
            final List<Object> cloned = objects.clone();
            cloned.sort();
            return cloned;
        }

        /**
         * @description
         * Sorts an array using the given Comparable
         *
         * @param comparator The Comparator to use to compare the objects.
         *
         * @return A new array containing the sorted objects.
         */
        public List<Object> sort(final Comparator<Object> comparator) {
            final List<Object> cloned = objects.clone();
            cloned.sort(comparator);
            return cloned;
        }

        private List<Object> newListOfSameType(final List<Object> listToClone) {
            final List<Object> cloned = listToClone.clone();
            cloned.clear();
            return cloned;
        }

        private OptionalV1 reduce(
                final ArrayV1.Callback callback,
                final OptionalV1 initialValue,
                final Integer startIndex
        ) {
            callback.sharing(shared);
            OptionalV1 value = initialValue;
            for (Integer i = startIndex; i < length; i++) {
                value = callback.function(objects[i], value, i);
            }
            return value;
        }

        private OptionalV1 reduceRight(
                final ArrayV1.Callback callback,
                final OptionalV1 initialValue,
                final Integer startIndex
        ) {
            callback.sharing(shared);
            OptionalV1 value = initialValue;
            for (Integer i = startIndex; i > 0; ) {
                i--;
                value = callback.function(objects[i], value, i);
            }
            return value;
        }

        private Boolean isTrue(final OptionalV1 value) {
            if (!value.isPresent() || !(value.get() instanceof Boolean)) {
                throw new ArrayV1.APIException('Callback must return a Boolean');
            } else {
                return (Boolean) value.get();
            }
        }

        private OptionalV1 getOptionalForElement(final Integer index) {
            if (objects.isEmpty()) {
                throw new ArrayV1.APIException('The reduce() method requires an array containing at least one element');
            }
            return OptionalV1.of(objects[index]);
        }

        private void isListValid(final List<Object> objects) {
            Assert.isNotNull(objects);
        }
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
    public static ArrayV1.Methods newInstance(final List<Object> objects) {
        return new Implementation(objects);
    }
}