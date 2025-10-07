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

    private with sharing class CollectionImpl implements ImmutableV1.Collection {
        private final ArrayV1.Methods methods {
            private get {
                if (methods == null) {
                    methods = ArrayV1.over(wrapped);
                }
                return methods;
            }
            private set;
        }

        private final List<Object> wrapped;

        public CollectionImpl(final List<Object> source) {
            this.wrapped = source;
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

        public Boolean containsAll(List<Object> objs) {
            for (Object obj : objs) {
                if (!contains(obj)) {
                    return false;
                }
            }

            return true;
        }

        public Boolean containsAll(Set<Object> objs) {
            for (Object obj : objs) {
                if (!contains(obj)) {
                    return false;
                }
            }

            return true;
        }

        public Iterator<Object> iterator() {
            return wrapped.iterator();
        }

        public List<Object> toList() {
            return toList(CommonHelper.newListOfSameType(wrapped));
        }

        public List<Object> toList(final List<Object> result) {
            for (Object obj : wrapped) {
                result.add(obj);
            }

            return result;
        }

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
            throw new ImmutableV1.APIException('Mutation of collection not allowed');
        }

        public OptionalV1 pop() {
            throw new ImmutableV1.APIException('Mutation of collection not allowed');
        }

        public OptionalV1 shift() {
            throw new ImmutableV1.APIException('Mutation of collection not allowed');
        }

        public List<Object> sort() {
            return methods.sort();
        }

        public List<Object> sort(final Comparator<Object> comparator) {
            return methods.sort(comparator);
        }
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

    public static ImmutableV1.Collection newCollection(final List<Object> source) {
        return new CollectionImpl(source);
    }

    public static ImmutableV1.ReadOnlyMap newMap(final Map<Object, Object> source) {
        return new ImmutableMap(source);
    }
}