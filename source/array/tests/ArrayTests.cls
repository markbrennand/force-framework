/**
 * @description
 * <p>
 * Unit tests for ArrayV1 class.
 * <p>
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../LICENSE target="_blank">MIT License</a>.
 *
 * @author Mark Brennand
 */
@IsTest
@SuppressWarnings('PMD')
public with sharing class ArrayTests {
    private final static String TESTING = 'array';

    @TestSetup
    private static void createUsers() {
        TestHelper.createUsers(TESTING, new Set<String>());
    }

    @IsTest
    private static void testListConcat() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            testConcat(new List<Integer>{ 1, 2, 3 });
        }
    }

    @IsTest
    private static void testSetConcat() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            testConcat(new Set<Integer>{ 1, 2, 3 });
        }
    }

    @IsTest
    private static void testIterableConcat() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            testConcat(new TestIterable(new List<Integer> { 1, 2, 3 }));
        }
    }

    @IsTest
    private static void testOptionalListConcat() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            testConcat(OptionalV1.of(new List<Integer>{ 1, 2, 3 }));
        }
    }

    @IsTest
    private static void testOptionalSetConcat() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            testConcat(OptionalV1.of(new Set<Integer>{ 1, 2, 3 }));
        }
    }

    @IsTest
    private static void testOptionalCollectionConcat() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            testConcat(OptionalV1.of(ImmutableV1.of(new List<Integer>{ 1, 2, 3 })));
        }
    }

    private static void testConcat(Object toTest) {
        List<Object> result = getMethods(toTest).concat(new List<Integer>{ 4, 5 });
        Assert.areEqual(5, result.size());
        for (Integer index = 0; index < 5; index++) {
            Assert.areEqual(index + 1, result[index]);
        }
    }

    @IsTest
    private static void testListForEach() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            testForEach(new List<Integer> { 1, 2, 3, 4, 5 });
        }
    }

    @IsTest
    private static void testSetForEach() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            testForEach(new Set<Integer> { 1, 2, 3, 4, 5 });
        }
    }

    @IsTest
    private static void testIterableForEach() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            testForEach(new TestIterable(new List<Integer> { 1, 2, 3, 4, 5 }));
        }
    }

    @IsTest
    private static void testOptionalListForEach() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            testForEach(OptionalV1.of(new List<Integer> { 1, 2, 3, 4, 5 }));
        }
    }

    @IsTest
    private static void testOptionalSetForEach() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            testForEach(OptionalV1.of(new Set<Integer> { 1, 2, 3, 4, 5 }));
        }
    }

    @IsTest
    private static void testOptionalCollectionForEach() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            testForEach(OptionalV1.of(ImmutableV1.of(new Set<Integer> { 1, 2, 3, 4, 5 })));
        }
    }

    private static void testForEach(Object toTest) {
        List<Integer> result = new List<Integer>();
        getMethods(toTest).sharing(result).forEach(new ForEachMultiplier());
        Assert.areEqual(5, result.size());
        Assert.areEqual(2, result[0]);
        Assert.areEqual(4, result[1]);
        Assert.areEqual(6, result[2]);
        Assert.areEqual(8, result[3]);
        Assert.areEqual(10, result[4]);
    }

    @IsTest
    private static void testListReduce() {
        System.runAs(TestHelper.getUser(TESTING)) {
            TestHelper.setNOW();
            Assert.areEqual(-13, ArrayV1.over(new List<Integer>{ 1, 2, 3, 4, 5 }).reduce(new ReduceSubtractor()));
            Assert.areEqual(1, ArrayV1.over(new List<Integer> { 1 }).reduce(new ReduceSubtractor()));
            Assert.isTrue(((List<Integer>) ArrayV1.over(new List<Integer>()).reduce(new ReduceSubtractor(), new List<Integer>())).isEmpty());

            try {
                Assert.areEqual(1, ArrayV1.over(new List<Integer>()).reduce(new ReduceSubtractor()));
                Assert.fail();
            } catch(ArrayV1.APIException ae) {
                Assert.areEqual('The reduce() method requires an array containing at least one element', ae.getMessage());
            }

            Map<String, Object> merged = (Map<String, Object>) ArrayV1.over(new List<AsynchronousJob__c>{
                    new AsynchronousJob__c(
                            Runnable__c = 'TEST',
                            RetryInterval__c = 1000,
                            Status__c = 'STATUS1'
                    ),
                    new AsynchronousJob__c(
                            RetryNumber__c = 0,
                            MaximumRetries__c = 100,
                            Status__c = 'STATUS2'
                    )
            })
                    .reduce(new ObjectMerger(), new Map<String, Object>());

            Assert.areEqual(100, merged.get(AsynchronousJob__c.MaximumRetries__c.getDescribe().name));
            Assert.areEqual(1000, merged.get(AsynchronousJob__c.RetryInterval__c.getDescribe().name));
            Assert.areEqual(0, merged.get(AsynchronousJob__c.RetryNumber__c.getDescribe().name));
            Assert.areEqual('TEST', merged.get(AsynchronousJob__c.Runnable__c.getDescribe().name));
            Assert.areEqual('STATUS2', merged.get(AsynchronousJob__c.Status__c.getDescribe().name));

            Map<String, Object> values = (Map<String, Object>) ArrayV1.over(new List<SObjectField>{
                    AsynchronousJob__c.MaximumRetries__c,
                    AsynchronousJob__c.RetryInterval__c,
                    AsynchronousJob__c.RetryNumber__c,
                    AsynchronousJob__c.Runnable__c
            })
                    .sharing(merged)
                    .reduce(new ValueExtractor(), new Map<String, Object>());

            Assert.areEqual(100, values.get(AsynchronousJob__c.MaximumRetries__c.getDescribe().name));
            Assert.areEqual(1000, values.get(AsynchronousJob__c.RetryInterval__c.getDescribe().name));
            Assert.areEqual(0, values.get(AsynchronousJob__c.RetryNumber__c.getDescribe().name));
            Assert.areEqual('TEST', values.get(AsynchronousJob__c.Runnable__c.getDescribe().name));
        }
    }

    @IsTest
    private static void testSetReduce() {
        System.runAs(TestHelper.getUser(TESTING)) {
            TestHelper.setNOW();
            Assert.areEqual(-13, ArrayV1.over(new Set<Integer>{ 1, 2, 3, 4, 5 }).reduce(new ReduceSubtractor()));
            Assert.areEqual(1, ArrayV1.over(new Set<Integer> { 1 }).reduce(new ReduceSubtractor()));
            Assert.isTrue(((List<Integer>) ArrayV1.over(new Set<Integer>()).reduce(new ReduceSubtractor(), new List<Integer>())).isEmpty());

            try {
                Assert.areEqual(1, ArrayV1.over(new Set<Integer>()).reduce(new ReduceSubtractor()));
                Assert.fail();
            } catch(ArrayV1.APIException ae) {
                Assert.areEqual('The reduce() method requires an array containing at least one element', ae.getMessage());
            }

            Map<String, Object> merged = (Map<String, Object>) ArrayV1.over(new Set<AsynchronousJob__c>{
                    new AsynchronousJob__c(
                            Runnable__c = 'TEST',
                            RetryInterval__c = 1000,
                            Status__c = 'STATUS1'
                    ),
                    new AsynchronousJob__c(
                            RetryNumber__c = 0,
                            MaximumRetries__c = 100,
                            Status__c = 'STATUS2'
                    )
            })
                    .reduce(new ObjectMerger(), new Map<String, Object>());

            Assert.areEqual(100, merged.get(AsynchronousJob__c.MaximumRetries__c.getDescribe().name));
            Assert.areEqual(1000, merged.get(AsynchronousJob__c.RetryInterval__c.getDescribe().name));
            Assert.areEqual(0, merged.get(AsynchronousJob__c.RetryNumber__c.getDescribe().name));
            Assert.areEqual('TEST', merged.get(AsynchronousJob__c.Runnable__c.getDescribe().name));
            Assert.areEqual('STATUS2', merged.get(AsynchronousJob__c.Status__c.getDescribe().name));

            Map<String, Object> values = (Map<String, Object>) ArrayV1.over(new List<SObjectField>{
                    AsynchronousJob__c.MaximumRetries__c,
                    AsynchronousJob__c.RetryInterval__c,
                    AsynchronousJob__c.RetryNumber__c,
                    AsynchronousJob__c.Runnable__c
            })
                    .sharing(merged)
                    .reduce(new ValueExtractor(), new Map<String, Object>());

            Assert.areEqual(100, values.get(AsynchronousJob__c.MaximumRetries__c.getDescribe().name));
            Assert.areEqual(1000, values.get(AsynchronousJob__c.RetryInterval__c.getDescribe().name));
            Assert.areEqual(0, values.get(AsynchronousJob__c.RetryNumber__c.getDescribe().name));
            Assert.areEqual('TEST', values.get(AsynchronousJob__c.Runnable__c.getDescribe().name));
        }
    }

    @IsTest
    private static void testIterableReduce() {
        System.runAs(TestHelper.getUser(TESTING)) {
            TestHelper.setNOW();
            Assert.areEqual(-13, ArrayV1.over(new TestIterable(new List<Integer>{ 1, 2, 3, 4, 5 })).reduce(new ReduceSubtractor()));
            Assert.areEqual(1, ArrayV1.over(new TestIterable(new List<Integer> { 1 })).reduce(new ReduceSubtractor()));
            Assert.isTrue(((List<Integer>) ArrayV1.over(new TestIterable(new List<Integer>())).reduce(new ReduceSubtractor(), new List<Integer>())).isEmpty());

            try {
                Assert.areEqual(1, ArrayV1.over(new TestIterable(new List<Integer>())).reduce(new ReduceSubtractor()));
                Assert.fail();
            } catch(ArrayV1.APIException ae) {
                Assert.areEqual('The reduce() method requires an array containing at least one element', ae.getMessage());
            }

            Map<String, Object> merged = (Map<String, Object>) ArrayV1.over(new TestIterable(new List<AsynchronousJob__c>{
                    new AsynchronousJob__c(
                            Runnable__c = 'TEST',
                            RetryInterval__c = 1000,
                            Status__c = 'STATUS1'
                    ),
                    new AsynchronousJob__c(
                            RetryNumber__c = 0,
                            MaximumRetries__c = 100,
                            Status__c = 'STATUS2'
                    )
            }))
                    .reduce(new ObjectMerger(), new Map<String, Object>());

            Assert.areEqual(100, merged.get(AsynchronousJob__c.MaximumRetries__c.getDescribe().name));
            Assert.areEqual(1000, merged.get(AsynchronousJob__c.RetryInterval__c.getDescribe().name));
            Assert.areEqual(0, merged.get(AsynchronousJob__c.RetryNumber__c.getDescribe().name));
            Assert.areEqual('TEST', merged.get(AsynchronousJob__c.Runnable__c.getDescribe().name));
            Assert.areEqual('STATUS2', merged.get(AsynchronousJob__c.Status__c.getDescribe().name));

            Map<String, Object> values = (Map<String, Object>) ArrayV1.over(new TestIterable(new List<SObjectField>{
                    AsynchronousJob__c.MaximumRetries__c,
                    AsynchronousJob__c.RetryInterval__c,
                    AsynchronousJob__c.RetryNumber__c,
                    AsynchronousJob__c.Runnable__c
            }))
                    .sharing(merged)
                    .reduce(new ValueExtractor(), new Map<String, Object>());

            Assert.areEqual(100, values.get(AsynchronousJob__c.MaximumRetries__c.getDescribe().name));
            Assert.areEqual(1000, values.get(AsynchronousJob__c.RetryInterval__c.getDescribe().name));
            Assert.areEqual(0, values.get(AsynchronousJob__c.RetryNumber__c.getDescribe().name));
            Assert.areEqual('TEST', values.get(AsynchronousJob__c.Runnable__c.getDescribe().name));
        }
    }

    @IsTest
    private static void testOptionalListReduce() {
        System.runAs(TestHelper.getUser(TESTING)) {
            TestHelper.setNOW();
            Assert.areEqual(-13, OptionalV1.of(new List<Integer>{ 1, 2, 3, 4, 5 }).collection().reduce(new ReduceSubtractor()));
            Assert.areEqual(1, OptionalV1.of(new List<Integer> { 1 }).collection().reduce(new ReduceSubtractor()));
            Assert.isTrue(((List<Integer>) OptionalV1.of(new List<Integer>()).collection().reduce(new ReduceSubtractor(), new List<Integer>())).isEmpty());

            try {
                Assert.areEqual(1, OptionalV1.of(new List<Integer>()).collection().reduce(new ReduceSubtractor()));
                Assert.fail();
            } catch(ArrayV1.APIException ae) {
                Assert.areEqual('The reduce() method requires an array containing at least one element', ae.getMessage());
            }

            Map<String, Object> merged = (Map<String, Object>) OptionalV1.of(new List<AsynchronousJob__c>{
                    new AsynchronousJob__c(
                            Runnable__c = 'TEST',
                            RetryInterval__c = 1000,
                            Status__c = 'STATUS1'
                    ),
                    new AsynchronousJob__c(
                            RetryNumber__c = 0,
                            MaximumRetries__c = 100,
                            Status__c = 'STATUS2'
                    )
            })
                    .collection()
                    .reduce(new ObjectMerger(), new Map<String, Object>());

            Assert.areEqual(100, merged.get(AsynchronousJob__c.MaximumRetries__c.getDescribe().name));
            Assert.areEqual(1000, merged.get(AsynchronousJob__c.RetryInterval__c.getDescribe().name));
            Assert.areEqual(0, merged.get(AsynchronousJob__c.RetryNumber__c.getDescribe().name));
            Assert.areEqual('TEST', merged.get(AsynchronousJob__c.Runnable__c.getDescribe().name));
            Assert.areEqual('STATUS2', merged.get(AsynchronousJob__c.Status__c.getDescribe().name));

            Map<String, Object> values = (Map<String, Object>) OptionalV1.of(new List<SObjectField>{
                    AsynchronousJob__c.MaximumRetries__c,
                    AsynchronousJob__c.RetryInterval__c,
                    AsynchronousJob__c.RetryNumber__c,
                    AsynchronousJob__c.Runnable__c
            })
                    .collection()
                    .sharing(merged)
                    .reduce(new ValueExtractor(), new Map<String, Object>());

            Assert.areEqual(100, values.get(AsynchronousJob__c.MaximumRetries__c.getDescribe().name));
            Assert.areEqual(1000, values.get(AsynchronousJob__c.RetryInterval__c.getDescribe().name));
            Assert.areEqual(0, values.get(AsynchronousJob__c.RetryNumber__c.getDescribe().name));
            Assert.areEqual('TEST', values.get(AsynchronousJob__c.Runnable__c.getDescribe().name));
        }
    }

    @IsTest
    private static void testOptionalSetReduce() {
        System.runAs(TestHelper.getUser(TESTING)) {
            TestHelper.setNOW();
            Assert.areEqual(-13, OptionalV1.of(new Set<Integer>{ 1, 2, 3, 4, 5 }).collection().reduce(new ReduceSubtractor()));
            Assert.areEqual(1, OptionalV1.of(new Set<Integer> { 1 }).collection().reduce(new ReduceSubtractor()));
            Assert.isTrue(((List<Integer>) OptionalV1.of(new Set<Integer>()).collection().reduce(new ReduceSubtractor(), new List<Integer>())).isEmpty());

            try {
                Assert.areEqual(1, OptionalV1.of(new Set<Integer>()).collection().reduce(new ReduceSubtractor()));
                Assert.fail();
            } catch(ArrayV1.APIException ae) {
                Assert.areEqual('The reduce() method requires an array containing at least one element', ae.getMessage());
            }

            Map<String, Object> merged = (Map<String, Object>) OptionalV1.of(new Set<AsynchronousJob__c>{
                    new AsynchronousJob__c(
                            Runnable__c = 'TEST',
                            RetryInterval__c = 1000,
                            Status__c = 'STATUS1'
                    ),
                    new AsynchronousJob__c(
                            RetryNumber__c = 0,
                            MaximumRetries__c = 100,
                            Status__c = 'STATUS2'
                    )
            })
                    .collection()
                    .reduce(new ObjectMerger(), new Map<String, Object>());

            Assert.areEqual(100, merged.get(AsynchronousJob__c.MaximumRetries__c.getDescribe().name));
            Assert.areEqual(1000, merged.get(AsynchronousJob__c.RetryInterval__c.getDescribe().name));
            Assert.areEqual(0, merged.get(AsynchronousJob__c.RetryNumber__c.getDescribe().name));
            Assert.areEqual('TEST', merged.get(AsynchronousJob__c.Runnable__c.getDescribe().name));
            Assert.areEqual('STATUS2', merged.get(AsynchronousJob__c.Status__c.getDescribe().name));

            Map<String, Object> values = (Map<String, Object>) OptionalV1.of(new Set<SObjectField>{
                    AsynchronousJob__c.MaximumRetries__c,
                    AsynchronousJob__c.RetryInterval__c,
                    AsynchronousJob__c.RetryNumber__c,
                    AsynchronousJob__c.Runnable__c
            })
                    .collection()
                    .sharing(merged)
                    .reduce(new ValueExtractor(), new Map<String, Object>());

            Assert.areEqual(100, values.get(AsynchronousJob__c.MaximumRetries__c.getDescribe().name));
            Assert.areEqual(1000, values.get(AsynchronousJob__c.RetryInterval__c.getDescribe().name));
            Assert.areEqual(0, values.get(AsynchronousJob__c.RetryNumber__c.getDescribe().name));
            Assert.areEqual('TEST', values.get(AsynchronousJob__c.Runnable__c.getDescribe().name));
        }
    }

    @IsTest
    private static void testOptionalCollectionReduce() {
        System.runAs(TestHelper.getUser(TESTING)) {
            TestHelper.setNOW();
            Assert.areEqual(-13, OptionalV1.of(ImmutableV1.of(new Set<Integer>{ 1, 2, 3, 4, 5 })).collection().reduce(new ReduceSubtractor()));
            Assert.areEqual(1, OptionalV1.of(ImmutableV1.of(new Set<Integer> { 1 })).collection().reduce(new ReduceSubtractor()));
            Assert.isTrue(((List<Integer>) OptionalV1.of(ImmutableV1.of(new Set<Integer>())).collection().reduce(new ReduceSubtractor(), new List<Integer>())).isEmpty());

            try {
                Assert.areEqual(1, OptionalV1.of(ImmutableV1.of(new Set<Integer>())).collection().reduce(new ReduceSubtractor()));
                Assert.fail();
            } catch(ArrayV1.APIException ae) {
                Assert.areEqual('The reduce() method requires an array containing at least one element', ae.getMessage());
            }

            Map<String, Object> merged = (Map<String, Object>) OptionalV1.of(ImmutableV1.of(new Set<AsynchronousJob__c>{
                    new AsynchronousJob__c(
                            Runnable__c = 'TEST',
                            RetryInterval__c = 1000,
                            Status__c = 'STATUS1'
                    ),
                    new AsynchronousJob__c(
                            RetryNumber__c = 0,
                            MaximumRetries__c = 100,
                            Status__c = 'STATUS2'
                    )
            }))
                    .collection()
                    .reduce(new ObjectMerger(), new Map<String, Object>());

            Assert.areEqual(100, merged.get(AsynchronousJob__c.MaximumRetries__c.getDescribe().name));
            Assert.areEqual(1000, merged.get(AsynchronousJob__c.RetryInterval__c.getDescribe().name));
            Assert.areEqual(0, merged.get(AsynchronousJob__c.RetryNumber__c.getDescribe().name));
            Assert.areEqual('TEST', merged.get(AsynchronousJob__c.Runnable__c.getDescribe().name));
            Assert.areEqual('STATUS2', merged.get(AsynchronousJob__c.Status__c.getDescribe().name));

            Map<String, Object> values = (Map<String, Object>) OptionalV1.of(ImmutableV1.of(new Set<SObjectField>{
                    AsynchronousJob__c.MaximumRetries__c,
                    AsynchronousJob__c.RetryInterval__c,
                    AsynchronousJob__c.RetryNumber__c,
                    AsynchronousJob__c.Runnable__c
            }))
                    .collection()
                    .sharing(merged)
                    .reduce(new ValueExtractor(), new Map<String, Object>());

            Assert.areEqual(100, values.get(AsynchronousJob__c.MaximumRetries__c.getDescribe().name));
            Assert.areEqual(1000, values.get(AsynchronousJob__c.RetryInterval__c.getDescribe().name));
            Assert.areEqual(0, values.get(AsynchronousJob__c.RetryNumber__c.getDescribe().name));
            Assert.areEqual('TEST', values.get(AsynchronousJob__c.Runnable__c.getDescribe().name));
        }
    }

    @IsTest
    private static void testListReduceRight() {
        System.runAs(TestHelper.getUser(TESTING)) {
            TestHelper.setNOW();
            Assert.areEqual(-5, ArrayV1.over(new List<Integer>{ 1, 2, 3, 4, 5 }).reduceRight(new ReduceSubtractor()));
            Assert.areEqual(1, ArrayV1.over(new List<Integer> { 1 }).reduceRight(new ReduceSubtractor()));

            try {
                Assert.areEqual(1, ArrayV1.over(new List<Integer>()).reduceRight(new ReduceSubtractor()));
                Assert.fail();
            } catch(ArrayV1.APIException ae) {
                Assert.areEqual('The reduce() method requires an array containing at least one element', ae.getMessage());
            }

            Map<String, Object> merged = (Map<String, Object>) ArrayV1.over(new List<AsynchronousJob__c>{
                    new AsynchronousJob__c(
                            Runnable__c = 'TEST',
                            RetryInterval__c = 1000,
                            Status__c = 'STATUS1'
                    ),
                    new AsynchronousJob__c(
                            RetryNumber__c = 0,
                            MaximumRetries__c = 100,
                            Status__c = 'STATUS2'
                    )
            })
                    .reduceRight(new ObjectMerger(), new Map<String, Object>());

            Assert.areEqual(100, merged.get(AsynchronousJob__c.MaximumRetries__c.getDescribe().name));
            Assert.areEqual(1000, merged.get(AsynchronousJob__c.RetryInterval__c.getDescribe().name));
            Assert.areEqual(0, merged.get(AsynchronousJob__c.RetryNumber__c.getDescribe().name));
            Assert.areEqual('TEST', merged.get(AsynchronousJob__c.Runnable__c.getDescribe().name));
            Assert.areEqual('STATUS1', merged.get(AsynchronousJob__c.Status__c.getDescribe().name));

            Map<String, Object> values = (Map<String, Object>) ArrayV1.over(new List<SObjectField>{
                    AsynchronousJob__c.MaximumRetries__c,
                    AsynchronousJob__c.RetryInterval__c,
                    AsynchronousJob__c.RetryNumber__c,
                    AsynchronousJob__c.Runnable__c
            })
                    .sharing(merged)
                    .reduceRight(new ValueExtractor(), new Map<String, Object>());

            Assert.areEqual(100, values.get(AsynchronousJob__c.MaximumRetries__c.getDescribe().name));
            Assert.areEqual(1000, values.get(AsynchronousJob__c.RetryInterval__c.getDescribe().name));
            Assert.areEqual(0, values.get(AsynchronousJob__c.RetryNumber__c.getDescribe().name));
            Assert.areEqual('TEST', values.get(AsynchronousJob__c.Runnable__c.getDescribe().name));
        }
    }

    @IsTest
    private static void testSetReduceRight() {
        System.runAs(TestHelper.getUser(TESTING)) {
            TestHelper.setNOW();
            Assert.areEqual(-5, ArrayV1.over(new Set<Integer>{ 1, 2, 3, 4, 5 }).reduceRight(new ReduceSubtractor()));
            Assert.areEqual(1, ArrayV1.over(new Set<Integer> { 1 }).reduceRight(new ReduceSubtractor()));

            try {
                Assert.areEqual(1, ArrayV1.over(new Set<Integer>()).reduceRight(new ReduceSubtractor()));
                Assert.fail();
            } catch(ArrayV1.APIException ae) {
                Assert.areEqual('The reduce() method requires an array containing at least one element', ae.getMessage());
            }

            Map<String, Object> merged = (Map<String, Object>) ArrayV1.over(new Set<AsynchronousJob__c>{
                    new AsynchronousJob__c(
                            Runnable__c = 'TEST',
                            RetryInterval__c = 1000,
                            Status__c = 'STATUS1'
                    ),
                    new AsynchronousJob__c(
                            RetryNumber__c = 0,
                            MaximumRetries__c = 100,
                            Status__c = 'STATUS2'
                    )
            })
                    .reduceRight(new ObjectMerger(), new Map<String, Object>());

            Assert.areEqual(100, merged.get(AsynchronousJob__c.MaximumRetries__c.getDescribe().name));
            Assert.areEqual(1000, merged.get(AsynchronousJob__c.RetryInterval__c.getDescribe().name));
            Assert.areEqual(0, merged.get(AsynchronousJob__c.RetryNumber__c.getDescribe().name));
            Assert.areEqual('TEST', merged.get(AsynchronousJob__c.Runnable__c.getDescribe().name));
            Assert.areEqual('STATUS1', merged.get(AsynchronousJob__c.Status__c.getDescribe().name));

            Map<String, Object> values = (Map<String, Object>) ArrayV1.over(new Set<SObjectField>{
                    AsynchronousJob__c.MaximumRetries__c,
                    AsynchronousJob__c.RetryInterval__c,
                    AsynchronousJob__c.RetryNumber__c,
                    AsynchronousJob__c.Runnable__c
            })
                    .sharing(merged)
                    .reduceRight(new ValueExtractor(), new Map<String, Object>());

            Assert.areEqual(100, values.get(AsynchronousJob__c.MaximumRetries__c.getDescribe().name));
            Assert.areEqual(1000, values.get(AsynchronousJob__c.RetryInterval__c.getDescribe().name));
            Assert.areEqual(0, values.get(AsynchronousJob__c.RetryNumber__c.getDescribe().name));
            Assert.areEqual('TEST', values.get(AsynchronousJob__c.Runnable__c.getDescribe().name));
        }
    }

    @IsTest
    private static void testIterableReduceRight() {
        System.runAs(TestHelper.getUser(TESTING)) {
            TestHelper.setNOW();
            Assert.areEqual(-5, ArrayV1.over(new TestIterable(new List<Integer>{ 1, 2, 3, 4, 5 })).reduceRight(new ReduceSubtractor()));
            Assert.areEqual(1, ArrayV1.over(new TestIterable(new List<Integer> { 1 })).reduceRight(new ReduceSubtractor()));

            try {
                Assert.areEqual(1, ArrayV1.over(new TestIterable(new List<Integer>())).reduceRight(new ReduceSubtractor()));
                Assert.fail();
            } catch(ArrayV1.APIException ae) {
                Assert.areEqual('The reduce() method requires an array containing at least one element', ae.getMessage());
            }

            Map<String, Object> merged = (Map<String, Object>) ArrayV1.over(new TestIterable(new List<AsynchronousJob__c>{
                    new AsynchronousJob__c(
                            Runnable__c = 'TEST',
                            RetryInterval__c = 1000,
                            Status__c = 'STATUS1'
                    ),
                    new AsynchronousJob__c(
                            RetryNumber__c = 0,
                            MaximumRetries__c = 100,
                            Status__c = 'STATUS2'
                    )
            }))
                    .reduceRight(new ObjectMerger(), new Map<String, Object>());

            Assert.areEqual(100, merged.get(AsynchronousJob__c.MaximumRetries__c.getDescribe().name));
            Assert.areEqual(1000, merged.get(AsynchronousJob__c.RetryInterval__c.getDescribe().name));
            Assert.areEqual(0, merged.get(AsynchronousJob__c.RetryNumber__c.getDescribe().name));
            Assert.areEqual('TEST', merged.get(AsynchronousJob__c.Runnable__c.getDescribe().name));
            Assert.areEqual('STATUS1', merged.get(AsynchronousJob__c.Status__c.getDescribe().name));

            Map<String, Object> values = (Map<String, Object>) ArrayV1.over(new TestIterable(new List<SObjectField>{
                    AsynchronousJob__c.MaximumRetries__c,
                    AsynchronousJob__c.RetryInterval__c,
                    AsynchronousJob__c.RetryNumber__c,
                    AsynchronousJob__c.Runnable__c
            }))
                    .sharing(merged)
                    .reduceRight(new ValueExtractor(), new Map<String, Object>());

            Assert.areEqual(100, values.get(AsynchronousJob__c.MaximumRetries__c.getDescribe().name));
            Assert.areEqual(1000, values.get(AsynchronousJob__c.RetryInterval__c.getDescribe().name));
            Assert.areEqual(0, values.get(AsynchronousJob__c.RetryNumber__c.getDescribe().name));
            Assert.areEqual('TEST', values.get(AsynchronousJob__c.Runnable__c.getDescribe().name));
        }
    }


    @IsTest
    private static void testOptionalListReduceRight() {
        System.runAs(TestHelper.getUser(TESTING)) {
            TestHelper.setNOW();
            Assert.areEqual(-5, OptionalV1.of(new List<Integer>{ 1, 2, 3, 4, 5 }).collection().reduceRight(new ReduceSubtractor()));
            Assert.areEqual(1, OptionalV1.of(new List<Integer> { 1 }).collection().reduceRight(new ReduceSubtractor()));

            try {
                Assert.areEqual(1, OptionalV1.of(new List<Integer>()).collection().reduceRight(new ReduceSubtractor()));
                Assert.fail();
            } catch(ArrayV1.APIException ae) {
                Assert.areEqual('The reduce() method requires an array containing at least one element', ae.getMessage());
            }

            Map<String, Object> merged = (Map<String, Object>) OptionalV1.of(new List<AsynchronousJob__c>{
                    new AsynchronousJob__c(
                            Runnable__c = 'TEST',
                            RetryInterval__c = 1000,
                            Status__c = 'STATUS1'
                    ),
                    new AsynchronousJob__c(
                            RetryNumber__c = 0,
                            MaximumRetries__c = 100,
                            Status__c = 'STATUS2'
                    )
            })
                    .collection()
                    .reduceRight(new ObjectMerger(), new Map<String, Object>());

            Assert.areEqual(100, merged.get(AsynchronousJob__c.MaximumRetries__c.getDescribe().name));
            Assert.areEqual(1000, merged.get(AsynchronousJob__c.RetryInterval__c.getDescribe().name));
            Assert.areEqual(0, merged.get(AsynchronousJob__c.RetryNumber__c.getDescribe().name));
            Assert.areEqual('TEST', merged.get(AsynchronousJob__c.Runnable__c.getDescribe().name));
            Assert.areEqual('STATUS1', merged.get(AsynchronousJob__c.Status__c.getDescribe().name));

            Map<String, Object> values = (Map<String, Object>) OptionalV1.of(new List<SObjectField>{
                    AsynchronousJob__c.MaximumRetries__c,
                    AsynchronousJob__c.RetryInterval__c,
                    AsynchronousJob__c.RetryNumber__c,
                    AsynchronousJob__c.Runnable__c
            })
                    .collection()
                    .sharing(merged)
                    .reduceRight(new ValueExtractor(), new Map<String, Object>());

            Assert.areEqual(100, values.get(AsynchronousJob__c.MaximumRetries__c.getDescribe().name));
            Assert.areEqual(1000, values.get(AsynchronousJob__c.RetryInterval__c.getDescribe().name));
            Assert.areEqual(0, values.get(AsynchronousJob__c.RetryNumber__c.getDescribe().name));
            Assert.areEqual('TEST', values.get(AsynchronousJob__c.Runnable__c.getDescribe().name));
        }
    }

    @IsTest
    private static void testOptionalSetReduceRight() {
        System.runAs(TestHelper.getUser(TESTING)) {
            TestHelper.setNOW();
            Assert.areEqual(-5, OptionalV1.of(new Set<Integer>{ 1, 2, 3, 4, 5 }).collection().reduceRight(new ReduceSubtractor()));
            Assert.areEqual(1, OptionalV1.of(new Set<Integer> { 1 }).collection().reduceRight(new ReduceSubtractor()));

            try {
                Assert.areEqual(1, OptionalV1.of(new Set<Integer>()).collection().reduceRight(new ReduceSubtractor()));
                Assert.fail();
            } catch(ArrayV1.APIException ae) {
                Assert.areEqual('The reduce() method requires an array containing at least one element', ae.getMessage());
            }

            Map<String, Object> merged = (Map<String, Object>) OptionalV1.of(new Set<AsynchronousJob__c>{
                    new AsynchronousJob__c(
                            Runnable__c = 'TEST',
                            RetryInterval__c = 1000,
                            Status__c = 'STATUS1'
                    ),
                    new AsynchronousJob__c(
                            RetryNumber__c = 0,
                            MaximumRetries__c = 100,
                            Status__c = 'STATUS2'
                    )
            })
                    .collection()
                    .reduceRight(new ObjectMerger(), new Map<String, Object>());

            Assert.areEqual(100, merged.get(AsynchronousJob__c.MaximumRetries__c.getDescribe().name));
            Assert.areEqual(1000, merged.get(AsynchronousJob__c.RetryInterval__c.getDescribe().name));
            Assert.areEqual(0, merged.get(AsynchronousJob__c.RetryNumber__c.getDescribe().name));
            Assert.areEqual('TEST', merged.get(AsynchronousJob__c.Runnable__c.getDescribe().name));
            Assert.areEqual('STATUS1', merged.get(AsynchronousJob__c.Status__c.getDescribe().name));

            Map<String, Object> values = (Map<String, Object>) OptionalV1.of(new Set<SObjectField>{
                    AsynchronousJob__c.MaximumRetries__c,
                    AsynchronousJob__c.RetryInterval__c,
                    AsynchronousJob__c.RetryNumber__c,
                    AsynchronousJob__c.Runnable__c
            })
                    .collection()
                    .sharing(merged)
                    .reduceRight(new ValueExtractor(), new Map<String, Object>());

            Assert.areEqual(100, values.get(AsynchronousJob__c.MaximumRetries__c.getDescribe().name));
            Assert.areEqual(1000, values.get(AsynchronousJob__c.RetryInterval__c.getDescribe().name));
            Assert.areEqual(0, values.get(AsynchronousJob__c.RetryNumber__c.getDescribe().name));
            Assert.areEqual('TEST', values.get(AsynchronousJob__c.Runnable__c.getDescribe().name));
        }
    }

    @IsTest
    private static void testOptionalCollectionReduceRight() {
        System.runAs(TestHelper.getUser(TESTING)) {
            TestHelper.setNOW();
            Assert.areEqual(-5, OptionalV1.of(ImmutableV1.of(new Set<Integer>{ 1, 2, 3, 4, 5 })).collection().reduceRight(new ReduceSubtractor()));
            Assert.areEqual(1, OptionalV1.of(ImmutableV1.of(new Set<Integer> { 1 })).collection().reduceRight(new ReduceSubtractor()));

            try {
                Assert.areEqual(1, OptionalV1.of(ImmutableV1.of(new Set<Integer>())).collection().reduceRight(new ReduceSubtractor()));
                Assert.fail();
            } catch(ArrayV1.APIException ae) {
                Assert.areEqual('The reduce() method requires an array containing at least one element', ae.getMessage());
            }

            Map<String, Object> merged = (Map<String, Object>) OptionalV1.of(ImmutableV1.of(new Set<AsynchronousJob__c>{
                    new AsynchronousJob__c(
                            Runnable__c = 'TEST',
                            RetryInterval__c = 1000,
                            Status__c = 'STATUS1'
                    ),
                    new AsynchronousJob__c(
                            RetryNumber__c = 0,
                            MaximumRetries__c = 100,
                            Status__c = 'STATUS2'
                    )
            }))
                    .collection()
                    .reduceRight(new ObjectMerger(), new Map<String, Object>());

            Assert.areEqual(100, merged.get(AsynchronousJob__c.MaximumRetries__c.getDescribe().name));
            Assert.areEqual(1000, merged.get(AsynchronousJob__c.RetryInterval__c.getDescribe().name));
            Assert.areEqual(0, merged.get(AsynchronousJob__c.RetryNumber__c.getDescribe().name));
            Assert.areEqual('TEST', merged.get(AsynchronousJob__c.Runnable__c.getDescribe().name));
            Assert.areEqual('STATUS1', merged.get(AsynchronousJob__c.Status__c.getDescribe().name));

            Map<String, Object> values = (Map<String, Object>) OptionalV1.of(ImmutableV1.of(new Set<SObjectField>{
                    AsynchronousJob__c.MaximumRetries__c,
                    AsynchronousJob__c.RetryInterval__c,
                    AsynchronousJob__c.RetryNumber__c,
                    AsynchronousJob__c.Runnable__c
            }))
                    .collection()
                    .sharing(merged)
                    .reduceRight(new ValueExtractor(), new Map<String, Object>());

            Assert.areEqual(100, values.get(AsynchronousJob__c.MaximumRetries__c.getDescribe().name));
            Assert.areEqual(1000, values.get(AsynchronousJob__c.RetryInterval__c.getDescribe().name));
            Assert.areEqual(0, values.get(AsynchronousJob__c.RetryNumber__c.getDescribe().name));
            Assert.areEqual('TEST', values.get(AsynchronousJob__c.Runnable__c.getDescribe().name));
        }
    }

    @IsTest
    private static void testListFilter() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            testFilter(new List<AsynchronousJob__c>{
                    new AsynchronousJob__c(Runnable__c = 'TEST1'),
                    new AsynchronousJob__c(Runnable__c = 'TEST2')
            });
        }
    }

    @IsTest
    private static void testSetFilter() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            testFilter(new Set<AsynchronousJob__c>{
                    new AsynchronousJob__c(Runnable__c = 'TEST1'),
                    new AsynchronousJob__c(Runnable__c = 'TEST2')
            });
        }
    }

    @IsTest
    private static void testIterableFilter() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            testFilter(new TestIterable(new List<AsynchronousJob__c>{
                    new AsynchronousJob__c(Runnable__c = 'TEST1'),
                    new AsynchronousJob__c(Runnable__c = 'TEST2')
            }));
        }
    }

    @IsTest
    private static void testOptionalListFilter() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            testFilter(OptionalV1.of(new List<AsynchronousJob__c>{
                    new AsynchronousJob__c(Runnable__c = 'TEST1'),
                    new AsynchronousJob__c(Runnable__c = 'TEST2')
            }));
        }
    }

    @IsTest
    private static void testOptionalSetFilter() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            testFilter(OptionalV1.of(new Set<AsynchronousJob__c>{
                    new AsynchronousJob__c(Runnable__c = 'TEST1'),
                    new AsynchronousJob__c(Runnable__c = 'TEST2')
            }));
        }
    }

    @IsTest
    private static void testOptionalCollectionFilter() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            testFilter(OptionalV1.of(ImmutableV1.of(new Set<AsynchronousJob__c>{
                    new AsynchronousJob__c(Runnable__c = 'TEST1'),
                    new AsynchronousJob__c(Runnable__c = 'TEST2')
            })));
        }
    }

    private static void testFilter(Object toTest) {
        List<Object> results = getMethods(toTest).filter(new FilterTestRunnable());
        Assert.areEqual(1, results.size());
        Assert.areEqual('TEST1', ((AsynchronousJob__c) results[0]).Runnable__c);

        results = getMethods(toTest).sharing('TEST2').filter(new FilterTestRunnable());
        Assert.areEqual(1, results.size());
        Assert.areEqual('TEST2', ((AsynchronousJob__c) results[0]).Runnable__c);

        try {
            results = getMethods(toTest).sharing(123).filter(new FilterTestRunnable());
            Assert.fail();

        } catch (ArrayV1.APIException ae) {
            Assert.areEqual('Callback must return a Boolean', ae.getMessage());
        }
    }

    @IsTest
    private static void testListTransform() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            testTransform(new List<AsynchronousJob__c>{
                    new AsynchronousJob__c(Runnable__c = 'TEST1'),
                    new AsynchronousJob__c(Runnable__c = 'TEST2')
            });
        }
    }

    @IsTest
    private static void testSetTransform() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            testTransform(new Set<AsynchronousJob__c>{
                    new AsynchronousJob__c(Runnable__c = 'TEST1'),
                    new AsynchronousJob__c(Runnable__c = 'TEST2')
            });
        }
    }

    @IsTest
    private static void testIterableTransform() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            testTransform(new TestIterable(new List<AsynchronousJob__c>{
                    new AsynchronousJob__c(Runnable__c = 'TEST1'),
                    new AsynchronousJob__c(Runnable__c = 'TEST2')
            }));
        }
    }

    @IsTest
    private static void testOptionalListTransform() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            testTransform(OptionalV1.of(new List<AsynchronousJob__c>{
                    new AsynchronousJob__c(Runnable__c = 'TEST1'),
                    new AsynchronousJob__c(Runnable__c = 'TEST2')
            }));
        }
    }

    @IsTest
    private static void testOptionalSetTransform() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            testTransform(OptionalV1.of(new Set<AsynchronousJob__c>{
                    new AsynchronousJob__c(Runnable__c = 'TEST1'),
                    new AsynchronousJob__c(Runnable__c = 'TEST2')
            }));
        }
    }

    @IsTest
    private static void testOptionalCollectionTransform() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            testTransform(OptionalV1.of(ImmutableV1.of(new Set<AsynchronousJob__c>{
                    new AsynchronousJob__c(Runnable__c = 'TEST1'),
                    new AsynchronousJob__c(Runnable__c = 'TEST2')
            })));
        }
    }

    private static void testTransform(Object toTest) {
        List<Object> results = getMethods(toTest).transform(new Transformer());
        Assert.areEqual(2, results.size());
        Assert.areEqual('TEST1', results[0]);
        Assert.areEqual('TEST2', results[1]);

        List<String> stringResults = (List<String>) getMethods(toTest).transform(new Transformer(), new List<String>());
        Assert.areEqual(2, stringResults.size());
        Assert.areEqual('TEST1', stringResults[0]);
        Assert.areEqual('TEST2', stringResults[1]);
    }

    @IsTest
    private static void testListAt() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            testAt(new List<Integer> { 1, 2, 3, 4 });
        }
    }

    @IsTest
    private static void testSetAt() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            testAt(new Set<Integer> { 1, 2, 3, 4 });
        }
    }

    @IsTest
    private static void testIterableAt() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            testAt(new TestIterable(new List<Integer> { 1, 2, 3, 4 }));
        }
    }

    @IsTest
    private static void testOptionalListAt() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            testAt(OptionalV1.of(new List<Integer> { 1, 2, 3, 4 }));
        }
    }

    @IsTest
    private static void testOptionalSetAt() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            testAt(OptionalV1.of(new Set<Integer> { 1, 2, 3, 4 }));
        }
    }

    @IsTest
    private static void testOptionalCollectionAt() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            testAt(OptionalV1.of(ImmutableV1.of(new Set<Integer> { 1, 2, 3, 4 })));
        }
    }

    private static void testAt(Object toTest) {
        ArrayV1.Methods methods = getMethods(toTest);
        Assert.areEqual(1, methods.at(0).get());
        Assert.areEqual(4, methods.at(3).get());
        Assert.areEqual(3, methods.at(-2).get());
        Assert.areEqual(1, methods.at(-4).get());
        Assert.isFalse(methods.at(4).isPresent());
        Assert.isFalse(methods.at(-5).isPresent());
    }

    @IsTest
    private static void testListJoin() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            testJoin(new List<Integer> { 1, 2, 3, 4, 5 });
        }
    }

    @IsTest
    private static void testSetJoin() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            testJoin(new Set<Integer> { 1, 2, 3, 4, 5 });
        }
    }

    @IsTest
    private static void testIterableJoin() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            testJoin(new TestIterable(new List<Integer> { 1, 2, 3, 4, 5 }));
        }
    }

    @IsTest
    private static void testOptionalListJoin() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            testJoin(OptionalV1.of(new List<Integer> { 1, 2, 3, 4, 5 }));
        }
    }

    @IsTest
    private static void testOptionalSetJoin() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            testJoin(OptionalV1.of(new Set<Integer> { 1, 2, 3, 4, 5 }));
        }
    }

    @IsTest
    private static void testOptionalCollectionJoin() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            testJoin(OptionalV1.of(ImmutableV1.of(new Set<Integer> { 1, 2, 3, 4, 5 })));
        }
    }

    private static void testJoin(Object toTest) {
        Assert.areEqual('1-2-3-4-5', getMethods(toTest).join('-'));
    }

    @IsTest
    private static void testListSome() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            testSome(
                    new List<AsynchronousJob__c> {
                            new AsynchronousJob__c(Runnable__c = 'TEST1'),
                            new AsynchronousJob__c(Runnable__c = 'TEST2'),
                            new AsynchronousJob__c(Runnable__c = 'TEST3'),
                            new AsynchronousJob__c(Runnable__c = 'TEST1')
                    },
                    new List<AsynchronousJob__c>{
                            new AsynchronousJob__c(Runnable__c = 'TEST4'),
                            new AsynchronousJob__c(Runnable__c = 'TEST5')
                    }
            );
        }
    }

    @IsTest
    private static void testSetSome() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            testSome(
                    new Set<AsynchronousJob__c> {
                            new AsynchronousJob__c(Runnable__c = 'TEST1'),
                            new AsynchronousJob__c(Runnable__c = 'TEST2'),
                            new AsynchronousJob__c(Runnable__c = 'TEST3'),
                            new AsynchronousJob__c(Runnable__c = 'TEST1')
                    },
                    new Set<AsynchronousJob__c>{
                            new AsynchronousJob__c(Runnable__c = 'TEST4'),
                            new AsynchronousJob__c(Runnable__c = 'TEST5')
                    }
            );
        }
    }

    @IsTest
    private static void testIterableSome() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            testSome(
                    new TestIterable(new List<AsynchronousJob__c> {
                            new AsynchronousJob__c(Runnable__c = 'TEST1'),
                            new AsynchronousJob__c(Runnable__c = 'TEST2'),
                            new AsynchronousJob__c(Runnable__c = 'TEST3'),
                            new AsynchronousJob__c(Runnable__c = 'TEST1')
                    }),
                    new TestIterable(new List<AsynchronousJob__c>{
                            new AsynchronousJob__c(Runnable__c = 'TEST4'),
                            new AsynchronousJob__c(Runnable__c = 'TEST5')
                    })
            );
        }
    }

    @IsTest
    private static void testOptionalListSome() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            testSome(
                    OptionalV1.of(new List<AsynchronousJob__c> {
                            new AsynchronousJob__c(Runnable__c = 'TEST1'),
                            new AsynchronousJob__c(Runnable__c = 'TEST2'),
                            new AsynchronousJob__c(Runnable__c = 'TEST3'),
                            new AsynchronousJob__c(Runnable__c = 'TEST1')
                    }),
                    OptionalV1.of(new List<AsynchronousJob__c>{
                            new AsynchronousJob__c(Runnable__c = 'TEST4'),
                            new AsynchronousJob__c(Runnable__c = 'TEST5')
                    })
            );
        }
    }

    @IsTest
    private static void testOptionalSetSome() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            testSome(
                    OptionalV1.of(new Set<AsynchronousJob__c> {
                            new AsynchronousJob__c(Runnable__c = 'TEST1'),
                            new AsynchronousJob__c(Runnable__c = 'TEST2'),
                            new AsynchronousJob__c(Runnable__c = 'TEST3'),
                            new AsynchronousJob__c(Runnable__c = 'TEST1')
                    }),
                    OptionalV1.of(new Set<AsynchronousJob__c>{
                            new AsynchronousJob__c(Runnable__c = 'TEST4'),
                            new AsynchronousJob__c(Runnable__c = 'TEST5')
                    })
            );
        }
    }

    @IsTest
    private static void testOptionalCollectionSome() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            testSome(
                    OptionalV1.of(ImmutableV1.of(new Set<AsynchronousJob__c> {
                            new AsynchronousJob__c(Runnable__c = 'TEST1'),
                            new AsynchronousJob__c(Runnable__c = 'TEST2'),
                            new AsynchronousJob__c(Runnable__c = 'TEST3'),
                            new AsynchronousJob__c(Runnable__c = 'TEST1')
                    })),
                    OptionalV1.of(ImmutableV1.of(new Set<AsynchronousJob__c>{
                            new AsynchronousJob__c(Runnable__c = 'TEST4'),
                            new AsynchronousJob__c(Runnable__c = 'TEST5')
                    }))
            );
        }
    }

    private static void testSome(Object toTest1, Object toTest2) {
        System.runAs(TestHelper.getUser(TESTING)) {
            TestHelper.setNOW();
            Assert.isTrue(getMethods(toTest1).some(new FilterTestRunnable()));
            Assert.isFalse(getMethods(toTest2).some(new FilterTestRunnable()));
            Assert.isTrue(getMethods(toTest1).sharing('TEST2').some(new FilterTestRunnable()));
            Assert.isFalse(getMethods(toTest2).sharing('TEST2').some(new FilterTestRunnable()));
            Assert.isFalse(getMethods(toTest1).sharing('TEST4').some(new FilterTestRunnable()));
            Assert.isTrue(getMethods(toTest2).sharing('TEST4').some(new FilterTestRunnable()));

            try {
                Assert.isTrue(getMethods(toTest1).sharing(123).some(new FilterTestRunnable()));
                Assert.fail();
            } catch(ArrayV1.APIException ae) {
                Assert.areEqual('Callback must return a Boolean', ae.getMessage());
            }
        }
    }

    @IsTest
    private static void testListEvery() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            testEvery(
                    new List<AsynchronousJob__c> {
                            new AsynchronousJob__c(Runnable__c = 'TEST1'),
                            new AsynchronousJob__c(Runnable__c = 'TEST1')
                    },
                    new List<AsynchronousJob__c>{
                            new AsynchronousJob__c(Runnable__c = 'TEST1'),
                            new AsynchronousJob__c(Runnable__c = 'TEST2')
                    }
            );
        }
    }

    @IsTest
    private static void testSetEvery() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            testEvery(
                    new Set<AsynchronousJob__c> {
                            new AsynchronousJob__c(Runnable__c = 'TEST1'),
                            new AsynchronousJob__c(Runnable__c = 'TEST1')
                    },
                    new Set<AsynchronousJob__c>{
                            new AsynchronousJob__c(Runnable__c = 'TEST1'),
                            new AsynchronousJob__c(Runnable__c = 'TEST2')
                    }
            );
        }
    }

    @IsTest
    private static void testIterableEvery() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            testEvery(
                    new TestIterable(new List<AsynchronousJob__c> {
                            new AsynchronousJob__c(Runnable__c = 'TEST1'),
                            new AsynchronousJob__c(Runnable__c = 'TEST1')
                    }),
                    new TestIterable(new List<AsynchronousJob__c>{
                            new AsynchronousJob__c(Runnable__c = 'TEST1'),
                            new AsynchronousJob__c(Runnable__c = 'TEST2')
                    })
            );
        }
    }

    @IsTest
    private static void testOptionalListEvery() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            testEvery(
                    OptionalV1.of(new List<AsynchronousJob__c> {
                            new AsynchronousJob__c(Runnable__c = 'TEST1'),
                            new AsynchronousJob__c(Runnable__c = 'TEST1')
                    }),
                    OptionalV1.of(new List<AsynchronousJob__c>{
                            new AsynchronousJob__c(Runnable__c = 'TEST1'),
                            new AsynchronousJob__c(Runnable__c = 'TEST2')
                    })
            );
        }
    }

    @IsTest
    private static void testOptionalSetEvery() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            testEvery(
                    OptionalV1.of(new Set<AsynchronousJob__c> {
                            new AsynchronousJob__c(Runnable__c = 'TEST1'),
                            new AsynchronousJob__c(Runnable__c = 'TEST1')
                    }),
                    OptionalV1.of(new Set<AsynchronousJob__c>{
                            new AsynchronousJob__c(Runnable__c = 'TEST1'),
                            new AsynchronousJob__c(Runnable__c = 'TEST2')
                    })
            );
        }
    }

    @IsTest
    private static void testOptionalCollectionEvery() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            testEvery(
                    OptionalV1.of(ImmutableV1.of(new Set<AsynchronousJob__c> {
                            new AsynchronousJob__c(Runnable__c = 'TEST1'),
                            new AsynchronousJob__c(Runnable__c = 'TEST1')
                    })),
                    OptionalV1.of(ImmutableV1.of(new Set<AsynchronousJob__c>{
                            new AsynchronousJob__c(Runnable__c = 'TEST1'),
                            new AsynchronousJob__c(Runnable__c = 'TEST2')
                    }))
            );
        }
    }

    private static void testEvery(Object toTest1, Object toTest2) {
        Assert.isTrue(getMethods(toTest1).every(new FilterTestRunnable()));
        Assert.isFalse(getMethods(toTest2).every(new FilterTestRunnable()));

        try {
            Assert.isTrue(getMethods(toTest1).sharing(123).every(new FilterTestRunnable()));
            Assert.fail();
        } catch(ArrayV1.APIException ae) {
            Assert.areEqual('Callback must return a Boolean', ae.getMessage());
        }
    }

    @IsTest
    private static void testListReverse() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            testReverse(new List<String> { 'one', 'two', 'three' });
        }
    }

    @IsTest
    private static void testSetReverse() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            testReverse(new Set<String> { 'one', 'two', 'three' });
        }
    }

    @IsTest
    private static void testIterableReverse() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            testReverse(new TestIterable(new List<String> { 'one', 'two', 'three' }));
        }
    }

    @IsTest
    private static void testOptionalListReverse() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            testReverse(OptionalV1.of(new List<String> { 'one', 'two', 'three' }));
        }
    }

    @IsTest
    private static void testOptionalSetReverse() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            testReverse(OptionalV1.of(new Set<String> { 'one', 'two', 'three' }));
        }
    }

    @IsTest
    private static void testOptionalCollectionReverse() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            testReverse(OptionalV1.of(ImmutableV1.of(new Set<String> { 'one', 'two', 'three' })));
        }
    }

    private static void testReverse(Object toTest) {
        List<Object> reversed = getMethods(toTest).reverse();
        Assert.areEqual(3, reversed.size());
        Assert.areEqual('three', reversed[0]);
        Assert.areEqual('two', reversed[1]);
        Assert.areEqual('one', reversed[2]);
    }

    @IsTest
    private static void testListPushAndPop() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            testPushAndPop(new List<Integer>());
        }
    }

    @IsTest
    private static void testSetPushAndPop() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            testPushAndPop(new Set<Integer>());
        }
    }

    @IsTest
    private static void testIterablePushAndPop() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            testPushAndPop(new TestIterable(new List<Integer>()));
        }
    }

    @IsTest
    private static void testOptionalListPushAndPop() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            testPushAndPop(OptionalV1.of(new List<Integer>()));
        }
    }

    @IsTest
    private static void testOptionalSetPushAndPop() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            testPushAndPop(OptionalV1.of(new Set<Integer>()));
        }
    }

    @IsTest
    private static void testOptionalCollectionPushAndPop() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            testPushAndPop(OptionalV1.of(ImmutableV1.of(new Set<Integer>())));
        }
    }

    private static void testPushAndPop(Object toTest) {
        ArrayV1.Methods stack = getMethods(toTest);
        stack.push(1);
        Assert.areEqual(1, stack.length());
        stack.push(2);
        Assert.areEqual(2, stack.length());
        Assert.areEqual(2, stack.pop().get());
        Assert.areEqual(1, stack.length());
        stack.push(3);
        Assert.areEqual(2, stack.length());
        Assert.areEqual(3, stack.pop().get());
        Assert.areEqual(1, stack.length());
        Assert.areEqual(1, stack.pop().get());
        Assert.areEqual(0, stack.length());
        Assert.isFalse(stack.pop().isPresent());
    }

    @IsTest
    private static void testListPushAndShift() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            testPushAndShift(new List<Integer>());
        }
    }

    @IsTest
    private static void testSetPushAndShift() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            testPushAndShift(new Set<Integer>());
        }
    }

    @IsTest
    private static void testIterablePushAndShift() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            testPushAndShift(new TestIterable(new List<Integer>()));
        }
    }

    @IsTest
    private static void testOptionalListPushAndShift() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            testPushAndShift(OptionalV1.of(new List<Integer>()));
        }
    }

    @IsTest
    private static void testOptionalSetPushAndShift() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            testPushAndShift(OptionalV1.of(new Set<Integer>()));
        }
    }

    @IsTest
    private static void testOptionalCollectionPushAndShift() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            testPushAndShift(OptionalV1.of(ImmutableV1.of(new Set<Integer>())));
        }
    }

    private static void testPushAndShift(Object toTest) {
        ArrayV1.Methods fifo = getMethods(toTest);
        fifo.push(1);
        Assert.areEqual(1, fifo.length());
        fifo.push(2);
        Assert.areEqual(2, fifo.length());
        Assert.areEqual(1, fifo.shift().get());
        Assert.areEqual(1, fifo.length());
        fifo.push(3);
        Assert.areEqual(2, fifo.length());
        Assert.areEqual(2, fifo.shift().get());
        Assert.areEqual(1, fifo.length());
        Assert.areEqual(3, fifo.shift().get());
        Assert.areEqual(0, fifo.length());
        Assert.isFalse(fifo.shift().isPresent());
    }

    @IsTest
    private static void testListLength() {
        System.runAs(TestHelper.getUser(TESTING)) {
            TestHelper.setNOW();
            Assert.areEqual(0, getMethods(new List<Integer>()).length());
            Assert.areEqual(1, getMethods(new List<Integer> { 1 }).length());
        }
    }

    @IsTest
    private static void testSetLength() {
        System.runAs(TestHelper.getUser(TESTING)) {
            TestHelper.setNOW();
            Assert.areEqual(0, getMethods(new Set<Integer>()).length());
            Assert.areEqual(1, getMethods(new Set<Integer> { 1 }).length());
        }
    }

    @IsTest
    private static void testIterableLength() {
        System.runAs(TestHelper.getUser(TESTING)) {
            TestHelper.setNOW();
            Assert.areEqual(0, getMethods(new TestIterable(new List<Integer>())).length());
            Assert.areEqual(1, getMethods(new TestIterable(new List<Integer> { 1 })).length());
        }
    }

    @IsTest
    private static void testOptionalListLength() {
        System.runAs(TestHelper.getUser(TESTING)) {
            TestHelper.setNOW();
            Assert.areEqual(0, getMethods(OptionalV1.of(new List<Integer>())).length());
            Assert.areEqual(1, getMethods(OptionalV1.of(new List<Integer> { 1 })).length());
        }
    }

    @IsTest
    private static void testOptionalSetLength() {
        System.runAs(TestHelper.getUser(TESTING)) {
            TestHelper.setNOW();
            Assert.areEqual(0, getMethods(OptionalV1.of(new Set<Integer>())).length());
            Assert.areEqual(1, getMethods(OptionalV1.of(new Set<Integer> { 1 })).length());
        }
    }

    @IsTest
    private static void testOptionalCollectionLength() {
        System.runAs(TestHelper.getUser(TESTING)) {
            TestHelper.setNOW();
            Assert.areEqual(0, getMethods(OptionalV1.of(ImmutableV1.of(new Set<Integer>()))).length());
            Assert.areEqual(1, getMethods(OptionalV1.of(ImmutableV1.of(new Set<Integer> { 1 }))).length());
        }
    }

    @IsTest
    private static void testListSort() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            List<Integer> initial = new List<Integer> { 5, 2, 4, 3, 1 };
            testSort(initial, initial);
        }
    }

    @IsTest
    private static void testSetSort() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            List<Integer> initial = new List<Integer> { 5, 2, 4, 3, 1 };
            testSort(new Set<Integer>(initial), initial);
        }
    }

    @IsTest
    private static void testIterableSort() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            List<Integer> initial = new List<Integer> { 5, 2, 4, 3, 1 };
            testSort(new TestIterable(initial), initial);
        }
    }

    @IsTest
    private static void testOptionalListSort() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            List<Integer> initial = new List<Integer> { 5, 2, 4, 3, 1 };
            testSort(OptionalV1.of(initial), initial);
        }
    }

    @IsTest
    private static void testOptionalSetSort() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            List<Integer> initial = new List<Integer> { 5, 2, 4, 3, 1 };
            testSort(OptionalV1.of(new Set<Integer>(initial)), initial);
        }
    }

    @IsTest
    private static void testOptionalCollectionSort() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            List<Integer> initial = new List<Integer> { 5, 2, 4, 3, 1 };
            testSort(OptionalV1.of(ImmutableV1.of(new Set<Integer>(initial))), initial);
        }
    }

    private static void testSort(Object toTest, List<Integer> initial) {
        List<Object> sorted = getMethods(toTest).sort();
        Assert.areEqual(5, initial[0]);
        Assert.areEqual(1, sorted[0]);
        Assert.areEqual(2, initial[1]);
        Assert.areEqual(2, sorted[1]);
        Assert.areEqual(4, initial[2]);
        Assert.areEqual(3, sorted[2]);
        Assert.areEqual(3, initial[3]);
        Assert.areEqual(4, sorted[3]);
        Assert.areEqual(1, initial[4]);
        Assert.areEqual(5, sorted[4]);

        sorted = getMethods(toTest).sort(new ReverseComparator());
        Assert.areEqual(5, initial[0]);
        Assert.areEqual(5, sorted[0]);
        Assert.areEqual(2, initial[1]);
        Assert.areEqual(4, sorted[1]);
        Assert.areEqual(4, initial[2]);
        Assert.areEqual(3, sorted[2]);
        Assert.areEqual(3, initial[3]);
        Assert.areEqual(2, sorted[3]);
        Assert.areEqual(1, initial[4]);
        Assert.areEqual(1, sorted[4]);
    }

    private static ArrayV1.Methods getMethods(Object toTest) {
        if (toTest instanceof OptionalV1) {
            return ((OptionalV1) toTest).collection();
        } else if (toTest instanceof ImmutableV1.Collection) {
            return (ImmutableV1.Collection) toTest;
        } else {
            return ArrayV1.over(toTest);
        }
    }

    private with sharing class ForEachMultiplier extends ArrayV1.Callback {
        public override OptionalV1 function(Object element, OptionalV1 currentValue, Integer index) {
            ((List<Integer>) shared().get()).add(((Integer) element) * 2);
            return OptionalV1.empty();
        }
    }

    private with sharing class ReduceSubtractor extends ArrayV1.Callback {
        public override OptionalV1 function(Object element, OptionalV1 currentValue, Integer index) {
            return OptionalV1.of((Integer) currentValue.get() - (Integer) element);
        }
    }

    private with sharing class ObjectMerger extends ArrayV1.Callback {
        public override OptionalV1 function(Object element, OptionalV1 currentValue, Integer index) {
            Map<String, Object> mergeMap = (Map<String, Object>) currentValue.get();
            SObject record = (SObject) element;
            mergeMap.putAll(record.getPopulatedFieldsAsMap());
            return OptionalV1.of(mergeMap);
        }
    }

    private with sharing class ValueExtractor extends ArrayV1.Callback {
        public override OptionalV1 function(Object element, OptionalV1 currentValue, Integer index) {
            Map<String, Object> valueMap = (Map<String, Object>) currentValue.get();
            Map<String, Object> mergeMap = (Map<String, Object>) shared().get();
            SObjectField field = (SObjectField) element;
            valueMap.put(field.getDescribe().name, mergeMap.get(field.getDescribe().name));
            return OptionalV1.of(valueMap);
        }
    }

    private with sharing class FilterTestRunnable extends ArrayV1.Callback {
        public override OptionalV1 function(Object element, OptionalV1 currentValue, Integer index) {
            if (shared().isPresent() && ! (shared().get() instanceof String)) {
                return OptionalV1.of(shared().get());
            }

            return OptionalV1.of((!shared().isPresent())
                    ? ((AsynchronousJob__c) element).Runnable__c == 'TEST1'
                    : ((AsynchronousJob__c) element).Runnable__c == (String) shared().get());
        }
    }

    private with sharing class Transformer extends ArrayV1.Callback {
        public override OptionalV1 function(Object element, OptionalV1 currentValue, Integer index) {
            return OptionalV1.of(((AsynchronousJob__c) element).Runnable__c);
        }
    }

    private with sharing class ReverseComparator implements Comparator<Object> {
        public Integer compare(Object param1, Object param2) {
            return (Integer) param2 - (Integer) param1;
        }
    }

    private with sharing class TestIterable implements Iterable<Object> {
        private final List<Object> objects;

        public TestIterable(List<Object> objects) {
            this.objects = objects;
        }

        public Iterator<Object> iterator() {
            return objects.iterator();
        }
    }
}