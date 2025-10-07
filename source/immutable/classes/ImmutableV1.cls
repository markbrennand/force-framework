/**
 * @description
 * <p>
 * Class providing the Collections API implementation.
 * <p>
 * Use these classes to create and manage immutable Lists, Sets and Maps.
 * <p>
 * List and Set functionality is combined and provided by the Collection interface.
 * <p>
 * See <a href=./../source/collection/README.md target="_blank">README</a> for full details of the Collection API.
 * <p>
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../LICENSE target="_blank">MIT License</a>.
 *
 * @author Mark Brennand
 */
@SuppressWarnings('PMD.AvoidGlobalModifier')
global with sharing class ImmutableV1 {

    /**
     * @description
     * Exception thrown when an operation in the Immutable API fails.
     */
    global with sharing class APIException extends ForceFwException {}

    /**
     * @description
     * <p>
     * Interface for List and Set that supports conversion to a List and the functionality of the ArrayV1.Methods
     * interface.
     * <p>
     * A ReadOnlyMap or ReadyOnlySet may have reduce(), filter(), transform() etc. called on it.
     */
    global interface Collection extends ArrayV1.Methods {

        /**
         * @description
         * <p>
         * Converts the contents of a collection to a List.
         * <p>
         * The collection's elements will be added to the List passed as argument. This method allows a List
         * of a specific type to be populated from a collection.
         *
         * @param result The List to be populated.
         *
         * @return The populated List.
         */
        List<Object> toList(final List<Object> result);

        /**
         * @description
         * <p>
         * Converts the contents of a collection to a List.
         * <p>
         * The returned List will be of type Object. This will prevent it being cast to a List of any other type, even
         * if the List contains that type.
         *
         * @return The collection's contents as a List.
         */
        List<Object> toList();

        /**
         * @description
         * <p>
         * Checks if the collection is empty.
         *
         * @return  True if the collection is empty, otherwise false.
         */
        Boolean isEmpty();

        /**
         * @description
         * <p>
         * Returns the number of elements in the collection.
         *
         * @return The number of elements in the collection.
         */
        Integer size();

        /**
         * @description
         * <p>
         * Determines whether collection contains the given object.
         *
         * @param element The object to be checked.
         *
         * @return True if the collection contains the object, false if not.
         */
        Boolean contains(final Object element);

        /**
         * @description
         * <p>
         * Determines whether the Set contains all the objects in the List argument.
         *
         * @param objs The objects to be matched.
         *
         * @return True if the Set contains all the objects, false if not.
         */
        Boolean containsAll(final List<Object> objs);

        /**
         * @description
         * <p>
         * Determines whether the Set contains all the objects in the Set argument.
         *
         * @param objs The objects to be matched.
         *
         * @return True if the Set contains all the objects, false if not.
         */
        Boolean containsAll(final Set<Object> objs);

        /**
         * @description
         * <p>
         * Retrieves the element at the given index in the List.
         *
         * @param index The positional index.
         *
         * @return The element.
         */
        Object get(final Integer index);

        /**
         * @description
         * <p>
         * Finds the positional index in the List of the given object.
         *
         * @param element The object to find.
         *
         * @return The positional index, or -1 if not found.
         */
        Integer indexOf(final Object element);
    }

    /**
     * @description
     * <p>
     * An immutable Map.
     * <p>
     * It has all the accessor functionality of a Map but has had the update capability removed.
     * <p>
     * It provides one item of functionality not present in a Map, iteration over the implementation, the Objects
     * returned by the Iterator will be the Map's keys.
     */
    global interface ReadOnlyMap extends Iterable<Object> {

        /**
         * @description
         * <p>
         * Retrieves the value associated with the specified key.
         *
         * @param key The key whose associated value is to be returned.
         *
         * @return The value associated with the key, or null if the key is not found.
         */
        Object get(final Object key);

        /**
         * @description
         * <p>
         * Checks if the map contains the specified key.
         *
         * @param key The key to check
         *
         * @return True if the map contains the key, false otherwise
         */
        Boolean containsKey(final Object key);

        /**
         * @description
         * <p>
         * Returns a List of the values stored in the Map.
         *
         * @return The values.
         */
        List<Object> values();

        /**
         * @description
         * <p>
         * Returns the keys to the Map's elements.
         *
         * @return The keys.
         */
        Set<Object> keySet();

        /**
         * @description
         * <p>
         * Returns the number of keys in the Map.
         *
         * @return The number of keys in the Map.
         */
        Integer size();
    }

    /**
     * @description
     * <p>
     * Creates an immutable Map from the given source Map.
     * <p>
     * The key to the Map is of an unknown type.
     *
     * @param source The source Map.
     *
     * @return The immutable Map.
     */
    global static ReadOnlyMap of(final Map<Object, Object> source) {
        return ImmutableImpl.newMap(source.clone());
    }

    /**
     * @description
     * <p>
     * Creates an immutable Map from the given source Map.
     * <p>
     * The key to the Map is an SObject Id.
     *
     * @param source The source Map.
     *
     * @return The immutable Map.
     */
    global static ReadOnlyMap of(final Map<Id, Object> source) {
        Map<Object, Object> cloned = new Map<Object, Object>();
        for (Id key : source.keySet()) {
            cloned.put(key, source.get(key));
        }
        return ImmutableImpl.newMap(cloned);
    }

    /**
     * @description
     * <p>
     * Creates an immutable Map from the given source Map.
     * <p>
     * The key to the Map is a String.
     *
     * @param source The source Map.
     *
     * @return The immutable Map.
     */
    global static ReadOnlyMap of(final Map<String, Object> source) {
        Map<Object, Object> cloned = new Map<Object, Object>();
        for (String key : source.keySet()) {
            cloned.put(key, source.get(key));
        }
        return ImmutableImpl.newMap(cloned);
    }

    /**
     * @description
     * <p>
     * Creates an immutable List from the given Iterable.
     *
     * @param source The Iterable.
     *
     * @return The immutable List.
     */
    global static Collection of(final Iterable<Object> source) {
        if (source instanceof List<Object>) {
            return ImmutableImpl.newCollection(((List<Object>) source).clone());
        } else {
            final List<Object> elements = new List<Object>();
            for (Object value : source) {
                elements.add(value);
            }
            return ImmutableImpl.newCollection(elements);
        }
    }
}