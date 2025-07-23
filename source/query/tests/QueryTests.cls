/**
 * @description
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../../LICENSE target="_blank">MIT License</a>.
 * <br><br>
 * Unit tests for QueryV1 class.
 *
 * @author Mark Brennand
 */
@IsTest
public with sharing class QueryTests {

    @TestSetup
    private static void setup() {
        QueryTestHelper.createUsers();
    }

    @IsTest
    private static void testExtendedClassesAreInert() {
        ExtendedClass extended = new ExtendedClass();

        try {
            extended.type(Contact.SObjectType);
            Assert.fail();
        } catch (QueryException qe) {
            Assert.areEqual('Access denied', qe.getMessage());
        }

        try {
            extended.type();
            Assert.fail();
        } catch (QueryException qe) {
            Assert.areEqual('Access denied', qe.getMessage());
        }

        try {
            extended.security(AccessLevel.USER_MODE);
            Assert.fail();
        } catch (QueryException qe) {
            Assert.areEqual('Access denied', qe.getMessage());
        }

        try {
            extended.count();
            Assert.fail();
        } catch (QueryException qe) {
            Assert.areEqual('Access denied', qe.getMessage());
        }

        try {
            extended.returningAll();
            Assert.fail();
        } catch (QueryException qe) {
            Assert.areEqual('Access denied', qe.getMessage());
        }

        try {
            extended.returning(new Set<SObjectField>());
            Assert.fail();
        } catch (QueryException qe) {
            Assert.areEqual('Access denied', qe.getMessage());
        }

        try {
            extended.returning(Contact.AccountId, new Set<SObjectField>());
            Assert.fail();
        } catch (QueryException qe) {
            Assert.areEqual('Access denied', qe.getMessage());
        }

        try {
            extended.returning(new Set<QueryV1.AggregatedField>());
            Assert.fail();
        } catch (QueryException qe) {
            Assert.areEqual('Access denied', qe.getMessage());
        }

        try {
            extended.matching(null);
            Assert.fail();
        } catch (QueryException qe) {
            Assert.areEqual('Access denied', qe.getMessage());
        }

        try {
            extended.ordered((QueryV1.Order) null);
            Assert.fail();
        } catch (QueryException qe) {
            Assert.areEqual('Access denied', qe.getMessage());
        }

        try {
            extended.ordered(new List<QueryV1.Order>());
            Assert.fail();
        } catch (QueryException qe) {
            Assert.areEqual('Access denied', qe.getMessage());
        }

        try {
            extended.group(new Set<SObjectField>());
            Assert.fail();
        } catch (QueryException qe) {
            Assert.areEqual('Access denied', qe.getMessage());
        }

        try {
            extended.group(Contact.AccountId, new Set<SObjectField>());
            Assert.fail();
        } catch (QueryException qe) {
            Assert.areEqual('Access denied', qe.getMessage());
        }

        try {
            extended.has(null);
            Assert.fail();
        } catch (QueryException qe) {
            Assert.areEqual('Access denied', qe.getMessage());
        }

        try {
            extended.children(null);
            Assert.fail();
        } catch (QueryException qe) {
            Assert.areEqual('Access denied', qe.getMessage());
        }

        try {
            extended.execute(null);
            Assert.fail();
        } catch (QueryException qe) {
            Assert.areEqual('Access denied', qe.getMessage());
        }

        try {
            extended.max(null);
            Assert.fail();
        } catch (QueryException qe) {
            Assert.areEqual('Access denied', qe.getMessage());
        }

        try {
            extended.offset(null);
            Assert.fail();
        } catch (QueryException qe) {
            Assert.areEqual('Access denied', qe.getMessage());
        }
    }

    @IsTest
    private static void testMatching() {
        createData();
        System.runAs(QueryTestHelper.getUser()) {
            List<Contact> matches = (List<Contact>) QueryV1.of(Contact.SObjectType)
                    .security(AccessLevel.SYSTEM_MODE)
                    .returningAll()
                    .matching('LastName = \'1\' AND FirstName IN(\'AC\', \'CC\')')
                    .ordered(QueryV1.ascending(Contact.FirstName))
                    .execute(OptionalV1.empty()).get();

            Assert.areEqual(2, matches.size());
            Assert.areEqual('1', matches[0].LastName);
            Assert.areEqual('AC', matches[0].FirstName);
            Assert.areEqual('1', matches[1].LastName);
            Assert.areEqual('CC', matches[1].FirstName);

            matches = (List<Contact>) QueryV1.of(Contact.SObjectType)
                    .security(AccessLevel.SYSTEM_MODE)
                    .returningAll()
                    .matching('LastName = :lastName AND FirstName IN :firstNames')
                    .ordered(QueryV1.ascending(Contact.FirstName))
                    .execute(OptionalV1.of(new Map<String, Object> { 'lastName' => '1', 'firstNames' => new Set<String> { 'AC', 'CC' }}))
                    .get();

            Assert.areEqual(2, matches.size());
            Assert.areEqual('1', matches[0].LastName);
            Assert.areEqual('AC', matches[0].FirstName);
            Assert.areEqual('1', matches[1].LastName);
            Assert.areEqual('CC', matches[1].FirstName);
        }
    }

    @IsTest
    private static void testAggregation() {
        createData();
        System.runAs(QueryTestHelper.getUser()) {
            List<AggregateResult> matches = (List<AggregateResult>) QueryV1.of(Contact.SObjectType)
                    .returning(new Set<QueryV1.AggregatedField>{
                            QueryV1.aggregatedField(Contact.LastName, 'LastName'),
                            QueryV1.aggregatedField('COUNT', Contact.Id, 'Contacts')
                    })
                    .group(new Set<SObjectField>{ Contact.LastName })
                    .ordered(QueryV1.ascending(Contact.LastName))
                    .execute(OptionalV1.empty())
                    .get();

            Assert.areEqual(3, matches.size());
            Assert.areEqual('1', matches[0].get('LastName'));
            Assert.areEqual(4, matches[0].get('Contacts'));
            Assert.areEqual('2', matches[1].get('LastName'));
            Assert.areEqual(2, matches[1].get('Contacts'));
            Assert.areEqual('3', matches[2].get('LastName'));
            Assert.areEqual(1, matches[2].get('Contacts'));

            matches = (List<AggregateResult>) QueryV1.of(Contact.SObjectType)
                    .returning(new Set<QueryV1.AggregatedField>{
                            QueryV1.aggregatedField(Contact.LastName, 'LastName'),
                            QueryV1.aggregatedField(Contact.FirstName, 'FirstName'),
                            QueryV1.aggregatedField('COUNT', Contact.Id, 'Contacts')
                    })
                    .group(new Set<SObjectField>{ Contact.LastName })
                    .group(new Set<SObjectField>{ Contact.FirstName })
                    .ordered(QueryV1.ascending(Contact.LastName))
                    .ordered(QueryV1.ascending(Contact.FirstName))
                    .execute(OptionalV1.empty())
                    .get();

            Assert.areEqual(7, matches.size());
            Assert.areEqual('1', matches[0].get('LastName'));
            Assert.isNull(matches[0].get('FirstName'));
            Assert.areEqual(1, matches[0].get('Contacts'));
            Assert.areEqual('1', matches[1].get('LastName'));
            Assert.areEqual('AC', matches[1].get('FirstName'));
            Assert.areEqual(1, matches[1].get('Contacts'));
            Assert.areEqual('1', matches[2].get('LastName'));
            Assert.areEqual('BC', matches[2].get('FirstName'));
            Assert.areEqual(1, matches[2].get('Contacts'));
            Assert.areEqual('1', matches[3].get('LastName'));
            Assert.areEqual('CC', matches[3].get('FirstName'));
            Assert.areEqual(1, matches[3].get('Contacts'));
            Assert.areEqual('2', matches[4].get('LastName'));
            Assert.areEqual('AC', matches[4].get('FirstName'));
            Assert.areEqual(1, matches[4].get('Contacts'));
            Assert.areEqual('2', matches[5].get('LastName'));
            Assert.areEqual('BC', matches[5].get('FirstName'));
            Assert.areEqual(1, matches[5].get('Contacts'));
            Assert.areEqual('3', matches[6].get('LastName'));
            Assert.areEqual('AC', matches[6].get('FirstName'));
            Assert.areEqual(1, matches[6].get('Contacts'));

            matches = (List<AggregateResult>) QueryV1.of(Contact.SObjectType)
                    .returning(new Set<QueryV1.AggregatedField>{
                            QueryV1.aggregatedField(Contact.AccountId, Account.Name, 'AccountName'),
                            QueryV1.aggregatedField('COUNT', Contact.Id, 'Contacts')
                    })
                    .group(Contact.AccountId, new Set<SObjectField>{ Account.Name })
                    .ordered(QueryV1.ascending(Contact.AccountId, Account.Name))
                    .execute(OptionalV1.empty())
                    .get();

            Assert.areEqual(4, matches.size());
            Assert.areEqual('A', matches[0].get('AccountName'));
            Assert.areEqual(3, matches[0].get('Contacts'));
            Assert.areEqual('B', matches[1].get('AccountName'));
            Assert.areEqual(2, matches[1].get('Contacts'));
            Assert.areEqual('C', matches[2].get('AccountName'));
            Assert.areEqual(1, matches[2].get('Contacts'));
            Assert.areEqual('D', matches[3].get('AccountName'));
            Assert.areEqual(1, matches[3].get('Contacts'));

            matches = (List<AggregateResult>) QueryV1.of(Contact.SObjectType)
                    .returning(new Set<QueryV1.AggregatedField>{
                            QueryV1.aggregatedField(Contact.AccountId, Account.Name, 'AccountName'),
                            QueryV1.aggregatedField('COUNT', Contact.Id, 'Contacts')
                    })
                    .returning(new Set<QueryV1.AggregatedField> {
                            QueryV1.aggregatedField(Contact.FirstName, 'FirstName')
                    })
                    .group(Contact.AccountId, new Set<SObjectField>{ Account.Name })
                    .group(new Set<SObjectField> { Contact.FirstName })
                    .ordered(QueryV1.ascending(Contact.AccountId, Account.Name))
                    .execute(OptionalV1.empty())
                    .get();

            Assert.areEqual(4, matches.size());
            Assert.areEqual('A', matches[0].get('AccountName'));
            Assert.areEqual('AC', matches[0].get('FirstName'));
            Assert.areEqual(3, matches[0].get('Contacts'));
            Assert.areEqual('B', matches[1].get('AccountName'));
            Assert.areEqual('BC', matches[1].get('FirstName'));
            Assert.areEqual(2, matches[1].get('Contacts'));
            Assert.areEqual('C', matches[2].get('AccountName'));
            Assert.areEqual('CC', matches[2].get('FirstName'));
            Assert.areEqual(1, matches[2].get('Contacts'));
            Assert.areEqual('D', matches[3].get('AccountName'));
            Assert.isNull(matches[3].get('FirstName'));
            Assert.areEqual(1, matches[3].get('Contacts'));

            try {
                QueryV1.of(Contact.SObjectType)
                        .returning(new Set<QueryV1.AggregatedField>{
                                QueryV1.aggregatedField(Contact.LastName, 'LastName'),
                                QueryV1.aggregatedField('COUNT', Contact.Id, 'Contacts')
                        })
                        .returning(new Set<SObjectField>{ Contact.Name });
                Assert.fail();
            } catch(QueryException qe) {
                Assert.areEqual('Operation may not be performed on an aggregation query', qe.getMessage());
            }

            try {
                QueryV1.of(Contact.SObjectType)
                        .returning(new Set<QueryV1.AggregatedField>{
                                QueryV1.aggregatedField(Contact.LastName, 'LastName'),
                                QueryV1.aggregatedField('COUNT', Contact.Id, 'Contacts')
                        })
                        .returning(Contact.AccountId, new Set<SObjectField> { Account.Name });
                Assert.fail();
            } catch(QueryException qe) {
                Assert.areEqual('Operation may not be performed on an aggregation query', qe.getMessage());
            }
        }
    }

    @IsTest
    private static void testHas() {
        createData();
        System.runAs(QueryTestHelper.getUser()) {
            List<AggregateResult> matches = (List<AggregateResult>) QueryV1.of(Contact.SObjectType)
                    .returning(new Set<QueryV1.AggregatedField>{
                            QueryV1.aggregatedField(Contact.LastName, 'LastName'),
                            QueryV1.aggregatedField('COUNT', Contact.Id, 'Contacts')
                    })
                    .group(new Set<SObjectField>{ Contact.LastName })
                    .has('COUNT(Id) >= 1')
                    .ordered(QueryV1.ascending(Contact.LastName))
                    .execute(OptionalV1.empty())
                    .get();

            Assert.areEqual(3, matches.size());
            Assert.areEqual('1', matches[0].get('LastName'));
            Assert.areEqual(4, matches[0].get('Contacts'));
            Assert.areEqual('2', matches[1].get('LastName'));
            Assert.areEqual(2, matches[1].get('Contacts'));
            Assert.areEqual('3', matches[2].get('LastName'));
            Assert.areEqual(1, matches[2].get('Contacts'));

            matches = (List<AggregateResult>) QueryV1.of(Contact.SObjectType)
                    .returning(new Set<QueryV1.AggregatedField>{
                            QueryV1.aggregatedField(Contact.LastName, 'LastName'),
                            QueryV1.aggregatedField('COUNT', Contact.Id, 'Contacts')
                    })
                    .group(new Set<SObjectField>{ Contact.LastName })
                    .has('COUNT(Id) > 3')
                    .ordered(QueryV1.ascending(Contact.LastName))
                    .execute(OptionalV1.empty())
                    .get();

            Assert.areEqual(1, matches.size());
            Assert.areEqual('1', matches[0].get('LastName'));
            Assert.areEqual(4, matches[0].get('Contacts'));
        }
    }

    @IsTest
    private static void testChildren() {
        createData();
        System.runAs(QueryTestHelper.getUser()) {
            List<Account> matches = (List<Account>) QueryV1.of(Account.SObjectType)
                    .returning(new Set<SObjectField> { Account.Name })
                    .children(
                            QueryV1.of(Contact.SObjectType)
                                    .returning(new Set<SObjectField> { Contact.FirstName, Contact.LastName })
                                    .ordered(new List<QueryV1.Order> {
                                            QueryV1.ascending(Contact.LastName),
                                            QueryV1.ascending(Contact.FirstName)
                                    })
                    )
                    .children(
                            QueryV1.of(Partner.SObjectType)
                                    .returning(new Set<SObjectField> { Partner.IsPrimary })
                                    .returning(Partner.AccountFromId, new Set<SObjectField> { Account.Name })
                                    .returning(Partner.AccountToId, new Set<SObjectField> { Account.Name })
                                    .ordered(new List<QueryV1.Order> {
                                            QueryV1.ascending(Partner.AccountFromId, Account.Name, true),
                                            QueryV1.descending(Partner.AccountToId, Account.Name, false)
                                    })
                    )
                    .ordered(QueryV1.ascending(Account.Name))
                    .execute(OptionalV1.empty()).get();

            Assert.areEqual(4, matches.size());
            Assert.areEqual('A', matches[0].Name);
            Assert.areEqual('1', matches[0].Contacts[0].LastName);
            Assert.areEqual('AC', matches[0].Contacts[0].FirstName);
            Assert.areEqual('2', matches[0].Contacts[1].LastName);
            Assert.areEqual('AC', matches[0].Contacts[1].FirstName);
            Assert.areEqual('3', matches[0].Contacts[2].LastName);
            Assert.areEqual('AC', matches[0].Contacts[2].FirstName);
            Assert.areEqual('B', matches[1].Name);
            Assert.areEqual('1', matches[1].Contacts[0].LastName);
            Assert.areEqual('BC', matches[1].Contacts[0].FirstName);
            Assert.areEqual('2', matches[1].Contacts[1].LastName);
            Assert.areEqual('BC', matches[1].Contacts[1].FirstName);
            Assert.areEqual('C', matches[2].Name);
            Assert.areEqual('1', matches[2].Contacts[0].LastName);
            Assert.areEqual('CC', matches[2].Contacts[0].FirstName);
            Assert.areEqual('D', matches[3].Name);
            Assert.areEqual('1', matches[3].Contacts[0].LastName);
            Assert.isNull(matches[3].Contacts[0].FirstName);

            matches = (List<Account>) QueryV1.of(Account.SObjectType)
                    .returning(new Set<SObjectField> { Account.Name })
                    .children(
                            QueryV1.of(Contact.SObjectType)
                                    .returning(new Set<SObjectField> { Contact.FirstName, Contact.LastName })
                                    .returning(Contact.AccountId, new Set<SObjectField> { Account.Name })
                                    .ordered(new List<QueryV1.Order> {
                                            QueryV1.ascending(Contact.LastName),
                                            QueryV1.ascending(Contact.FirstName)
                                    })
                    )
                    .ordered(QueryV1.ascending(Account.Name))
                    .execute(OptionalV1.empty()).get();

            Assert.areEqual(4, matches.size());
            Assert.areEqual('A', matches[0].Name);
            Assert.areEqual('1', matches[0].Contacts[0].LastName);
            Assert.areEqual('AC', matches[0].Contacts[0].FirstName);
            Assert.areEqual('A', matches[0].Contacts[0].Account.Name);
            Assert.areEqual('2', matches[0].Contacts[1].LastName);
            Assert.areEqual('AC', matches[0].Contacts[1].FirstName);
            Assert.areEqual('A', matches[0].Contacts[1].Account.Name);
            Assert.areEqual('3', matches[0].Contacts[2].LastName);
            Assert.areEqual('AC', matches[0].Contacts[2].FirstName);
            Assert.areEqual('A', matches[0].Contacts[2].Account.Name);
            Assert.areEqual('B', matches[1].Name);
            Assert.areEqual('1', matches[1].Contacts[0].LastName);
            Assert.areEqual('BC', matches[1].Contacts[0].FirstName);
            Assert.areEqual('B', matches[1].Contacts[0].Account.Name);
            Assert.areEqual('2', matches[1].Contacts[1].LastName);
            Assert.areEqual('BC', matches[1].Contacts[1].FirstName);
            Assert.areEqual('B', matches[1].Contacts[1].Account.Name);
            Assert.areEqual('C', matches[2].Name);
            Assert.areEqual('1', matches[2].Contacts[0].LastName);
            Assert.areEqual('CC', matches[2].Contacts[0].FirstName);
            Assert.areEqual('C', matches[2].Contacts[0].Account.Name);
            Assert.areEqual('D', matches[3].Name);
            Assert.areEqual('1', matches[3].Contacts[0].LastName);
            Assert.isNull(matches[3].Contacts[0].FirstName);
            Assert.areEqual('D', matches[3].Contacts[0].Account.Name);

            try {
                QueryV1.of(Contact.SObjectType)
                        .security(AccessLevel.SYSTEM_MODE)
                        .returningAll()
                        .children(QueryV1.of(Account.SObjectType).returningAll())
                        .execute(OptionalV1.empty());
                Assert.fail();
            } catch(QueryException qe) {
                Assert.areEqual('No relationship found to object Account', qe.getMessage());
            }
        }
    }

    @IsTest
    private static void testMax() {
        createData();
        System.runAs(QueryTestHelper.getUser()) {
            List<Contact> matches = (List<Contact>) QueryV1.of(Contact.SObjectType)
                    .security(AccessLevel.SYSTEM_MODE)
                    .returningAll()
                    .returning(Contact.AccountId, new Set<SObjectField>{
                            Account.Name
                    })
                    .ordered(new List<QueryV1.Order>{
                            QueryV1.ascending(Contact.LastName),
                            QueryV1.ascending(Contact.FirstName)
                    })
                    .max(2)
                    .execute(OptionalV1.empty()).get();

            Assert.areEqual(2, matches.size());
            Assert.areEqual('1', matches[0].LastName);
            Assert.isNull(matches[0].FirstName);
            Assert.areEqual('1', matches[1].LastName);
            Assert.areEqual('AC', matches[1].FirstName);

            matches = (List<Contact>) QueryV1.of(Contact.SObjectType)
                    .security(AccessLevel.SYSTEM_MODE)
                    .returningAll()
                    .returning(Contact.AccountId, new Set<SObjectField>{
                            Account.Name
                    })
                    .ordered(new List<QueryV1.Order>{
                            QueryV1.ascending(Contact.LastName),
                            QueryV1.ascending(Contact.FirstName)
                    })
                    .max(1)
                    .execute(OptionalV1.empty()).get();

            Assert.areEqual(1, matches.size());
            Assert.areEqual('1', matches[0].LastName);
            Assert.isNull(matches[0].FirstName);
        }
    }

    @IsTest
    private static void testOffset() {
        createData();
        System.runAs(QueryTestHelper.getUser()) {
            List<Contact> matches = (List<Contact>) QueryV1.of(Contact.SObjectType)
                    .returning(new Set<SObjectField>{
                            Contact.FirstName, Contact.LastName
                    })
                    .ordered(new List<QueryV1.Order>{
                            QueryV1.ascending(Contact.LastName),
                            QueryV1.ascending(Contact.FirstName)
                    })
                    .offset(1)
                    .execute(OptionalV1.empty()).get();

            Assert.areEqual(6, matches.size());
            Assert.areEqual('1', matches[0].LastName);
            Assert.areEqual('AC', matches[0].FirstName);
            Assert.areEqual('1', matches[1].LastName);
            Assert.areEqual('BC', matches[1].FirstName);
            Assert.areEqual('1', matches[2].LastName);
            Assert.areEqual('CC', matches[2].FirstName);
            Assert.areEqual('2', matches[3].LastName);
            Assert.areEqual('AC', matches[3].FirstName);
            Assert.areEqual('2', matches[4].LastName);
            Assert.areEqual('BC', matches[4].FirstName);
            Assert.areEqual('3', matches[5].LastName);
            Assert.areEqual('AC', matches[5].FirstName);

            matches = (List<Contact>) QueryV1.of(Contact.SObjectType)
                    .returning(new Set<SObjectField>{
                            Contact.FirstName, Contact.LastName
                    })
                    .ordered(new List<QueryV1.Order>{
                            QueryV1.ascending(Contact.LastName),
                            QueryV1.ascending(Contact.FirstName)
                    })
                    .offset(5)
                    .execute(OptionalV1.empty()).get();

            Assert.areEqual(2, matches.size());
            Assert.areEqual('2', matches[0].LastName);
            Assert.areEqual('BC', matches[0].FirstName);
            Assert.areEqual('3', matches[1].LastName);
            Assert.areEqual('AC', matches[1].FirstName);
        }
    }

    @IsTest
    private static void testJoin() {
        createData();
        System.runAs(QueryTestHelper.getUser()) {
            List<Contact> matches = (List<Contact>) QueryV1.of(Contact.SObjectType)
                    .security(AccessLevel.SYSTEM_MODE)
                    .returningAll()
                    .returning(Contact.AccountId, new Set<SObjectField> { Account.Name })
                    .ordered(new List<QueryV1.Order>{
                            QueryV1.ascending(Contact.LastName),
                            QueryV1.ascending(Contact.FirstName)
                    })
                    .execute(OptionalV1.empty()).get();

            Assert.areEqual(7, matches.size());
            Assert.areEqual('1', matches[0].LastName);
            Assert.isNull(matches[0].FirstName);
            Assert.areEqual('D', matches[0].Account.Name);
            Assert.areEqual('1', matches[1].LastName);
            Assert.areEqual('AC', matches[1].FirstName);
            Assert.areEqual('A', matches[1].Account.Name);
            Assert.areEqual('1', matches[2].LastName);
            Assert.areEqual('BC', matches[2].FirstName);
            Assert.areEqual('B', matches[2].Account.Name);
            Assert.areEqual('1', matches[3].LastName);
            Assert.areEqual('CC', matches[3].FirstName);
            Assert.areEqual('C', matches[3].Account.Name);
            Assert.areEqual('2', matches[4].LastName);
            Assert.areEqual('AC', matches[4].FirstName);
            Assert.areEqual('A', matches[4].Account.Name);
            Assert.areEqual('2', matches[5].LastName);
            Assert.areEqual('BC', matches[5].FirstName);
            Assert.areEqual('B', matches[5].Account.Name);
            Assert.areEqual('3', matches[6].LastName);
            Assert.areEqual('AC', matches[6].FirstName);
            Assert.areEqual('A', matches[6].Account.Name);
        }

        try {
            QueryV1.of(Contact.SObjectType).returning(Contact.Name, new Set<SObjectField>{ Account.Name });
            Assert.fail();
        } catch(QueryException qe) {
            Assert.areEqual('Join field must be the Id field of the SObject to join', qe.getMessage());
        }
    }

    @IsTest
    private static void testCount() {
        createData();
        System.runAs(QueryTestHelper.getUser()) {
            Assert.areEqual(7, QueryV1.of(Contact.SObjectType).count().execute(OptionalV1.empty()).get());
            Assert.areEqual(
                    4,
                    QueryV1.of(Contact.SObjectType)
                            .count()
                            .matching('LastName = :lastName')
                            .execute(OptionalV1.of(new Map<String, Object> { 'lastName' => '1' }))
                            .get()
            );

            try {
                QueryV1.of(Contact.SObjectType).count().returningAll();
                Assert.fail();
            } catch (QueryException qe) {
                Assert.areEqual('Operation may not be performed on a count query', qe.getMessage());
            }

            try {
                QueryV1.of(Contact.SObjectType).count().returning(new Set<SObjectField>{
                        Contact.Name
                });
                Assert.fail();
            } catch (QueryException qe) {
                Assert.areEqual('Operation may not be performed on a count query', qe.getMessage());
            }

            try {
                QueryV1.of(Contact.SObjectType).count().returning(Contact.AccountId, new Set<SObjectField>{
                        Account.Name
                });
                Assert.fail();
            } catch (QueryException qe) {
                Assert.areEqual('Operation may not be performed on a count query', qe.getMessage());
            }

            try {
                QueryV1.of(Contact.SObjectType).count().returning(new Set<QueryV1.AggregatedField>{
                        QueryV1.aggregatedField(Contact.Name, 'ContactName')
                });
                Assert.fail();
            } catch (QueryException qe) {
                Assert.areEqual('Operation may not be performed on a count query', qe.getMessage());
            }
        }
    }

    @IsTest
    private static void testOrder() {
        createData();
        System.runAs(QueryTestHelper.getUser()) {
            List<Contact> matches = (List<Contact>) QueryV1.of(Contact.SObjectType)
                    .returning(new Set<SObjectField>{
                            Contact.FirstName, Contact.LastName
                    })
                    .ordered(new List<QueryV1.Order>{
                            QueryV1.ascending(Contact.LastName),
                            QueryV1.ascending(Contact.FirstName)
                    })
                    .execute(OptionalV1.empty()).get();

            Assert.areEqual(7, matches.size());
            Assert.areEqual('1', matches[0].LastName);
            Assert.isNull(matches[0].FirstName);
            Assert.areEqual('1', matches[1].LastName);
            Assert.areEqual('AC', matches[1].FirstName);
            Assert.areEqual('1', matches[2].LastName);
            Assert.areEqual('BC', matches[2].FirstName);
            Assert.areEqual('1', matches[3].LastName);
            Assert.areEqual('CC', matches[3].FirstName);
            Assert.areEqual('2', matches[4].LastName);
            Assert.areEqual('AC', matches[4].FirstName);
            Assert.areEqual('2', matches[5].LastName);
            Assert.areEqual('BC', matches[5].FirstName);
            Assert.areEqual('3', matches[6].LastName);
            Assert.areEqual('AC', matches[6].FirstName);

            matches = (List<Contact>) QueryV1.of(Contact.SObjectType)
                    .returning(new Set<SObjectField>{
                            Contact.FirstName, Contact.LastName
                    })
                    .ordered(new List<QueryV1.Order>{
                            QueryV1.ascending(Contact.LastName, false),
                            QueryV1.ascending(Contact.FirstName, false)
                    })
                    .execute(OptionalV1.empty()).get();

            Assert.areEqual(7, matches.size());
            Assert.areEqual('1', matches[0].LastName);
            Assert.areEqual('AC', matches[0].FirstName);
            Assert.areEqual('1', matches[1].LastName);
            Assert.areEqual('BC', matches[1].FirstName);
            Assert.areEqual('1', matches[2].LastName);
            Assert.areEqual('CC', matches[2].FirstName);
            Assert.areEqual('1', matches[3].LastName);
            Assert.isNull(matches[3].FirstName);
            Assert.areEqual('2', matches[4].LastName);
            Assert.areEqual('AC', matches[4].FirstName);
            Assert.areEqual('2', matches[5].LastName);
            Assert.areEqual('BC', matches[5].FirstName);
            Assert.areEqual('3', matches[6].LastName);
            Assert.areEqual('AC', matches[6].FirstName);

            matches = (List<Contact>) QueryV1.of(Contact.SObjectType)
                    .returning(new Set<SObjectField>{
                            Contact.FirstName, Contact.LastName
                    })
                    .ordered(QueryV1.ascending(Contact.LastName, false))
                    .ordered(QueryV1.ascending(Contact.FirstName, false))
                    .execute(OptionalV1.empty()).get();

            Assert.areEqual(7, matches.size());
            Assert.areEqual('1', matches[0].LastName);
            Assert.areEqual('AC', matches[0].FirstName);
            Assert.areEqual('1', matches[1].LastName);
            Assert.areEqual('BC', matches[1].FirstName);
            Assert.areEqual('1', matches[2].LastName);
            Assert.areEqual('CC', matches[2].FirstName);
            Assert.areEqual('1', matches[3].LastName);
            Assert.isNull(matches[3].FirstName);
            Assert.areEqual('2', matches[4].LastName);
            Assert.areEqual('AC', matches[4].FirstName);
            Assert.areEqual('2', matches[5].LastName);
            Assert.areEqual('BC', matches[5].FirstName);
            Assert.areEqual('3', matches[6].LastName);
            Assert.areEqual('AC', matches[6].FirstName);

            matches = (List<Contact>) QueryV1.of(Contact.SObjectType)
                    .returning(new Set<SObjectField>{
                            Contact.FirstName, Contact.LastName
                    })
                    .ordered(new List<QueryV1.Order>{
                            QueryV1.descending(Contact.LastName),
                            QueryV1.descending(Contact.FirstName)
                    })
                    .execute(OptionalV1.empty()).get();

            Assert.areEqual(7, matches.size());
            Assert.areEqual('3', matches[0].LastName);
            Assert.areEqual('AC', matches[0].FirstName);
            Assert.areEqual('2', matches[1].LastName);
            Assert.areEqual('BC', matches[1].FirstName);
            Assert.areEqual('2', matches[2].LastName);
            Assert.areEqual('AC', matches[2].FirstName);
            Assert.areEqual('1', matches[3].LastName);
            Assert.isNull(matches[3].FirstName);
            Assert.areEqual('1', matches[4].LastName);
            Assert.areEqual('CC', matches[4].FirstName);
            Assert.areEqual('1', matches[5].LastName);
            Assert.areEqual('BC', matches[5].FirstName);
            Assert.areEqual('1', matches[6].LastName);
            Assert.areEqual('AC', matches[6].FirstName);

            matches = (List<Contact>) QueryV1.of(Contact.SObjectType)
                    .returning(new Set<SObjectField>{
                            Contact.FirstName, Contact.LastName
                    })
                    .ordered(new List<QueryV1.Order>{
                            QueryV1.descending(Contact.LastName, false),
                            QueryV1.descending(Contact.FirstName, false)
                    })
                    .execute(OptionalV1.empty()).get();

            Assert.areEqual(7, matches.size());
            Assert.areEqual('3', matches[0].LastName);
            Assert.areEqual('AC', matches[0].FirstName);
            Assert.areEqual('2', matches[1].LastName);
            Assert.areEqual('BC', matches[1].FirstName);
            Assert.areEqual('2', matches[2].LastName);
            Assert.areEqual('AC', matches[2].FirstName);
            Assert.areEqual('1', matches[3].LastName);
            Assert.areEqual('CC', matches[3].FirstName);
            Assert.areEqual('1', matches[4].LastName);
            Assert.areEqual('BC', matches[4].FirstName);
            Assert.areEqual('1', matches[5].LastName);
            Assert.areEqual('AC', matches[5].FirstName);
            Assert.areEqual('1', matches[6].LastName);
            Assert.isNull(matches[6].FirstName);

            matches = (List<Contact>) QueryV1.of(Contact.SObjectType)
                    .returning(new Set<SObjectField>{
                            Contact.FirstName, Contact.LastName
                    })
                    .ordered(new List<QueryV1.Order>{
                            QueryV1.ascending(Contact.LastName, true),
                            QueryV1.descending(Contact.FirstName, true)
                    })
                    .execute(OptionalV1.empty()).get();

            Assert.areEqual(7, matches.size());
            Assert.areEqual('1', matches[0].LastName);
            Assert.isNull(matches[0].FirstName);
            Assert.areEqual('1', matches[1].LastName);
            Assert.areEqual('CC', matches[1].FirstName);
            Assert.areEqual('1', matches[2].LastName);
            Assert.areEqual('BC', matches[2].FirstName);
            Assert.areEqual('1', matches[3].LastName);
            Assert.areEqual('AC', matches[3].FirstName);
            Assert.areEqual('2', matches[4].LastName);
            Assert.areEqual('BC', matches[4].FirstName);
            Assert.areEqual('2', matches[5].LastName);
            Assert.areEqual('AC', matches[5].FirstName);
            Assert.areEqual('3', matches[6].LastName);
            Assert.areEqual('AC', matches[6].FirstName);

            matches = (List<Contact>) QueryV1.of(Contact.SObjectType)
                    .returning(new Set<SObjectField>{
                            Contact.FirstName, Contact.LastName
                    })
                    .ordered(new List<QueryV1.Order>{
                            QueryV1.ascending(Contact.AccountId, Account.Name),
                            QueryV1.ascending(Contact.LastName),
                            QueryV1.ascending(Contact.FirstName)
                    })
                    .execute(OptionalV1.empty()).get();

            Assert.areEqual(7, matches.size());
            Assert.areEqual('1', matches[0].LastName);
            Assert.areEqual('AC', matches[0].FirstName);
            Assert.areEqual('2', matches[1].LastName);
            Assert.areEqual('AC', matches[1].FirstName);
            Assert.areEqual('3', matches[2].LastName);
            Assert.areEqual('AC', matches[2].FirstName);
            Assert.areEqual('1', matches[3].LastName);
            Assert.areEqual('BC', matches[3].FirstName);
            Assert.areEqual('2', matches[4].LastName);
            Assert.areEqual('BC', matches[4].FirstName);
            Assert.areEqual('1', matches[5].LastName);
            Assert.areEqual('CC', matches[5].FirstName);
            Assert.areEqual('1', matches[6].LastName);
            Assert.isNull(matches[6].FirstName);
        }
    }

    private static void createData() {
        Account a = new Account(Name = 'A');
        Account b = new Account(Name = 'B');
        Account c = new Account(Name = 'C');
        Account d = new Account(Name = 'D');

        insert new List<SObject> { a, b, c, d };

        insert new List<SObject> {
                new Contact(FirstName = 'AC', LastName = '1', AccountId = a.Id),
                new Contact(FirstName = 'AC', LastName = '2', AccountId = a.Id),
                new Contact(FirstName = 'AC', LastName = '3', AccountId = a.Id),
                new Contact(FirstName = 'BC', LastName = '1', AccountId = b.Id),
                new Contact(FirstName = 'BC', LastName = '2', AccountId = b.Id),
                new Contact(FirstName = 'CC', LastName = '1', AccountId = c.Id),
                new Contact(FirstName = null, LastName = '1', AccountId = d.Id)
        };
    }

    private with sharing class ExtendedClass extends QueryAPI {}
}