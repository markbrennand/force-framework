/**
 * @description
 * <p>
 * Unit tests for Collections.
 * <p>
 * See <a href=./../source/collection/README.md target="_blank">README</a> for full details of the Collection API.
 * <p>
 * The Methods interface is tested by the ArrayTests class.
 * <p>
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../LICENSE target="_blank">MIT License</a>.
 *
 * @author Mark Brennand
 */
@IsTest
public with sharing class ImmutableTests {

    private final static String TESTING = 'collection';

    @TestSetup
    private static void createUsers() {
        TestHelper.createUsers(TESTING, new Set<String>());
    }

    @IsTest
    private static void testCollectionFromList() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            ImmutableV1.Collection stringList = ImmutableV1.of(new List<String>{ 'C', 'A', 'B'});
            ImmutableV1.Collection emptyList = ImmutableV1.of(new List<String>());
            testCollection(stringList, emptyList);
        }
    }

    @IsTest
    private static void testCollectionFromSet() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            ImmutableV1.Collection stringSet = ImmutableV1.of(new Set<String>{ 'C', 'A', 'B' });
            ImmutableV1.Collection emptySet = ImmutableV1.of(new Set<String>());
            testCollection(stringSet, emptySet);
        }
    }

    @IsTest
    private static void testExceptionOnMutation() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            ImmutableV1.Collection collection = ImmutableV1.of(new List<String>{
                    'C', 'A', 'B'
            });

            try {
                collection.push('A');
            } catch (ImmutableV1.APIException ae) {
                Assert.areEqual('Mutation of collection not allowed', ae.getMessage());
            }

            try {
                collection.pop();
            } catch (ImmutableV1.APIException ae) {
                Assert.areEqual('Mutation of collection not allowed', ae.getMessage());
            }

            try {
                collection.shift();
            } catch (ImmutableV1.APIException ae) {
                Assert.areEqual('Mutation of collection not allowed', ae.getMessage());
            }
        }
    }

    private static void testCollection(final ImmutableV1.Collection collection, final ImmutableV1.Collection emptyCollection) {
        Assert.isFalse(collection.isEmpty());
        Assert.areEqual(3, collection.size());
        Assert.isTrue(collection.contains('A'));
        Assert.isTrue(collection.contains('B'));
        Assert.isTrue(collection.contains('C'));
        Assert.isFalse(collection.contains('D'));
        Assert.areEqual(0, collection.indexOf('C'));
        Assert.areEqual(1, collection.indexOf('A'));
        Assert.areEqual(2, collection.indexOf('B'));
        Assert.areEqual(-1, collection.indexOf('D'));
        Assert.areEqual('C', collection.get(0));
        Assert.areEqual('A', collection.get(1));
        Assert.areEqual('B', collection.get(2));
        Assert.isTrue(collection.containsAll(new List<String>{
                'A', 'B', 'C'
        }));
        Assert.isTrue(collection.containsAll(new Set<Object>{
                'A', 'B', 'C'
        }));
        Assert.isFalse(collection.containsAll(new List<String>{
                'A', 'B', 'C', 'D'
        }));
        Assert.isFalse(collection.containsAll(new Set<Object>{
                'A', 'B', 'C', 'D'
        }));
        Assert.areEqual(3, collection.toList().size());
        Assert.isTrue(collection.toList().contains('A'));
        Assert.isTrue(collection.toList().contains('B'));
        Assert.isTrue(collection.toList().contains('C'));
        Assert.isFalse(collection.toList().contains('D'));
        Assert.areEqual(3, collection.toList(new List<String>()).size());
        Assert.isTrue(collection.toList(new List<String>()).contains('A'));
        Assert.isTrue(collection.toList(new List<String>()).contains('B'));
        Assert.isTrue(collection.toList(new List<String>()).contains('C'));
        Assert.isFalse(collection.toList(new List<String>()).contains('D'));

        String concatenation = '';
        for (Object obj : collection) {
            concatenation += obj;
        }
        Assert.areEqual('CAB', concatenation);

        Assert.isTrue(emptyCollection.isEmpty());
        Assert.areEqual(0, emptyCollection.size());
        Assert.areEqual(0, emptyCollection.toList().size());
        Assert.isFalse(emptyCollection.contains('A'));
        Assert.isFalse(emptyCollection.contains('B'));
        Assert.isFalse(emptyCollection.contains('C'));
        Assert.isFalse(emptyCollection.contains('D'));
        Assert.areEqual(-1, emptyCollection.indexOf('A'));
        Assert.areEqual(-1, emptyCollection.indexOf('B'));
        Assert.areEqual(-1, emptyCollection.indexOf('C'));
        Assert.areEqual(-1, emptyCollection.indexOf('D'));
        Assert.isFalse(emptyCollection.containsAll(new List<String>{
                'A', 'B', 'C'
        }));
        Assert.isFalse(emptyCollection.containsAll(new Set<Object>{
                'A', 'B', 'C'
        }));
        Assert.isFalse(emptyCollection.toList().contains('A'));
        Assert.isFalse(emptyCollection.toList().contains('B'));
        Assert.isFalse(emptyCollection.toList().contains('C'));
        Assert.isFalse(emptyCollection.toList().contains('D'));
        Assert.areEqual(0, emptyCollection.toList(new List<String>()).size());
        Assert.isFalse(emptyCollection.toList(new List<String>()).contains('A'));
        Assert.isFalse(emptyCollection.toList(new List<String>()).contains('B'));
        Assert.isFalse(emptyCollection.toList(new List<String>()).contains('C'));
        Assert.isFalse(emptyCollection.toList(new List<String>()).contains('D'));

        concatenation = '';
        for (Object obj : emptyCollection) {
            concatenation += obj;
        }
        Assert.areEqual('', concatenation);
    }
}