/**
 * @description
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../../LICENSE target="_blank">MIT License</a>.
 * <br><br>
 * Unit tests for ArrayIterator class.
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
    private static void testConcatList() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            testConcat(new List<Integer>{ 1, 2, 3 });
        }
    }

    @IsTest
    private static void testConcatSet() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            testConcat(new Set<Integer>{ 1, 2, 3 });
        }
    }

    @IsTest
    private static void testConcatIterable() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            testConcat(new TestIterable(new List<Integer> { 1, 2, 3 }));
        }
    }

    private static void testConcat(Object toTest) {
        List<Object> result = ArrayV1.over(toTest).concat(new List<Integer>{ 4, 5 });
        Assert.areEqual(5, result.size());
        for (Integer index = 0; index < 5; index++) {
            Assert.areEqual(index + 1, result[index]);
        }
    }

    @IsTest
    private static void testForEachList() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            testForEach(new List<Integer> { 1, 2, 3, 4, 5 });
        }
    }

    @IsTest
    private static void testForEachSet() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            testForEach(new Set<Integer> { 1, 2, 3, 4, 5 });
        }
    }

    @IsTest
    private static void testForEachIterable() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            testForEach(new TestIterable(new List<Integer> { 1, 2, 3, 4, 5 }));
        }
    }

    private static void testForEach(Object toTest) {
        List<Integer> result = new List<Integer>();
        ArrayV1.over(toTest).sharing(result).forEach(new ForEachMultiplier());
        Assert.areEqual(5, result.size());
        Assert.areEqual(2, result[0]);
        Assert.areEqual(4, result[1]);
        Assert.areEqual(6, result[2]);
        Assert.areEqual(8, result[3]);
        Assert.areEqual(10, result[4]);
    }

    @IsTest
    private static void testReduceList() {
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
    private static void testReduceSet() {
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
    private static void testReduceIterable() {
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
    private static void testReduceRightList() {
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
    private static void testReduceRightSet() {
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
    private static void testReduceRightIterable() {
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
    private static void testFilterList() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            testFilter(new List<AsynchronousJob__c>{
                    new AsynchronousJob__c(Runnable__c = 'TEST1'),
                    new AsynchronousJob__c(Runnable__c = 'TEST2')
            });
        }
    }

    @IsTest
    private static void testFilterSet() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            testFilter(new Set<AsynchronousJob__c>{
                    new AsynchronousJob__c(Runnable__c = 'TEST1'),
                    new AsynchronousJob__c(Runnable__c = 'TEST2')
            });
        }
    }

    @IsTest
    private static void testFilterIterable() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            testFilter(new TestIterable(new List<AsynchronousJob__c>{
                    new AsynchronousJob__c(Runnable__c = 'TEST1'),
                    new AsynchronousJob__c(Runnable__c = 'TEST2')
            }));
        }
    }

    private static void testFilter(Object toTest) {
        List<Object> results = ArrayV1.over(toTest).filter(new FilterTestRunnable());
        Assert.areEqual(1, results.size());
        Assert.areEqual('TEST1', ((AsynchronousJob__c) results[0]).Runnable__c);

        results = ArrayV1.over(toTest).sharing('TEST2').filter(new FilterTestRunnable());
        Assert.areEqual(1, results.size());
        Assert.areEqual('TEST2', ((AsynchronousJob__c) results[0]).Runnable__c);

        try {
            results = ArrayV1.over(toTest).sharing(123).filter(new FilterTestRunnable());
            Assert.fail();

        } catch (ArrayV1.APIException ae) {
            Assert.areEqual('Callback must return a Boolean', ae.getMessage());
        }
    }

    @IsTest
    private static void testTransformList() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            testTransform(new List<AsynchronousJob__c>{
                    new AsynchronousJob__c(Runnable__c = 'TEST1'),
                    new AsynchronousJob__c(Runnable__c = 'TEST2')
            });
        }
    }

    @IsTest
    private static void testTransformSet() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            testTransform(new Set<AsynchronousJob__c>{
                    new AsynchronousJob__c(Runnable__c = 'TEST1'),
                    new AsynchronousJob__c(Runnable__c = 'TEST2')
            });
        }
    }

    @IsTest
    private static void testTransformIterable() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            testTransform(new TestIterable(new List<AsynchronousJob__c>{
                    new AsynchronousJob__c(Runnable__c = 'TEST1'),
                    new AsynchronousJob__c(Runnable__c = 'TEST2')
            }));
        }
    }

    private static void testTransform(Object toTest) {
        List<Object> results = (List<Object>) ArrayV1.over(toTest).transform(new Transformer());
        Assert.areEqual(2, results.size());
        Assert.areEqual('TEST1', results[0]);
        Assert.areEqual('TEST2', results[1]);

        List<String> stringResults = (List<String>) ArrayV1.over(toTest).transform(new Transformer(), new List<String>());
        Assert.areEqual(2, stringResults.size());
        Assert.areEqual('TEST1', stringResults[0]);
        Assert.areEqual('TEST2', stringResults[1]);
    }

    @IsTest
    private static void testAtList() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            testAt(new List<Integer> { 1, 2, 3, 4 });
        }
    }

    @IsTest
    private static void testAtSet() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            testAt(new Set<Integer> { 1, 2, 3, 4 });
        }
    }

    @IsTest
    private static void testAtIterable() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            testAt(new TestIterable(new List<Integer> { 1, 2, 3, 4 }));
        }
    }

    private static void testAt(Object toTest) {
        ArrayV1.Methods methods = ArrayV1.over(toTest);
        Assert.areEqual(1, methods.at(0).get());
        Assert.areEqual(4, methods.at(3).get());
        Assert.areEqual(3, methods.at(-2).get());
        Assert.areEqual(1, methods.at(-4).get());
        Assert.isFalse(methods.at(4).isPresent());
        Assert.isFalse(methods.at(-5).isPresent());
    }

    @IsTest
    private static void testJoinList() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            testJoin(new List<Integer> { 1, 2, 3, 4, 5 });
        }
    }

    @IsTest
    private static void testJoinSet() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            testJoin(new Set<Integer> { 1, 2, 3, 4, 5 });
        }
    }

    @IsTest
    private static void testJoinIterable() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            testJoin(new TestIterable(new List<Integer> { 1, 2, 3, 4, 5 }));
        }
    }

    private static void testJoin(Object toTest) {
        Assert.areEqual('1-2-3-4-5', ArrayV1.over(toTest).join('-'));
    }

    @IsTest
    private static void testSomeList() {
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
    private static void testSomeSet() {
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
    private static void testSomeIterable() {
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

    private static void testSome(Object toTest1, Object toTest2) {
        System.runAs(TestHelper.getUser(TESTING)) {
            TestHelper.setNOW();
            Assert.isTrue(ArrayV1.over(toTest1).some(new FilterTestRunnable()));
            Assert.isFalse(ArrayV1.over(toTest2).some(new FilterTestRunnable()));
            Assert.isTrue(ArrayV1.over(toTest1).sharing('TEST2').some(new FilterTestRunnable()));
            Assert.isFalse(ArrayV1.over(toTest2).sharing('TEST2').some(new FilterTestRunnable()));
            Assert.isFalse(ArrayV1.over(toTest1).sharing('TEST4').some(new FilterTestRunnable()));
            Assert.isTrue(ArrayV1.over(toTest2).sharing('TEST4').some(new FilterTestRunnable()));

            try {
                Assert.isTrue(ArrayV1.over(toTest1).sharing(123).some(new FilterTestRunnable()));
                Assert.fail();
            } catch(ArrayV1.APIException ae) {
                Assert.areEqual('Callback must return a Boolean', ae.getMessage());
            }
        }
    }

    @IsTest
    private static void testEveryList() {
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
    private static void testEverySet() {
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
    private static void testEveryIterable() {
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

    private static void testEvery(Object toTest1, Object toTest2) {
        Assert.isTrue(ArrayV1.over(toTest1).every(new FilterTestRunnable()));
        Assert.isFalse(ArrayV1.over(toTest2).every(new FilterTestRunnable()));

        try {
            Assert.isTrue(ArrayV1.over(toTest1).sharing(123).every(new FilterTestRunnable()));
            Assert.fail();
        } catch(ArrayV1.APIException ae) {
            Assert.areEqual('Callback must return a Boolean', ae.getMessage());
        }
    }

    @IsTest
    private static void testReverseList() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            testReverse(new List<String> { 'one', 'two', 'three' });
        }
    }

    @IsTest
    private static void testReverseSet() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            testReverse(new Set<String> { 'one', 'two', 'three' });
        }
    }

    @IsTest
    private static void testReverseIterable() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            testReverse(new TestIterable(new List<String> { 'one', 'two', 'three' }));
        }
    }

    private static void testReverse(Object toTest) {
        List<Object> reversed = ArrayV1.over(toTest).reverse();
        Assert.areEqual(3, reversed.size());
        Assert.areEqual('three', reversed[0]);
        Assert.areEqual('two', reversed[1]);
        Assert.areEqual('one', reversed[2]);
    }

    @IsTest
    private static void testPushAndPopList() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            testPushAndPop(new List<Integer>());
        }
    }

    @IsTest
    private static void testPushAndPopSet() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            testPushAndPop(new Set<Integer>());
        }
    }

    @IsTest
    private static void testPushAndPopIterable() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            testPushAndPop(new TestIterable(new List<Integer>()));
        }
    }

    private static void testPushAndPop(Object toTest) {
        ArrayV1.Methods stack = ArrayV1.over(toTest);
        stack.push(1);
        Assert.areEqual(1, stack.length());
        stack.push(2);
        Assert.areEqual(2, stack.length());
        Assert.areEqual(2, (Integer) stack.pop().get());
        Assert.areEqual(1, stack.length());
        stack.push(3);
        Assert.areEqual(2, stack.length());
        Assert.areEqual(3, (Integer) stack.pop().get());
        Assert.areEqual(1, stack.length());
        Assert.areEqual(1, (Integer) stack.pop().get());
        Assert.areEqual(0, stack.length());
        Assert.isFalse(stack.pop().isPresent());
    }

    @IsTest
    private static void testPushAndShiftList() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            testPushAndShift(new List<Integer>());
        }
    }

    @IsTest
    private static void testPushAndShiftSet() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            testPushAndShift(new Set<Integer>());
        }
    }

    @IsTest
    private static void testPushAndShiftIterable() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            testPushAndShift(new TestIterable(new List<Integer>()));
        }
    }

    private static void testPushAndShift(Object toTest) {
        ArrayV1.Methods fifo = ArrayV1.over(toTest);
        fifo.push(1);
        Assert.areEqual(1, fifo.length());
        fifo.push(2);
        Assert.areEqual(2, fifo.length());
        Assert.areEqual(1, (Integer) fifo.shift().get());
        Assert.areEqual(1, fifo.length());
        fifo.push(3);
        Assert.areEqual(2, fifo.length());
        Assert.areEqual(2, (Integer) fifo.shift().get());
        Assert.areEqual(1, fifo.length());
        Assert.areEqual(3, (Integer) fifo.shift().get());
        Assert.areEqual(0, fifo.length());
        Assert.isFalse(fifo.shift().isPresent());
    }

    @IsTest
    private static void testLengthList() {
        System.runAs(TestHelper.getUser(TESTING)) {
            TestHelper.setNOW();
            Assert.areEqual(0, ArrayV1.over(new List<Integer>()).length());
            Assert.areEqual(1, ArrayV1.over(new List<Integer> { 1 }).length());
        }
    }

    @IsTest
    private static void testLengthSet() {
        System.runAs(TestHelper.getUser(TESTING)) {
            TestHelper.setNOW();
            Assert.areEqual(0, ArrayV1.over(new Set<Integer>()).length());
            Assert.areEqual(1, ArrayV1.over(new Set<Integer> { 1 }).length());
        }
    }

    @IsTest
    private static void testLengthIterable() {
        System.runAs(TestHelper.getUser(TESTING)) {
            TestHelper.setNOW();
            Assert.areEqual(0, ArrayV1.over(new TestIterable(new List<Integer>())).length());
            Assert.areEqual(1, ArrayV1.over(new TestIterable(new List<Integer> { 1 })).length());
        }
    }

    @IsTest
    private static void testSortList() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            List<Integer> initial = new List<Integer> { 5, 2, 4, 3, 1 };
            testSort(initial, initial);
        }
    }

    @IsTest
    private static void testSortSet() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            List<Integer> initial = new List<Integer> { 5, 2, 4, 3, 1 };
            testSort(new Set<Integer>(initial), initial);
        }
    }

    @IsTest
    private static void testSortIterable() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
            List<Integer> initial = new List<Integer> { 5, 2, 4, 3, 1 };
            testSort(new TestIterable(initial), initial);
        }
    }

    private static void testSort(Object toTest, List<Integer> initial) {
        List<Object> sorted = ArrayV1.over(toTest).sort();
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

        sorted = ArrayV1.over(toTest).sort(new ReverseComparator());
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
        private List<Object> objects;

        public TestIterable(List<Object> objects) {
            this.objects = objects;
        }

        public Iterator<Object> iterator() {
            return objects.iterator();
        }
    }
}