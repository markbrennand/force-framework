/**
 * @description
 * <p>
 * Implementations of Immutable APIs.
 * <p>
 * Implementation classes are private to prevent re-use.
 * <p>
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../LICENSE target="_blank">MIT License</a>.
 * 
 * @author Mark Brennand
 */
public with sharing class ImmutableImpl {

    /**
     * @description
     * <p>
     * Implementation of the Collection API.
     * <p>
     * Class is hidden to prevent re-use.
     */
    private with sharing class CollectionImpl implements ImmutableV1.Collection {

        private final List<Object> wrapped;

        private final ArrayV1.Methods methods {
            private get {
                if (methods == null) {
                    methods = ArrayV1.over(wrapped);
                }
                return methods;
            }
            private set;
        }

        /**
         * @description
         * <p>
         * Constructs an instance of the class providing an immutable Collection for the given List.
         *
         * @param source The List to be made immutable.
         */
        public CollectionImpl(final List<Object> source) {
            this.wrapped = source;
        }

        @SuppressWarnings('PMD.ApexDoc')
        public Integer size() {
            return wrapped.size();
        }

        @SuppressWarnings('PMD.ApexDoc')
        public Boolean isEmpty() {
            return wrapped.isEmpty();
        }

        @SuppressWarnings('PMD.ApexDoc')
        public Object get(final Integer index) {
            return wrapped.get(index);
        }

        @SuppressWarnings('PMD.ApexDoc')
        public Integer indexOf(final Object element) {
            return wrapped.indexOf(element);
        }

        @SuppressWarnings('PMD.ApexDoc')
        public Boolean contains(final Object element) {
            return wrapped.contains(element);
        }

        @SuppressWarnings('PMD.ApexDoc')
        public Boolean containsAll(final Iterable<Object> objs) {
            for (Object obj : objs) {
                if (!contains(obj)) {
                    return false;
                }
            }

            return true;
        }

        @SuppressWarnings('PMD.ApexDoc')
        public Iterator<Object> iterator() {
            return wrapped.iterator();
        }

        @SuppressWarnings('PMD.ApexDoc')
        public List<Object> toList() {
            return toList(CommonHelper.newListOfSameType(wrapped));
        }

        @SuppressWarnings('PMD.ApexDoc')
        public List<Object> toList(final List<Object> result) {
            for (Object obj : wrapped) {
                result.add(obj);
            }

            return result;
        }

        @SuppressWarnings('PMD.ApexDoc')
        public Integer length() {
            return methods.length();
        }

        @SuppressWarnings('PMD.ApexDoc')
        public ArrayV1.Methods sharing(final Object shared) {
            return methods.sharing(shared);
        }

        @SuppressWarnings('PMD.ApexDoc')
        public void forEach(final ArrayV1.Callback callback) {
            methods.forEach(callback);
        }

        @SuppressWarnings('PMD.ApexDoc')
        public Object reduce(final ArrayV1.Callback callback) {
            return methods.reduce(callback);
        }

        @SuppressWarnings('PMD.ApexDoc')
        public Object reduceRight(final ArrayV1.Callback callback) {
            return methods.reduceRight(callback);
        }

        @SuppressWarnings('PMD.ApexDoc')
        public Object reduce(final ArrayV1.Callback callback, final Object initialValue) {
            return methods.reduce(callback, initialValue);
        }

        @SuppressWarnings('PMD.ApexDoc')
        public Object reduceRight(final ArrayV1.Callback callback, final Object initialValue) {
            return methods.reduceRight(callback, initialValue);
        }

        @SuppressWarnings('PMD.ApexDoc')
        public List<Object> filter(final ArrayV1.Callback callback) {
            return methods.filter(callback);
        }

        @SuppressWarnings('PMD.ApexDoc')
        public List<Object> transform(final ArrayV1.Callback callback) {
            return methods.transform(callback);
        }

        @SuppressWarnings('PMD.ApexDoc')
        public List<Object> transform(final ArrayV1.Callback callback, final List<Object> returnList) {
            return methods.transform(callback, returnList);
        }

        @SuppressWarnings('PMD.ApexDoc')
        public List<Object> concat(final List<Object> elements) {
            return methods.concat(elements);
        }

        @SuppressWarnings('PMD.ApexDoc')
        public OptionalV1 at(final Integer index) {
            return methods.at(index);
        }

        @SuppressWarnings('PMD.ApexDoc')
        public String join(final String separator) {
            return methods.join(separator);
        }

        @SuppressWarnings('PMD.ApexDoc')
        public Boolean some(final ArrayV1.Callback callback) {
            return methods.some(callback);
        }

        @SuppressWarnings('PMD.ApexDoc')
        public Boolean every(final ArrayV1.Callback callback) {
            return methods.every(callback);
        }

        @SuppressWarnings('PMD.ApexDoc')
        public List<Object> reverse() {
            return methods.reverse();
        }

        @SuppressWarnings('PMD.ApexDoc')
        public void push(final Object obj) {
            throw new ImmutableV1.APIException('Mutation of collection not allowed');
        }

        @SuppressWarnings('PMD.ApexDoc')
        public OptionalV1 pop() {
            throw new ImmutableV1.APIException('Mutation of collection not allowed');
        }

        @SuppressWarnings('PMD.ApexDoc')
        public OptionalV1 shift() {
            throw new ImmutableV1.APIException('Mutation of collection not allowed');
        }

        @SuppressWarnings('PMD.ApexDoc')
        public List<Object> sort() {
            return methods.sort();
        }

        @SuppressWarnings('PMD.ApexDoc')
        public List<Object> sort(final Comparator<Object> comparator) {
            return methods.sort(comparator);
        }
    }

    /**
     * @description
     * <p>
     * Implementation of immutable Map.
     */
    private with sharing class ImmutableMap implements ImmutableV1.ReadOnlyMap {
        private final Map<Object, Object> wrapped;

        /**
         * @description
         * <p>
         * Constructs an immutable Map for the given source Map.
         *
         * @param source The Map to be return an immutable Map for.
         */
        public ImmutableMap(final Map<Object, Object> source) {
            this.wrapped = source;
        }

        @SuppressWarnings('PMD.ApexDoc')
        public Object get(final Object key) {
            return wrapped.get(key);
        }

        @SuppressWarnings('PMD.ApexDoc')
        public Boolean containsKey(final Object key) {
            return wrapped.containsKey(key);
        }

        @SuppressWarnings('PMD.ApexDoc')
        public List<Object> values() {
            return wrapped.values();
        }

        @SuppressWarnings('PMD.ApexDoc')
        public Set<Object> keySet() {
            return wrapped.keySet();
        }

        @SuppressWarnings('PMD.ApexDoc')
        public Boolean isEmpty() {
            return wrapped.isEmpty();
        }

        @SuppressWarnings('PMD.ApexDoc')
        public Integer size() {
            return wrapped.size();
        }

        @SuppressWarnings('PMD.ApexDoc')
        public Iterator<Object> iterator() {
            return keySet().iterator();
        }
    }

    /**
     * @description
     * <p>
     * Builds an immutable Collection for the given List.
     *
     * @param source The List to be made immutable.
     *
     * @return The immutable Collection.
     */
    public static ImmutableV1.Collection newCollection(final List<Object> source) {
        return new CollectionImpl(source);
    }

    /**
     * @description
     * <p>
     * Builds an immutable Map for the given Map.
     *
     * @param source The Map to be made immutable.
     *
     * @return The immutable Map.
     */
    public static ImmutableV1.ReadOnlyMap newMap(final Map<Object, Object> source) {
        return new ImmutableMap(source);
    }
}