/**
 * @description
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../../LICENSE target="_blank">MIT License</a>.
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

        public Implementation(final List<Object> objects) {
            isListValid(objects);
            this.objects = objects.clone();
            this.length = objects.size();
        }

        public Integer length() {
            return length;
        }

        public ArrayV1.Methods sharing(final Object shared) {
            this.shared = shared;
            return this;
        }

        public void forEach(final ArrayV1.Callback callback) {
            callback.sharing(shared);
            for (Integer i = 0; i < length; i++) {
                callback.function(objects[i], OptionalV1.empty(), i);
            }
        }

        public Object reduce(final ArrayV1.Callback callback) {
            return reduce(callback, getOptionalForElement(0), 0, length - 1, 1).get();
        }

        public Object reduceRight(final ArrayV1.Callback callback) {
            return reduce(callback, getOptionalForElement(length -1), length - 1, 0, -1).get();
        }

        public Object reduce(final ArrayV1.Callback callback, final Object initialValue) {
            return reduce(callback, OptionalV1.of(initialValue), -1, length -1, 1).get();
        }

        public Object reduceRight(final ArrayV1.Callback callback, final Object initialValue) {
            return reduce(callback, OptionalV1.of(initialValue), length, 0, -1).get();
        }

        public List<Object> filter(final ArrayV1.Callback callback) {
            callback.sharing(shared);
            final List<Object> filtered = newListOfSameType(objects);
            for (Integer i = 0; i < length; i++) {
                final OptionalV1 retVal = callback.function(objects[i], null, i);
                if (!retval.isPresent() || !(retval.get() instanceof Boolean)) {
                    throw new ArrayV1.APIException('Callback for filter() must return a Boolean');
                }

                if (retval.get() == true) {
                    filtered.add(objects[i]);
                }
            }
            return filtered;
        }

        public List<Object> transform(final ArrayV1.Callback callback) {
            callback.sharing(shared);
            final List<Object> mapped = new List<Object>();
            for (Integer i = 0; i < length; i++) {
                mapped.add(callback.function(objects[i], OptionalV1.empty(), i).get());
            }
            return mapped;
        }

        public List<Object> transform(final ArrayV1.Callback callback, final List<Object> returnList) {
            callback.sharing(shared);
            final List<Object> mapped = newListOfSameType(returnList);
            for (Integer i = 0; i < length; i++) {
                mapped.add(callback.function(objects[i], OptionalV1.empty(), i).get());
            }
            return mapped;
        }

        public List<Object> concat(final List<Object> elements) {
            final List<Object> cloned = newListOfSameType(objects);
            cloned.addAll(objects);
            cloned.addAll(elements);
            return cloned;
        }

        public OptionalV1 at(final Integer index) {
            if ((index > 0 && index >= length) ||
                    (index < 0 && (length + index) < 0))
            {
                return OptionalV1.empty();
            }
            return (index >= 0) ? OptionalV1.of(objects[index]) : OptionalV1.of(objects[length + index]);
        }

        public String join(final String separator) {
            return String.join(objects, separator);
        }

        public Boolean some(final ArrayV1.Callback callback) {
            callback.sharing(shared);
            for (Integer i = 0; i < length; i++) {
                final OptionalV1 retVal = callback.function(objects[i], OptionalV1.empty(), i);
                if (!retval.isPresent() || ! (retval.get() instanceof Boolean)) {
                    throw new ArrayV1.APIException('Callback for some() must return a Boolean');
                }

                if (retval.get() == true) {
                    return true;
                }
            }
            return false;
        }

        public Boolean every(final ArrayV1.Callback callback) {
            callback.sharing(shared);
            for (Integer i = 0; i < length; i++) {
                final OptionalV1 retVal = callback.function(objects[i], null, i);
                if (!retval.isPresent() || !(retval.get() instanceof Boolean)) {
                    throw new ArrayV1.APIException('Callback for every() must return a Boolean');
                }

                if (retval.get() != true) {
                    return false;
                }
            }
            return true;
        }

        public List<Object> reverse() {
            final List<Object> cloned = newListOfSameType(objects);
            for (Integer i = length; i > 0; i--) {
                cloned.add(objects[i-1]);
            }
            return cloned;
        }

        public void push(final Object obj) {
            objects.add(obj);
            length++;
        }

        public OptionalV1 pop() {
            if (objects.size() == 0) {
                return OptionalV1.empty();
            }

            final Object lastElement = objects[--length];
            objects.remove(length);

            return OptionalV1.of(lastElement);
        }

        public OptionalV1 shift() {
            if (objects.size() == 0) {
                return OptionalV1.empty();
            }

            final Object firstElement = objects[0];
            objects.remove(0);
            --length;

            return OptionalV1.of(firstElement);
        }

        public List<Object> sort() {
            final List<Object> cloned = objects.clone();
            cloned.sort();
            return cloned;
        }

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
                final Integer startIndex,
                final Integer lastIndex,
                final Integer increment
        ) {
            callback.sharing(shared);
            OptionalV1 value = initialValue;
            for (Integer i = startIndex; i != lastIndex;) {
                i += increment;
                value = callback.function(objects[i], value, i);
            }
            return value;
        }

        private OptionalV1 getOptionalForElement(final Integer index) {
            if (length == 0) {
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