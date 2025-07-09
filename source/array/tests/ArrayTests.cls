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
        Assert.areEqual(120, ArrayV1.over(new List<Integer>{
                1, 2, 3, 4, 5
        }).reduce(new ReduceMultiplier()));
        Map<String, Object> merged = (Map<String, Object>) ArrayV1.over(new List<AsynchronousJob__c>{
                        new AsynchronousJob__c(
                                Runnable__c = 'TEST',
                                RetryInterval__c = 1000
                        ),
                        new AsynchronousJob__c(
                                RetryNumber__c = 0,
                                MaximumRetries__c = 100
                        )
                })
                .reduce(new ObjectMerger(), new Map<String, Object>());

        Assert.areEqual(100, merged.get(AsynchronousJob__c.MaximumRetries__c.getDescribe().name));
        Assert.areEqual(1000, merged.get(AsynchronousJob__c.RetryInterval__c.getDescribe().name));
        Assert.areEqual(0, merged.get(AsynchronousJob__c.RetryNumber__c.getDescribe().name));
        Assert.areEqual('TEST', merged.get(AsynchronousJob__c.Runnable__c.getDescribe().name));

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

        Assert.areEqual(1, methods.at(0));
        Assert.areEqual(4, methods.at(3));
        Assert.areEqual(3, methods.at(-2));
        Assert.areEqual(1, methods.at(-4));

        try {
            methods.at(4);
            Assert.fail();
        } catch(ArrayV1.APIException ae) {
            Assert.areEqual('Array index out of bounds', ae.getMessage());
        }

        try {
            methods.at(-5);
            Assert.fail();
        } catch(ArrayV1.APIException ae) {
            Assert.areEqual('Array index out of bounds', ae.getMessage());
        }
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

    private with sharing class ForEachMultiplier extends ArrayV1.Callback {
        public override Object function(Object element, Object currentValue, Integer index) {
            ((List<Integer>) shared()).add(((Integer) element) * 2);
            return null;
        }
    }

    private with sharing class ReduceMultiplier extends ArrayV1.Callback {
        public override Object function(Object element, Object currentValue, Integer index) {
            return (Integer) element * (Integer) currentValue;
        }
    }

    private with sharing class ObjectMerger extends ArrayV1.Callback {
        public override Object function(Object element, Object currentValue, Integer index) {
            Map<String, Object> mergeMap = (Map<String, Object>) currentValue;
            SObject record = (SObject) element;
            mergeMap.putAll(record.getPopulatedFieldsAsMap());
            return mergeMap;
        }
    }

    private with sharing class ValueExtractor extends ArrayV1.Callback {
        public override Object function(Object element, Object currentValue, Integer index) {
            Map<String, Object> valueMap = (Map<String, Object>) currentValue;
            Map<String, Object> mergeMap = (Map<String, Object>) shared();
            SObjectField field = (SObjectField) element;
            valueMap.put(field.getDescribe().name, mergeMap.get(field.getDescribe().name));
            return valueMap;
        }
    }

    private with sharing class FilterTestRunnable extends ArrayV1.Callback {
        public override Object function(Object element, Object currentValue, Integer index) {
            if (shared() != null && ! (shared() instanceof String)) {
                return shared();
            }

            return (shared() == null)
                    ? ((AsynchronousJob__c) element).Runnable__c == 'TEST1'
                    : ((AsynchronousJob__c) element).Runnable__c == (String) shared();
        }
    }

    private with sharing class Transformer extends ArrayV1.Callback {
        public override Object function(Object element, Object currentValue, Integer index) {
            AsynchronousJob__c cloned = ((AsynchronousJob__c) element).clone();
            cloned.RetryInterval__c = shared() == null ? 1000 : (Integer) shared();
            return cloned;
        }
    }
}