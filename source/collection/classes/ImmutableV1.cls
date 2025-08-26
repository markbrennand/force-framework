/**
 * @description
 * <p/>
 * Class providing the Collections API implementation.
 * <p/>
 * Use these classes to create and manage immutable Lists, Sets and Maps.
 * <p/>
 * The ReadOnlyList and ReadOnlySet implement the Collection interface. The interface gives access to all the
 * functionality of the ArrayV1.Methods interface.
 * <p/>
 * See <a href=./../source/collection/README.md target="_blank">README</a> for full details of the Collection API.
 * <p/>
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../LICENSE target="_blank">MIT License</a>.
 *
 * @author Mark Brennand
 */
@SuppressWarnings('PMD.AvoidGlobalModifier')
global with sharing class ImmutableV1 {

    /**
     * @description
     * <p/>
     * Interface for List and Set that supports conversion to a List and the functionality of the ArrayV1.Methods
     * interface.
     * <p/>
     * A ReadOnlyMap or ReadyOnlySet may have reduce(), filter(), transform() etc. called on it.
     */
    global interface Collection extends ArrayV1.Methods {

        /**
         * @description
         * <p/>
         * Converts the contents of a collection to a List.
         * <p/>
         * The collection's elements will be added to the List passed as argument. This method allows a List
         * of a specific type to be populated from a collection.
         *
         * @param result The List to be populated.
         *
         * @return The populated list.
         */
        List<Object> toList(final List<Object> result);

        /**
         * @description
         * <p/>
         * Converts the contents of a collection to a List.
         * <p/>
         * The returned List will be of type Object. This will prevent it being cast to a List of any other type, even
         * if the List contains that type.
         *
         * @return The collection's contents as a list.
         */
        List<Object> toList();

        /**
         * @description
         * <p/>
         * Checks if the collection is empty.
         *
         * @return  True if the collection is empty, otherwise false.
         */
        Boolean isEmpty();

        /**
         * @description
         * <p/>
         * Returns the number of elements in the collection.
         *
         * @return The number of elements in the collection.
         */
        Integer size();

        /**
         * @description
         * <p/>
         * Determines whether collection contains the given object.
         *
         * @param element The object to be checked.
         *
         * @return True if the collection contains the object, false if not.
         */
        Boolean contains(final Object element);
    }

    /**
     * @description
     * <p/>
     * An immutable Map.
     * <p/>
     * It has all the accessor functionality of a Map but has had the update capability removed.
     * <p/>
     * It provides one item of functionality not present in a Map, iteration over the implementation, the Objects
     * returned by the Iterator will be the Map's keys.
     */
    global interface ReadOnlyMap extends Iterable<Object> {

        /**
         * @description
         * <p/>
         * Retrieves the value associated with the specified key.
         *
         * @param key The key whose associated value is to be returned.
         *
         * @return The value associated with the key, or null if the key is not found.
         */
        Object get(final Object key);

        /**
         * @description
         * <p/>
         * Checks if the map contains the specified key.
         *
         * @param key The key to check
         *
         * @return True if the map contains the key, false otherwise
         */
        Boolean containsKey(final Object key);

        /**
         * @description
         * <p/>
         * Returns a List of the values stored in the Map.
         *
         * @return The values.
         */
        List<Object> values();

        /**
         * @description
         * <p/>
         * Returns the keys to the Map's elements.
         *
         * @return The keys.
         */
        Set<Object> keySet();

        /**
         * @description
         * <p/>
         * Returns the number of keys in the Map.
         *
         * @return The number of keys in the Map.
         */
        Integer size();
    }

    /**
     * @description
     * <p/>
     * An immutable List.
     * <p/>
     * It has all the accessor functionality of a List but has had the update capability removed.
     * <p/>
     * The Collection methods may be used to use the functionality from ArrayV1.
     */
    global interface ReadOnlyList extends ImmutableV1.Collection {

        /**
         * @description
         * <p/>
         * Retrieves the element at the given index in the List.
         *
         * @param index The positional index.
         *
         * @return The element.
         */
        Object get(final Integer index);

        /**
         * @description
         * <p/>
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
    * <p/>
    * An immutable Set
    * <p/>
    * It has all the accessor functionality of a Set but has had the update capability removed.
    * <p/>
    * The Collection methods may be used to use the functionality from ArrayV1.
    */
    global interface ReadOnlySet extends ImmutableV1.Collection {

        /**
         * @description
         * <p/>
         * Determines whether the Set contains all the objects in the List argument.
         *
         * @param objs The objects to be matched.
         *
         * @return True if the Set contains all the objects, false if not.
         */
        Boolean containsAll(final List<Object> objs);

        /**
         * @description
         * <p/>
         * Determines whether the Set contains all the objects in the Set argument.
         *
         * @param objs The objects to be matched.
         *
         * @return True if the Set contains all the objects, false if not.
         */
        Boolean containsAll(final Set<Object> objs);
    }

    private with sharing class ImmutableMap implements ImmutableV1.ReadOnlyMap {
        private final Map<Object, Object> wrapped;

        public ImmutableMap(final Map<Object, Object> source) {
            this.wrapped = source;
        }

        public Object get(final Object key) {
            return wrapped.get(key);
        }

        public Boolean containsKey(final Object key) {
            return wrapped.containsKey(key);
        }

        public List<Object> values() {
            return wrapped.values();
        }

        public Set<Object> keySet() {
            return wrapped.keySet();
        }

        public Boolean isEmpty() {
            return wrapped.isEmpty();
        }

        public Integer size() {
            return wrapped.size();
        }

        public Iterator<Object> iterator() {
            return keySet().iterator();
        }
    }

    private with sharing abstract class CollectionImpl implements ImmutableV1.Collection {
        private final ArrayV1.Methods methods {
            private get {
                if (methods == null) {
                    methods = ArrayV1.over(getCollection());
                }
                return methods;
            }
            private set;
        }

        public abstract Iterable<Object> getCollection();

        public Integer length() {
            return methods.length();
        }

        public ArrayV1.Methods sharing(final Object shared) {
            return methods.sharing(shared);
        }

        public void forEach(final ArrayV1.Callback callback) {
            methods.forEach(callback);
        }

        public Object reduce(final ArrayV1.Callback callback) {
            return methods.reduce(callback);
        }

        public Object reduceRight(final ArrayV1.Callback callback) {
            return methods.reduceRight(callback);
        }

        public Object reduce(final ArrayV1.Callback callback, final Object initialValue) {
            return methods.reduce(callback, initialValue);
        }

        public Object reduceRight(final ArrayV1.Callback callback, final Object initialValue) {
            return methods.reduceRight(callback, initialValue);
        }

        public List<Object> filter(final ArrayV1.Callback callback) {
            return methods.filter(callback);
        }

        public List<Object> transform(final ArrayV1.Callback callback) {
            return methods.transform(callback);
        }

        public List<Object> transform(final ArrayV1.Callback callback, final List<Object> returnList) {
            return methods.transform(callback, returnList);
        }

        public List<Object> concat(final List<Object> elements) {
            return methods.concat(elements);
        }

        public OptionalV1 at(final Integer index) {
            return methods.at(index);
        }

        public String join(final String separator) {
            return methods.join(separator);
        }

        public Boolean some(final ArrayV1.Callback callback) {
            return methods.some(callback);
        }

        public Boolean every(final ArrayV1.Callback callback) {
            return methods.every(callback);
        }

        public List<Object> reverse() {
            return methods.reverse();
        }

        public void push(final Object obj) {
            methods.push(obj);
        }

        public OptionalV1 pop() {
            return methods.pop();
        }

        public OptionalV1 shift() {
            return methods.shift();
        }

        public List<Object> sort() {
            return methods.sort();
        }

        public List<Object> sort(final Comparator<Object> comparator) {
            return methods.sort(comparator);
        }

        public List<Object> toList(final List<Object> result) {
            for (Object obj : getCollection()) {
                result.add(obj);
            }

            return result;
        }

        public List<Object> toList() {
            return toList(new List<Object>());
        }
    }

    private with sharing class ImmutableList extends ImmutableV1.CollectionImpl implements ImmutableV1.ReadOnlyList {
        private final List<Object> wrapped;

        public ImmutableList(final List<Object> source) {
            this.wrapped = source;
        }

        public override Iterable<Object> getCollection() {
            return wrapped;
        }

        public Integer size() {
            return wrapped.size();
        }

        public Boolean isEmpty() {
            return wrapped.isEmpty();
        }

        public Object get(final Integer index) {
            return wrapped.get(index);
        }

        public Integer indexOf(final Object element) {
            return wrapped.indexOf(element);
        }

        public Boolean contains(final Object element) {
            return wrapped.contains(element);
        }

        public Iterator<Object> iterator() {
            return wrapped.iterator();
        }
    }

    private with sharing class ImmutableSet extends ImmutableV1.CollectionImpl implements ReadOnlySet {
        private final Set<Object> wrapped;

        public ImmutableSet(final Set<Object> source) {
            this.wrapped = source;
        }

        public override Iterable<Object> getCollection() {
            return wrapped;
        }

        public Integer size() {
            return wrapped.size();
        }

        public Boolean isEmpty() {
            return wrapped.isEmpty();
        }

        public Boolean contains(final Object element) {
            return wrapped.contains(element);
        }

        public Boolean containsAll(final List<Object> objs) {
            return wrapped.containsAll(objs);
        }

        public Boolean containsAll(final Set<Object> objs) {
            return wrapped.containsAll(objs);
        }

        public Iterator<Object> iterator() {
            return wrapped.iterator();
        }
    }

    public static ReadOnlyMap of(final Map<Object, Object> source) {
        return new ImmutableMap(source.clone());
    }

    public static ReadOnlyMap of(final Map<String, Object> source) {
        Map<Object, Object> cloned = new Map<Object, Object>();
        for (String key : source.keySet()) {
            cloned.put(key, source.get(key));
        }
        return new ImmutableMap(cloned);
    }

    public static ReadOnlyList of(final Iterable<Object> source) {
        if (source instanceof List<Object>) {
            return new ImmutableList(((List<Object>) source).clone());
        } else {
            final List<Object> elements = new List<Object>();
            for (Object value : source) {
                elements.add(value);
            }
            return new ImmutableList(elements);
        }
    }

    public static ReadOnlySet of(final Set<Object> source) {
        return new ImmutableSet(source.clone());
    }
}