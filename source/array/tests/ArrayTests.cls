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
    private static void testConcat() {
        List<Integer> result = (List<Integer>) ArrayV1.over(new List<Integer> { 1, 2, 3 }).concat(new List<Integer> { 4, 5 });
        Assert.areEqual(5, result.size());
        for (Integer index = 0; index < 5; index++) {
            Assert.areEqual(index+1, result[index]);
        }
    }

    @IsTest
    private static void testForEach() {
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
    private static void testReduce() {
        Assert.areEqual(-13, ArrayV1.over(new List<Integer>{
                1, 2, 3, 4, 5
        }).reduce(new ReduceSubtractor()));

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
    private static void testReduceRight() {
        Assert.areEqual(-5, ArrayV1.over(new List<Integer>{
                1, 2, 3, 4, 5
        }).reduceRight(new ReduceSubtractor()));

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
    private static void testFilter() {
        List<AsynchronousJob__c> results = (List<AsynchronousJob__c>) ArrayV1.over(new List<AsynchronousJob__c>{
                        new AsynchronousJob__c(
                                Runnable__c = 'TEST1'
                        ),
                        new AsynchronousJob__c(
                                Runnable__c = 'TEST2'
                        )
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
                            new AsynchronousJob__c(
                                    Runnable__c = 'TEST1'
                            ),
                            new AsynchronousJob__c(
                                    Runnable__c = 'TEST2'
                            )
                    })
                    .sharing(123)
                    .filter(new FilterTestRunnable());

            Assert.fail();

        } catch(ArrayV1.APIException ae) {
            Assert.areEqual('Callback for filter() must return a Boolean', ae.getMessage());
        }
    }

    @IsTest
    private static void testTransform() {
        List<AsynchronousJob__c> results = (List<AsynchronousJob__c>) ArrayV1.over(new List<AsynchronousJob__c>{
                        new AsynchronousJob__c(
                                Runnable__c = 'TEST1'
                        ),
                        new AsynchronousJob__c(
                                Runnable__c = 'TEST2'
                        )
                })
                .transform(new Transformer());

        Assert.areEqual(2, results.size());
        Assert.areEqual('TEST1', results[0].Runnable__c);
        Assert.areEqual(1000, results[0].RetryInterval__c);
        Assert.areEqual('TEST2', results[1].Runnable__c);
        Assert.areEqual(1000, results[1].RetryInterval__c);

        results = (List<AsynchronousJob__c>) ArrayV1.over(new List<AsynchronousJob__c>{
                        new AsynchronousJob__c(
                                Runnable__c = 'TEST1'
                        ),
                        new AsynchronousJob__c(
                                Runnable__c = 'TEST2'
                        )
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
    private static void testAt() {
        ArrayV1.Methods methods = ArrayV1.over(new List<Integer> { 1, 2, 3, 4 });

        Assert.areEqual(1, methods.at(0).get());
        Assert.areEqual(4, methods.at(3).get());
        Assert.areEqual(3, methods.at(-2).get());
        Assert.areEqual(1, methods.at(-4).get());
        Assert.isFalse(methods.at(4).isPresent());
        Assert.isFalse(methods.at(-5).isPresent());
    }

    @IsTest
    private static void testJoin() {
        Assert.areEqual('1-2-3-4-5', ArrayV1.over(new List<Integer> { 1, 2, 3, 4, 5 }).join('-'));
    }

    @IsTest
    private static void testSome() {
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
    private static void testEvery() {
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
    private static void testReverse() {
        List<String> reversed = (List<String>) ArrayV1.over(new List<String> { 'one', 'two', 'three' }).reverse();
        Assert.areEqual(3, reversed.size());
        Assert.areEqual('three', reversed[0]);
        Assert.areEqual('two', reversed[1]);
        Assert.areEqual('one', reversed[2]);
    }

    @IsTest
    private static void testPushAndPop() {
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
    private static void testPushAndShift() {
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
    private static void testLength() {
        Assert.areEqual(0, ArrayV1.over(new List<Integer>()).length());
        Assert.areEqual(1, ArrayV1.over(new List<Integer> { 1 }).length());
    }

    private with sharing class ForEachMultiplier extends ArrayV1.Callback {
        public override Optional function(Object element, Optional currentValue, Integer index) {
            ((List<Integer>) shared().get()).add(((Integer) element) * 2);
            return Optional.empty();
        }
    }

    private with sharing class ReduceSubtractor extends ArrayV1.Callback {
        public override Optional function(Object element, Optional currentValue, Integer index) {
            return Optional.of((Integer) currentValue.get() - (Integer) element);
        }
    }

    private with sharing class ObjectMerger extends ArrayV1.Callback {
        public override Optional function(Object element, Optional currentValue, Integer index) {
            Map<String, Object> mergeMap = (Map<String, Object>) currentValue.get();
            SObject record = (SObject) element;
            mergeMap.putAll(record.getPopulatedFieldsAsMap());
            return Optional.of(mergeMap);
        }
    }

    private with sharing class ValueExtractor extends ArrayV1.Callback {
        public override Optional function(Object element, Optional currentValue, Integer index) {
            Map<String, Object> valueMap = (Map<String, Object>) currentValue.get();
            Map<String, Object> mergeMap = (Map<String, Object>) shared().get();
            SObjectField field = (SObjectField) element;
            valueMap.put(field.getDescribe().name, mergeMap.get(field.getDescribe().name));
            return Optional.of(valueMap);
        }
    }

    private with sharing class FilterTestRunnable extends ArrayV1.Callback {
        public override Optional function(Object element, Optional currentValue, Integer index) {
            if (shared().isPresent() && ! (shared().get() instanceof String)) {
                return Optional.of(shared().get());
            }

            return Optional.of((!shared().isPresent())
                    ? ((AsynchronousJob__c) element).Runnable__c == 'TEST1'
                    : ((AsynchronousJob__c) element).Runnable__c == (String) shared().get());
        }
    }

    private with sharing class Transformer extends ArrayV1.Callback {
        public override Optional function(Object element, Optional currentValue, Integer index) {
            AsynchronousJob__c cloned = ((AsynchronousJob__c) element).clone();
            cloned.RetryInterval__c = shared().isPresent() ?  (Integer) shared().get() : 1000;
            return Optional.of(cloned);
        }
    }
}