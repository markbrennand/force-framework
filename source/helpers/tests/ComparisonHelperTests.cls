/**
 * @description
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../../LICENSE target="_blank">MIT License</a>.
 * <br><br>
 * Unit tests for ComparisonHelper class.
 *
 * @author Mark Brennand
 */
@IsTest
public with sharing class ComparisonHelperTests {

    @IsTest
    private static void testObjectComparison() {
        Assert.isTrue(ComparisonHelper.compare(1, 1));
        Assert.isFalse(ComparisonHelper.compare(1, 2));
    }

    @IsTest
    private static void testSObjectComparison() {
        Account a1 = new Account(Name = 'Bill');
        Account a2 = new Account(Name = 'Ted');
        Account a3 = new Account(Name = 'Bill', AccountNumber = '1');

        Assert.isTrue(ComparisonHelper.compare(a1, a1));
        Assert.isFalse(ComparisonHelper.compare(a1, a2));
        Assert.isTrue(ComparisonHelper.compare(a1, a3));

        Assert.isFalse(ComparisonHelper.compare(a2, a1));
        Assert.isTrue(ComparisonHelper.compare(a2, a2));
        Assert.isFalse(ComparisonHelper.compare(a2, a3));

        Assert.isFalse(ComparisonHelper.compare(a3, a1));
        Assert.isFalse(ComparisonHelper.compare(a3, a2));
        Assert.isTrue(ComparisonHelper.compare(a3, a3));

        Assert.isFalse(ComparisonHelper.compare(a1, 102));
    }

    @IsTest
    private static void testListSObjectComparison() {
        Account a1 = new Account(Name = 'Bill');
        Account a2 = new Account(Name = 'Ted');
        Account a3 = new Account(Name = 'Bill', AccountNumber = '1');

        Assert.isTrue(ComparisonHelper.compare(new List<SObject> { a1, a2 }, new List<SObject> { a1, a2 } ));
        Assert.isFalse(ComparisonHelper.compare(new List<SObject> { a1, a2 }, new List<SObject> { a1, a3 } ));
        Assert.isTrue(ComparisonHelper.compare(new List<SObject> { a1, a2 }, new List<SObject> { a3, a2 } ));

        Assert.isTrue(ComparisonHelper.compare(new List<SObject> { a2, a1 }, new List<SObject> { a2, a1 } ));
        Assert.isFalse(ComparisonHelper.compare(new List<SObject> { a2, a1 }, new List<SObject> { a3, a1 } ));
        Assert.isTrue(ComparisonHelper.compare(new List<SObject> { a2, a1 }, new List<SObject> { a2, a3 } ));

        Assert.isTrue(ComparisonHelper.compare(new List<SObject> { a3, a2 }, new List<SObject> { a3, a2 } ));
        Assert.isFalse(ComparisonHelper.compare(new List<SObject> { a3, a2 }, new List<SObject> { a1, a2 } ));
        Assert.isFalse(ComparisonHelper.compare(new List<SObject> { a3, a2 }, new List<SObject> { a2, a2 } ));

        Assert.isFalse(ComparisonHelper.compare(new List<SObject> { a1, a2 }, a3));
        Assert.isFalse(ComparisonHelper.compare(new List<SObject> { a1, a2 }, new List<Integer> { 1, 2 }));
    }

    @IsTest
    private static void testSetSObjectComparison() {
        Account a1 = new Account(Name = 'Bill');
        Account a2 = new Account(Name = 'Ted');
        Account a3 = new Account(Name = 'Bill', AccountNumber = '1');

        Assert.isTrue(ComparisonHelper.compare(new Set<SObject> { a1, a2 }, new Set<SObject> { a1, a2 } ));
        Assert.isFalse(ComparisonHelper.compare(new Set<SObject> { a1, a2 }, new Set<SObject> { a1, a3 } ));
        Assert.isTrue(ComparisonHelper.compare(new Set<SObject> { a1, a2 }, new Set<SObject> { a3, a2 } ));

        Assert.isTrue(ComparisonHelper.compare(new Set<SObject> { a2, a1 }, new Set<SObject> { a2, a1 } ));
        Assert.isFalse(ComparisonHelper.compare(new Set<SObject> { a2, a1 }, new Set<SObject> { a3, a1 } ));
        Assert.isTrue(ComparisonHelper.compare(new Set<SObject> { a2, a1 }, new Set<SObject> { a2, a3 } ));

        Assert.isTrue(ComparisonHelper.compare(new Set<SObject> { a3, a2 }, new Set<SObject> { a3, a2 } ));
        Assert.isFalse(ComparisonHelper.compare(new Set<SObject> { a3, a2 }, new Set<SObject> { a1, a2 } ));
        Assert.isFalse(ComparisonHelper.compare(new Set<SObject> { a3, a2 }, new Set<SObject> { a2, a2 } ));

        Assert.isFalse(ComparisonHelper.compare(new Set<SObject> { a1, a2 }, a3));
        Assert.isFalse(ComparisonHelper.compare(new Set<SObject> { a1, a2 }, new Set<Integer> { 1, 2 }));
    }

    @IsTest
    private static void testAdditionalComparator() {
        Exception exc1 = new DMLException('TEST');

        Assert.isFalse(ComparisonHelper.compare(exc1, new Dependency.APIException('TEST')));

        Assert.isTrue(ComparisonHelper.compare(
                new List<Comparator<Object>> { new ExceptionComparator() },
                exc1,
                new Dependency.APIException('TEST'))
        );

        Assert.isFalse(ComparisonHelper.compare(
                new List<Comparator<Object>> { new ExceptionComparator() },
                exc1,
                new Dependency.APIException('ANOTHER'))
        );
    }

    private with sharing class ExceptionComparator implements Comparator<Object> {

        public Integer compare(Object param1, Object param2) {

            // For the test, if the exceptions have the same message they match.
            return param1 instanceof Exception &&
                    param2 instanceof Exception &&
                    ((Exception) param1).getMessage() == ((Exception) param2).getMessage() ? 0 : -1;
        }
    }
}
