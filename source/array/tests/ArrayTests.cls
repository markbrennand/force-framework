/**
 * @description
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../../LICENSE target="_blank">MIT License</a>.
 * <br><br>
 * Unit tests for ArrayIterator class.
 *
 * @author Mark Brennand
 */
@IsTest
public with sharing class ArrayTests {

    @IsTest
    private static void testConcatList() {
        List<Object> result = ArrayV1.over(new List<Integer>{ 1, 2, 3 }).concat(new List<Integer>{4, 5});
        Assert.areEqual(5, result.size());
        for (Integer index = 0; index < 5; index++) {
            Assert.areEqual(index + 1, result[index]);
        }
    }

    @IsTest
    private static void testConcatSet() {
        List<Object> result = ArrayV1.over(new Set<Integer>{ 1, 2, 3 }).concat(new List<Integer>{ 4, 5 });
        Assert.areEqual(5, result.size());
        for (Integer index = 0; index < 5; index++) {
            Assert.areEqual(index + 1, result[index]);
        }
    }

    @IsTest
    private static void testConcatIterable() {
        List<Object> result = ArrayV1.over(new TestIterable(new List<Integer> { 1, 2, 3 })).concat(new List<Integer> { 4, 5 });
        Assert.areEqual(5, result.size());
        for (Integer index = 0; index < 5; index++) {
            Assert.areEqual(index+1, result[index]);
        }
    }

    @IsTest
    private static void testForEachList() {
        List<Integer> result = new List<Integer>();
        ArrayV1.over(new List<Integer> { 1, 2, 3, 4, 5 }).sharing(result).forEach(new ForEachMultiplier());
        Assert.areEqual(5, result.size());
        Assert.areEqual(2, result[0]);
        Assert.areEqual(4, result[1]);
        Assert.areEqual(6, result[2]);
        Assert.areEqual(8, result[3]);
        Assert.areEqual(10, result[4]);
    }

    @IsTest
    private static void testForEachSet() {
        List<Integer> result = new List<Integer>();
        ArrayV1.over(new Set<Integer> { 1, 2, 3, 4, 5 }).sharing(result).forEach(new ForEachMultiplier());
        Assert.areEqual(5, result.size());
        Assert.areEqual(2, result[0]);
        Assert.areEqual(4, result[1]);
        Assert.areEqual(6, result[2]);
        Assert.areEqual(8, result[3]);
        Assert.areEqual(10, result[4]);
    }

    @IsTest
    private static void testForEachIterable() {
        List<Integer> result = new List<Integer>();
        ArrayV1.over(new TestIterable(new List<Integer> { 1, 2, 3, 4, 5 })).sharing(result).forEach(new ForEachMultiplier());
        Assert.areEqual(5, result.size());
        Assert.areEqual(2, result[0]);
        Assert.areEqual(4, result[1]);
        Assert.areEqual(6, result[2]);
        Assert.areEqual(8, result[3]);
        Assert.areEqual(10, result[4]);
    }

    @IsTest
    private static void testReduceList() {
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

    @IsTest
    private static void testReduceSet() {
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

    @IsTest
    private static void testReduceIterable() {
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

    @IsTest
    private static void testReduceRightList() {
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

    @IsTest
    private static void testReduceRightSet() {
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

    @IsTest
    private static void testReduceRightIterable() {
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

    @IsTest
    private static void testFilterList() {
        List<AsynchronousJob__c> results = (List<AsynchronousJob__c>) ArrayV1.over(new List<AsynchronousJob__c>{
                        new AsynchronousJob__c(Runnable__c = 'TEST1'),
                        new AsynchronousJob__c(Runnable__c = 'TEST2')
                })
                .filter(new FilterTestRunnable());

        Assert.areEqual(1, results.size());
        Assert.areEqual('TEST1', results[0].Runnable__c);

        results = (List<AsynchronousJob__c>) ArrayV1.over(new List<AsynchronousJob__c>{
                        new AsynchronousJob__c(
                                Runnable__c = 'TEST1'
                        ),
                        new AsynchronousJob__c(
                                Runnable__c = 'TEST2'
                        )
                })
                .sharing('TEST2')
                .filter(new FilterTestRunnable());

        Assert.areEqual(1, results.size());
        Assert.areEqual('TEST2', results[0].Runnable__c);

        try {
            results = (List<AsynchronousJob__c>) ArrayV1.over(new List<AsynchronousJob__c>{
                            new AsynchronousJob__c(Runnable__c = 'TEST1'),
                            new AsynchronousJob__c(Runnable__c = 'TEST2')
                    })
                    .sharing(123)
                    .filter(new FilterTestRunnable());

            Assert.fail();

        } catch(ArrayV1.APIException ae) {
            Assert.areEqual('Callback for filter() must return a Boolean', ae.getMessage());
        }
    }

    @IsTest
    private static void testFilterSet() {
        List<Object> results = ArrayV1.over(new Set<AsynchronousJob__c>{
                        new AsynchronousJob__c(Runnable__c = 'TEST1'),
                        new AsynchronousJob__c(Runnable__c = 'TEST2')
                })
                .filter(new FilterTestRunnable());

        Assert.areEqual(1, results.size());
        Assert.areEqual('TEST1', ((AsynchronousJob__c) results[0]).Runnable__c);

        results = ArrayV1.over(new Set<AsynchronousJob__c>{
                        new AsynchronousJob__c(Runnable__c = 'TEST1'),
                        new AsynchronousJob__c(Runnable__c = 'TEST2')
                })
                .sharing('TEST2')
                .filter(new FilterTestRunnable());

        Assert.areEqual(1, results.size());
        Assert.areEqual('TEST2', ((AsynchronousJob__c) results[0]).Runnable__c);

        try {
            results = ArrayV1.over(new Set<AsynchronousJob__c>{
                            new AsynchronousJob__c(Runnable__c = 'TEST1'),
                            new AsynchronousJob__c(Runnable__c = 'TEST2')
                    })
                    .sharing(123)
                    .filter(new FilterTestRunnable());

            Assert.fail();

        } catch(ArrayV1.APIException ae) {
            Assert.areEqual('Callback for filter() must return a Boolean', ae.getMessage());
        }
    }

    @IsTest
    private static void testFilterIterable() {
        List<Object> results = ArrayV1.over(new TestIterable(new List<AsynchronousJob__c>{
                        new AsynchronousJob__c( Runnable__c = 'TEST1' ),
                        new AsynchronousJob__c(Runnable__c = 'TEST2')
                }))
                .filter(new FilterTestRunnable());

        Assert.areEqual(1, results.size());
        Assert.areEqual('TEST1', ((AsynchronousJob__c) results[0]).Runnable__c);

        results = ArrayV1.over(new TestIterable(new List<AsynchronousJob__c>{
                        new AsynchronousJob__c(Runnable__c = 'TEST1'),
                        new AsynchronousJob__c(Runnable__c = 'TEST2')
                }))
                .sharing('TEST2')
                .filter(new FilterTestRunnable());

        Assert.areEqual(1, results.size());
        Assert.areEqual('TEST2', ((AsynchronousJob__c) results[0]).Runnable__c);

        try {
            results = ArrayV1.over(new TestIterable(new List<AsynchronousJob__c>{
                            new AsynchronousJob__c(Runnable__c = 'TEST1'),
                            new AsynchronousJob__c(Runnable__c = 'TEST2')
                    }))
                    .sharing(123)
                    .filter(new FilterTestRunnable());

            Assert.fail();

        } catch(ArrayV1.APIException ae) {
            Assert.areEqual('Callback for filter() must return a Boolean', ae.getMessage());
        }
    }

    @IsTest
    private static void testTransformList() {
        List<AsynchronousJob__c> results = (List<AsynchronousJob__c>) ArrayV1.over(new List<AsynchronousJob__c>{
                        new AsynchronousJob__c(Runnable__c = 'TEST1'),
                        new AsynchronousJob__c(Runnable__c = 'TEST2')
                })
                .transform(new Transformer());

        Assert.areEqual(2, results.size());
        Assert.areEqual('TEST1', results[0].Runnable__c);
        Assert.areEqual(1000, results[0].RetryInterval__c);
        Assert.areEqual('TEST2', results[1].Runnable__c);
        Assert.areEqual(1000, results[1].RetryInterval__c);

        results = (List<AsynchronousJob__c>) ArrayV1.over(new List<AsynchronousJob__c>{
                        new AsynchronousJob__c(Runnable__c = 'TEST1'),
                        new AsynchronousJob__c(Runnable__c = 'TEST2')
                })
                .sharing(5000)
                .transform(new Transformer());

        Assert.areEqual(2, results.size());
        Assert.areEqual('TEST1', results[0].Runnable__c);
        Assert.areEqual(5000, results[0].RetryInterval__c);
        Assert.areEqual('TEST2', results[1].Runnable__c);
        Assert.areEqual(5000, results[1].RetryInterval__c);
    }

    @IsTest
    private static void testTransformSet() {
        List<Object> results = ArrayV1.over(new Set<AsynchronousJob__c>{
                        new AsynchronousJob__c(Runnable__c = 'TEST1'),
                        new AsynchronousJob__c(Runnable__c = 'TEST2')
                })
                .transform(new Transformer());

        Assert.areEqual(2, results.size());
        Assert.areEqual('TEST1', ((AsynchronousJob__c) results[0]).Runnable__c);
        Assert.areEqual(1000, ((AsynchronousJob__c) results[0]).RetryInterval__c);
        Assert.areEqual('TEST2', ((AsynchronousJob__c) results[1]).Runnable__c);
        Assert.areEqual(1000, ((AsynchronousJob__c) results[1]).RetryInterval__c);

        results = ArrayV1.over(new Set<AsynchronousJob__c>{
                        new AsynchronousJob__c(Runnable__c = 'TEST1'),
                        new AsynchronousJob__c(Runnable__c = 'TEST2')
                })
                .sharing(5000)
                .transform(new Transformer());

        Assert.areEqual(2, results.size());
        Assert.areEqual('TEST1', ((AsynchronousJob__c) results[0]).Runnable__c);
        Assert.areEqual(5000, ((AsynchronousJob__c) results[0]).RetryInterval__c);
        Assert.areEqual('TEST2', ((AsynchronousJob__c) results[1]).Runnable__c);
        Assert.areEqual(5000, ((AsynchronousJob__c) results[1]).RetryInterval__c);
    }

    @IsTest
    private static void testTransformIterable() {
        List<Object> results = ArrayV1.over(new TestIterable(new List<AsynchronousJob__c>{
                        new AsynchronousJob__c(Runnable__c = 'TEST1'),
                        new AsynchronousJob__c(Runnable__c = 'TEST2')
                }))
                .transform(new Transformer());

        Assert.areEqual(2, results.size());
        Assert.areEqual('TEST1', ((AsynchronousJob__c) results[0]).Runnable__c);
        Assert.areEqual(1000, ((AsynchronousJob__c) results[0]).RetryInterval__c);
        Assert.areEqual('TEST2', ((AsynchronousJob__c) results[1]).Runnable__c);
        Assert.areEqual(1000, ((AsynchronousJob__c) results[1]).RetryInterval__c);

        results = ArrayV1.over(new TestIterable(new List<AsynchronousJob__c>{
                        new AsynchronousJob__c(Runnable__c = 'TEST1'),
                        new AsynchronousJob__c(Runnable__c = 'TEST2')
                }))
                .sharing(5000)
                .transform(new Transformer());

        Assert.areEqual(2, results.size());
        Assert.areEqual('TEST1', ((AsynchronousJob__c) results[0]).Runnable__c);
        Assert.areEqual(5000, ((AsynchronousJob__c) results[0]).RetryInterval__c);
        Assert.areEqual('TEST2', ((AsynchronousJob__c) results[1]).Runnable__c);
        Assert.areEqual(5000, ((AsynchronousJob__c) results[1]).RetryInterval__c);
    }

    @IsTest
    private static void testAtList() {
        ArrayV1.Methods methods = ArrayV1.over(new List<Integer> { 1, 2, 3, 4 });

        Assert.areEqual(1, methods.at(0).get());
        Assert.areEqual(4, methods.at(3).get());
        Assert.areEqual(3, methods.at(-2).get());
        Assert.areEqual(1, methods.at(-4).get());
        Assert.isFalse(methods.at(4).isPresent());
        Assert.isFalse(methods.at(-5).isPresent());
    }

    @IsTest
    private static void testAtSet() {
        ArrayV1.Methods methods = ArrayV1.over(new Set<Integer> { 1, 2, 3, 4 });

        Assert.areEqual(1, methods.at(0).get());
        Assert.areEqual(4, methods.at(3).get());
        Assert.areEqual(3, methods.at(-2).get());
        Assert.areEqual(1, methods.at(-4).get());
        Assert.isFalse(methods.at(4).isPresent());
        Assert.isFalse(methods.at(-5).isPresent());
    }

    @IsTest
    private static void testAtIterable() {
        ArrayV1.Methods methods = ArrayV1.over(new TestIterable(new List<Integer> { 1, 2, 3, 4 }));

        Assert.areEqual(1, methods.at(0).get());
        Assert.areEqual(4, methods.at(3).get());
        Assert.areEqual(3, methods.at(-2).get());
        Assert.areEqual(1, methods.at(-4).get());
        Assert.isFalse(methods.at(4).isPresent());
        Assert.isFalse(methods.at(-5).isPresent());
    }

    @IsTest
    private static void testJoinList() {
        Assert.areEqual('1-2-3-4-5', ArrayV1.over(new List<Integer> { 1, 2, 3, 4, 5 }).join('-'));
    }

    @IsTest
    private static void testJoinSet() {
        Assert.areEqual('1-2-3-4-5', ArrayV1.over(new Set<Integer> { 1, 2, 3, 4, 5 }).join('-'));
    }

    @IsTest
    private static void testJoinIterable() {
        Assert.areEqual('1-2-3-4-5', ArrayV1.over(new TestIterable(new List<Integer> { 1, 2, 3, 4, 5 })).join('-'));
    }

    @IsTest
    private static void testSomeList() {
        List<AsynchronousJob__c> jobs1 = new List<AsynchronousJob__c> {
                new AsynchronousJob__c(Runnable__c = 'TEST1'),
                new AsynchronousJob__c(Runnable__c = 'TEST2'),
                new AsynchronousJob__c(Runnable__c = 'TEST3'),
                new AsynchronousJob__c(Runnable__c = 'TEST1')
        };

        List<AsynchronousJob__c> jobs2 = new List<AsynchronousJob__c>{
                new AsynchronousJob__c(Runnable__c = 'TEST4'),
                new AsynchronousJob__c(Runnable__c = 'TEST5')
        };

        Assert.isTrue(ArrayV1.over(jobs1).some(new FilterTestRunnable()));
        Assert.isFalse(ArrayV1.over(jobs2).some(new FilterTestRunnable()));
        Assert.isTrue(ArrayV1.over(jobs1).sharing('TEST2').some(new FilterTestRunnable()));
        Assert.isFalse(ArrayV1.over(jobs2).sharing('TEST2').some(new FilterTestRunnable()));
        Assert.isFalse(ArrayV1.over(jobs1).sharing('TEST4').some(new FilterTestRunnable()));
        Assert.isTrue(ArrayV1.over(jobs2).sharing('TEST4').some(new FilterTestRunnable()));

        try {
            Assert.isTrue(ArrayV1.over(jobs1).sharing(123).some(new FilterTestRunnable()));
            Assert.fail();
        } catch(ArrayV1.APIException ae) {
            Assert.areEqual('Callback for some() must return a Boolean', ae.getMessage());
        }
    }

    @IsTest
    private static void testSomeSet() {
        Set<AsynchronousJob__c> jobs1 = new Set<AsynchronousJob__c> {
                new AsynchronousJob__c(Runnable__c = 'TEST1'),
                new AsynchronousJob__c(Runnable__c = 'TEST2'),
                new AsynchronousJob__c(Runnable__c = 'TEST3'),
                new AsynchronousJob__c(Runnable__c = 'TEST1')
        };

        Set<AsynchronousJob__c> jobs2 = new Set<AsynchronousJob__c>{
                new AsynchronousJob__c(Runnable__c = 'TEST4'),
                new AsynchronousJob__c(Runnable__c = 'TEST5')
        };

        Assert.isTrue(ArrayV1.over(jobs1).some(new FilterTestRunnable()));
        Assert.isFalse(ArrayV1.over(jobs2).some(new FilterTestRunnable()));
        Assert.isTrue(ArrayV1.over(jobs1).sharing('TEST2').some(new FilterTestRunnable()));
        Assert.isFalse(ArrayV1.over(jobs2).sharing('TEST2').some(new FilterTestRunnable()));
        Assert.isFalse(ArrayV1.over(jobs1).sharing('TEST4').some(new FilterTestRunnable()));
        Assert.isTrue(ArrayV1.over(jobs2).sharing('TEST4').some(new FilterTestRunnable()));

        try {
            Assert.isTrue(ArrayV1.over(jobs1).sharing(123).some(new FilterTestRunnable()));
            Assert.fail();
        } catch(ArrayV1.APIException ae) {
            Assert.areEqual('Callback for some() must return a Boolean', ae.getMessage());
        }
    }

    @IsTest
    private static void testIterable() {
        TestIterable iter1 = new TestIterable(new List<AsynchronousJob__c> {
                new AsynchronousJob__c(Runnable__c = 'TEST1'),
                new AsynchronousJob__c(Runnable__c = 'TEST2'),
                new AsynchronousJob__c(Runnable__c = 'TEST3'),
                new AsynchronousJob__c(Runnable__c = 'TEST1')
        });

        TestIterable iter2 = new TestIterable(new List<AsynchronousJob__c>{
                new AsynchronousJob__c(Runnable__c = 'TEST4'),
                new AsynchronousJob__c(Runnable__c = 'TEST5')
        });

        Assert.isTrue(ArrayV1.over(iter1).some(new FilterTestRunnable()));
        Assert.isFalse(ArrayV1.over(iter2).some(new FilterTestRunnable()));
        Assert.isTrue(ArrayV1.over(iter1).sharing('TEST2').some(new FilterTestRunnable()));
        Assert.isFalse(ArrayV1.over(iter2).sharing('TEST2').some(new FilterTestRunnable()));
        Assert.isFalse(ArrayV1.over(iter1).sharing('TEST4').some(new FilterTestRunnable()));
        Assert.isTrue(ArrayV1.over(iter2).sharing('TEST4').some(new FilterTestRunnable()));

        try {
            Assert.isTrue(ArrayV1.over(iter1).sharing(123).some(new FilterTestRunnable()));
            Assert.fail();
        } catch(ArrayV1.APIException ae) {
            Assert.areEqual('Callback for some() must return a Boolean', ae.getMessage());
        }
    }

    @IsTest
    private static void testEveryList() {
        List<AsynchronousJob__c> jobs1 = new List<AsynchronousJob__c> {
                new AsynchronousJob__c(Runnable__c = 'TEST1'),
                new AsynchronousJob__c(Runnable__c = 'TEST1')
        };

        List<AsynchronousJob__c> jobs2 = new List<AsynchronousJob__c>{
                new AsynchronousJob__c(Runnable__c = 'TEST1'),
                new AsynchronousJob__c(Runnable__c = 'TEST2')
        };

        Assert.isTrue(ArrayV1.over(jobs1).every(new FilterTestRunnable()));
        Assert.isFalse(ArrayV1.over(jobs2).every(new FilterTestRunnable()));

        try {
            Assert.isTrue(ArrayV1.over(jobs1).sharing(123).every(new FilterTestRunnable()));
            Assert.fail();
        } catch(ArrayV1.APIException ae) {
            Assert.areEqual('Callback for every() must return a Boolean', ae.getMessage());
        }
    }

    @IsTest
    private static void testEverySet() {
        Set<AsynchronousJob__c> jobs1 = new Set<AsynchronousJob__c> {
                new AsynchronousJob__c(Runnable__c = 'TEST1'),
                new AsynchronousJob__c(Runnable__c = 'TEST1')
        };

        Set<AsynchronousJob__c> jobs2 = new Set<AsynchronousJob__c>{
                new AsynchronousJob__c(Runnable__c = 'TEST1'),
                new AsynchronousJob__c(Runnable__c = 'TEST2')
        };

        Assert.isTrue(ArrayV1.over(jobs1).every(new FilterTestRunnable()));
        Assert.isFalse(ArrayV1.over(jobs2).every(new FilterTestRunnable()));

        try {
            Assert.isTrue(ArrayV1.over(jobs1).sharing(123).every(new FilterTestRunnable()));
            Assert.fail();
        } catch(ArrayV1.APIException ae) {
            Assert.areEqual('Callback for every() must return a Boolean', ae.getMessage());
        }
    }

    @IsTest
    private static void testEveryIterable() {
        TestIterable iter1 = new TestIterable(new List<AsynchronousJob__c> {
                new AsynchronousJob__c(Runnable__c = 'TEST1'),
                new AsynchronousJob__c(Runnable__c = 'TEST1')
        });

        TestIterable iter2 = new TestIterable(new List<AsynchronousJob__c>{
                new AsynchronousJob__c(Runnable__c = 'TEST1'),
                new AsynchronousJob__c(Runnable__c = 'TEST2')
        });

        Assert.isTrue(ArrayV1.over(iter1).every(new FilterTestRunnable()));
        Assert.isFalse(ArrayV1.over(iter2).every(new FilterTestRunnable()));

        try {
            Assert.isTrue(ArrayV1.over(iter1).sharing(123).every(new FilterTestRunnable()));
            Assert.fail();
        } catch(ArrayV1.APIException ae) {
            Assert.areEqual('Callback for every() must return a Boolean', ae.getMessage());
        }
    }

    @IsTest
    private static void testReverseList() {
        List<String> reversed = (List<String>) ArrayV1.over(new List<String> { 'one', 'two', 'three' }).reverse();
        Assert.areEqual(3, reversed.size());
        Assert.areEqual('three', reversed[0]);
        Assert.areEqual('two', reversed[1]);
        Assert.areEqual('one', reversed[2]);
    }

    @IsTest
    private static void testReverseSet() {
        List<Object> reversed = ArrayV1.over(new Set<String> { 'one', 'two', 'three' }).reverse();
        Assert.areEqual(3, reversed.size());
        Assert.areEqual('three', reversed[0]);
        Assert.areEqual('two', reversed[1]);
        Assert.areEqual('one', reversed[2]);
    }

    @IsTest
    private static void testReverseIterable() {
        List<Object> reversed = ArrayV1.over(new TestIterable(new List<String> { 'one', 'two', 'three' })).reverse();
        Assert.areEqual(3, reversed.size());
        Assert.areEqual('three', reversed[0]);
        Assert.areEqual('two', reversed[1]);
        Assert.areEqual('one', reversed[2]);
    }

    @IsTest
    private static void testPushAndPopList() {
        ArrayV1.Methods stack = ArrayV1.over(new List<Integer>());
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
    private static void testPushAndPopSet() {
        ArrayV1.Methods stack = ArrayV1.over(new Set<Integer>());
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
    private static void testPushAndPopIterable() {
        ArrayV1.Methods stack = ArrayV1.over(new TestIterable(new List<Integer>()));
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
        ArrayV1.Methods fifo = ArrayV1.over(new List<Integer>());
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
    private static void testPushAndShiftSet() {
        ArrayV1.Methods fifo = ArrayV1.over(new Set<Integer>());
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
    private static void testPushAndShiftIterable() {
        ArrayV1.Methods fifo = ArrayV1.over(new TestIterable(new List<Integer>()));
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
        Assert.areEqual(0, ArrayV1.over(new List<Integer>()).length());
        Assert.areEqual(1, ArrayV1.over(new List<Integer> { 1 }).length());
    }

    @IsTest
    private static void testLengthSet() {
        Assert.areEqual(0, ArrayV1.over(new Set<Integer>()).length());
        Assert.areEqual(1, ArrayV1.over(new Set<Integer> { 1 }).length());
    }

    @IsTest
    private static void testLengthIterable() {
        Assert.areEqual(0, ArrayV1.over(new TestIterable(new List<Integer>())).length());
        Assert.areEqual(1, ArrayV1.over(new TestIterable(new List<Integer> { 1 })).length());
    }

    @IsTest
    private static void testSortList() {
        List<Integer> initial = new List<Integer> { 5, 2, 4, 3, 1 };
        List<Integer> sorted = (List<Integer>) ArrayV1.over(initial).sort();
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

        sorted = (List<Integer>) ArrayV1.over(initial).sort(new ReverseComparator());
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

    @IsTest
    private static void testSortSet() {
        List<Object> initial = new List<Integer> { 5, 2, 4, 3, 1 };
        List<Object> sorted = ArrayV1.over(new Set<Object>(initial)).sort();
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

        sorted = ArrayV1.over(new Set<Object>(initial)).sort(new ReverseComparator());
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

    @IsTest
    private static void testSortIterable() {
        List<Integer> initial = new List<Integer> { 5, 2, 4, 3, 1 };
        TestIterable iter = new TestIterable(initial);
        List<Object> sorted = ArrayV1.over(iter).sort();
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

        sorted = ArrayV1.over(iter).sort(new ReverseComparator());
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
            AsynchronousJob__c cloned = ((AsynchronousJob__c) element).clone();
            cloned.RetryInterval__c = shared().isPresent() ?  (Integer) shared().get() : 1000;
            return OptionalV1.of(cloned);
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