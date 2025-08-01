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
    private final static String TESTING = 'query';

    @TestSetup
    private static void createUsers() {
        TestHelper.createUsers(TESTING, new Set<String> { 'ForceFwDependencyInjectionPermissions' });
    }

    @IsTest
    @SuppressWarnings('PMD.NcssMethodCount')
    private static void testExtendedClassesAreInert() {
        TestHelper.setNOW();
        System.runAs(TestHelper.getUser(TESTING)) {
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
                extended.returning((QueryV1.API) null);
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
                extended.ordered(new Set<QueryV1.Order>());
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
    }

    @IsTest
    private static void testMatching() {
        TestHelper.setNOW();
        createData();
        System.runAs(TestHelper.getUser(TESTING)) {
            List<Contact> contacts = (List<Contact>) QueryV1.of(Contact.SObjectType)
                    .security(AccessLevel.SYSTEM_MODE)
                    .returningAll()
                    .matching('LastName = \'1\' AND FirstName IN(\'AC\', \'CC\')')
                    .ordered(QueryV1.ascending(Contact.FirstName))
                    .execute(OptionalV1.empty()).get();

            Assert.areEqual(2, contacts.size());
            Assert.areEqual('1', contacts[0].LastName);
            Assert.areEqual('AC', contacts[0].FirstName);
            Assert.areEqual('1', contacts[1].LastName);
            Assert.areEqual('CC', contacts[1].FirstName);

            contacts = (List<Contact>) QueryV1.of(Contact.SObjectType)
                    .security(AccessLevel.SYSTEM_MODE)
                    .returningAll()
                    .matching('LastName = :lastName AND FirstName IN :firstNames')
                    .ordered(QueryV1.ascending(Contact.FirstName))
                    .execute(OptionalV1.of(new Map<String, Object> { 'lastName' => '1', 'firstNames' => new Set<String> { 'AC', 'CC' }}))
                    .get();

            Assert.areEqual(2, contacts.size());
            Assert.areEqual('1', contacts[0].LastName);
            Assert.areEqual('AC', contacts[0].FirstName);
            Assert.areEqual('1', contacts[1].LastName);
            Assert.areEqual('CC', contacts[1].FirstName);
        }
    }

    @IsTest
    @SuppressWarnings('PMD.NcssMethodCount')
    private static void testAggregation() {
        TestHelper.setNOW();
        createData();
        System.runAs(TestHelper.getUser(TESTING)) {
            List<AggregateResult> aggregates = (List<AggregateResult>) QueryV1.of(Contact.SObjectType)
                    .security(AccessLevel.SYSTEM_MODE)
                    .returning(new Set<QueryV1.AggregatedField>{
                            QueryV1.aggregatedField(Contact.LastName, 'LastName'),
                            QueryV1.aggregatedField('COUNT', Contact.Id, 'Contacts')
                    })
                    .group(new Set<SObjectField>{ Contact.LastName })
                    .ordered(QueryV1.ascending(Contact.LastName))
                    .execute(OptionalV1.empty())
                    .get();

            Assert.areEqual(3, aggregates.size());
            Assert.areEqual('1', aggregates[0].get('LastName'));
            Assert.areEqual(4, aggregates[0].get('Contacts'));
            Assert.areEqual('2', aggregates[1].get('LastName'));
            Assert.areEqual(2, aggregates[1].get('Contacts'));
            Assert.areEqual('3', aggregates[2].get('LastName'));
            Assert.areEqual(1, aggregates[2].get('Contacts'));

            aggregates = (List<AggregateResult>) QueryV1.of(Contact.SObjectType)
                    .security(AccessLevel.SYSTEM_MODE)
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

            Assert.areEqual(7, aggregates.size());
            Assert.areEqual('1', aggregates[0].get('LastName'));
            Assert.isNull(aggregates[0].get('FirstName'));
            Assert.areEqual(1, aggregates[0].get('Contacts'));
            Assert.areEqual('1', aggregates[1].get('LastName'));
            Assert.areEqual('AC', aggregates[1].get('FirstName'));
            Assert.areEqual(1, aggregates[1].get('Contacts'));
            Assert.areEqual('1', aggregates[2].get('LastName'));
            Assert.areEqual('BC', aggregates[2].get('FirstName'));
            Assert.areEqual(1, aggregates[2].get('Contacts'));
            Assert.areEqual('1', aggregates[3].get('LastName'));
            Assert.areEqual('CC', aggregates[3].get('FirstName'));
            Assert.areEqual(1, aggregates[3].get('Contacts'));
            Assert.areEqual('2', aggregates[4].get('LastName'));
            Assert.areEqual('AC', aggregates[4].get('FirstName'));
            Assert.areEqual(1, aggregates[4].get('Contacts'));
            Assert.areEqual('2', aggregates[5].get('LastName'));
            Assert.areEqual('BC', aggregates[5].get('FirstName'));
            Assert.areEqual(1, aggregates[5].get('Contacts'));
            Assert.areEqual('3', aggregates[6].get('LastName'));
            Assert.areEqual('AC', aggregates[6].get('FirstName'));
            Assert.areEqual(1, aggregates[6].get('Contacts'));

            aggregates = (List<AggregateResult>) QueryV1.of(Contact.SObjectType)
                    .security(AccessLevel.SYSTEM_MODE)
                    .returning(new Set<QueryV1.AggregatedField>{
                            QueryV1.aggregatedField(Contact.AccountId, Account.Name, 'AccountName'),
                            QueryV1.aggregatedField('COUNT', Contact.Id, 'Contacts')
                    })
                    .group(Contact.AccountId, new Set<SObjectField>{ Account.Name })
                    .ordered(QueryV1.ascending(Contact.AccountId, Account.Name))
                    .execute(OptionalV1.empty())
                    .get();

            Assert.areEqual(4, aggregates.size());
            Assert.areEqual('A', aggregates[0].get('AccountName'));
            Assert.areEqual(3, aggregates[0].get('Contacts'));
            Assert.areEqual('B', aggregates[1].get('AccountName'));
            Assert.areEqual(2, aggregates[1].get('Contacts'));
            Assert.areEqual('C', aggregates[2].get('AccountName'));
            Assert.areEqual(1, aggregates[2].get('Contacts'));
            Assert.areEqual('D', aggregates[3].get('AccountName'));
            Assert.areEqual(1, aggregates[3].get('Contacts'));

            aggregates = (List<AggregateResult>) QueryV1.of(Contact.SObjectType)
                    .security(AccessLevel.SYSTEM_MODE)
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

            Assert.areEqual(4, aggregates.size());
            Assert.areEqual('A', aggregates[0].get('AccountName'));
            Assert.areEqual('AC', aggregates[0].get('FirstName'));
            Assert.areEqual(3, aggregates[0].get('Contacts'));
            Assert.areEqual('B', aggregates[1].get('AccountName'));
            Assert.areEqual('BC', aggregates[1].get('FirstName'));
            Assert.areEqual(2, aggregates[1].get('Contacts'));
            Assert.areEqual('C', aggregates[2].get('AccountName'));
            Assert.areEqual('CC', aggregates[2].get('FirstName'));
            Assert.areEqual(1, aggregates[2].get('Contacts'));
            Assert.areEqual('D', aggregates[3].get('AccountName'));
            Assert.isNull(aggregates[3].get('FirstName'));
            Assert.areEqual(1, aggregates[3].get('Contacts'));

            aggregates = (List<AggregateResult>) QueryV1.of(Contact.SObjectType)
                    .security(AccessLevel.SYSTEM_MODE)
                    .returning(new Set<QueryV1.AggregatedField>{
                            QueryV1.aggregatedField(Contact.AccountId, 'SUM', Account.AnnualRevenue, 'Revenue'),
                            QueryV1.aggregatedField(Contact.FirstName, 'ContactFirstName')
                    })
                    .group(new Set<SObjectField> { Contact.FirstName })
                    .ordered(QueryV1.ascending(QueryV1.aggregatedField(Contact.AccountId, 'SUM', Account.AnnualRevenue, 'Revenue')))
                    .ordered(QueryV1.descending(QueryV1.aggregatedField(Contact.FirstName, 'ContactFirstName'), false))
                    .execute(OptionalV1.empty())
                    .get();

            Assert.areEqual(4, aggregates.size());
            Assert.areEqual(1500, aggregates[0].get('Revenue'));
            Assert.areEqual('CC', aggregates[0].get('ContactFirstName'));
            Assert.areEqual(2000, aggregates[1].get('Revenue'));
            Assert.areEqual('BC', aggregates[1].get('ContactFirstName'));
            Assert.areEqual(2000, aggregates[2].get('Revenue'));
            Assert.isNull(aggregates[2].get('ContactFirstName'));
            Assert.areEqual(3000, aggregates[3].get('Revenue'));
            Assert.areEqual('AC', aggregates[3].get('ContactFirstName'));

            try {
                QueryV1.of(Contact.SObjectType)
                        .security(AccessLevel.SYSTEM_MODE)
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
        TestHelper.setNOW();
        createData();
        System.runAs(TestHelper.getUser(TESTING)) {
            List<AggregateResult> aggregates = (List<AggregateResult>) QueryV1.of(Contact.SObjectType)
                    .security(AccessLevel.SYSTEM_MODE)
                    .returning(new Set<QueryV1.AggregatedField>{
                            QueryV1.aggregatedField(Contact.LastName, 'LastName'),
                            QueryV1.aggregatedField('COUNT', Contact.Id, 'Contacts')
                    })
                    .group(new Set<SObjectField>{ Contact.LastName })
                    .has('COUNT(Id) >= 1')
                    .ordered(QueryV1.ascending(Contact.LastName))
                    .execute(OptionalV1.empty())
                    .get();

            Assert.areEqual(3, aggregates.size());
            Assert.areEqual('1', aggregates[0].get('LastName'));
            Assert.areEqual(4, aggregates[0].get('Contacts'));
            Assert.areEqual('2', aggregates[1].get('LastName'));
            Assert.areEqual(2, aggregates[1].get('Contacts'));
            Assert.areEqual('3', aggregates[2].get('LastName'));
            Assert.areEqual(1, aggregates[2].get('Contacts'));

            aggregates = (List<AggregateResult>) QueryV1.of(Contact.SObjectType)
                    .security(AccessLevel.SYSTEM_MODE)
                    .returning(new Set<QueryV1.AggregatedField>{
                            QueryV1.aggregatedField(Contact.LastName, 'LastName'),
                            QueryV1.aggregatedField('COUNT', Contact.Id, 'Contacts')
                    })
                    .group(new Set<SObjectField>{ Contact.LastName })
                    .has('COUNT(Id) > 3')
                    .ordered(QueryV1.ascending(Contact.LastName))
                    .execute(OptionalV1.empty())
                    .get();

            Assert.areEqual(1, aggregates.size());
            Assert.areEqual('1', aggregates[0].get('LastName'));
            Assert.areEqual(4, aggregates[0].get('Contacts'));
        }
    }

    @IsTest
    @SuppressWarnings('PMD.NcssMethodCount')
    private static void testRelationshipQuery() {
        TestHelper.setNOW();
        createData();
        System.runAs(TestHelper.getUser(TESTING)) {
            List<Account> accounts = (List<Account>) QueryV1.of(Account.SObjectType)
                    .security(AccessLevel.SYSTEM_MODE)
                    .returning(new Set<SObjectField> { Account.Name })
                    .returning(
                            QueryV1.of(Contact.SObjectType)
                                    .returning(new Set<SObjectField> { Contact.FirstName, Contact.LastName })
                                    .ordered(new Set<QueryV1.Order> {
                                            QueryV1.ascending(Contact.LastName),
                                            QueryV1.ascending(Contact.FirstName)
                                    })
                    )
                    .returning(
                            QueryV1.of(Partner.SObjectType)
                                    .returning(new Set<SObjectField> { Partner.IsPrimary })
                                    .returning(Partner.AccountFromId, new Set<SObjectField> { Account.Name })
                                    .returning(Partner.AccountToId, new Set<SObjectField> { Account.Name })
                                    .ordered(new Set<QueryV1.Order> {
                                            QueryV1.ascending(Partner.AccountFromId, Account.Name, true),
                                            QueryV1.descending(Partner.AccountToId, Account.Name, false)
                                    })
                    )
                    .ordered(QueryV1.ascending(Account.Name))
                    .execute(OptionalV1.empty()).get();

            Assert.areEqual(4, accounts.size());
            Assert.areEqual('A', accounts[0].Name);
            Assert.areEqual('1', accounts[0].Contacts[0].LastName);
            Assert.areEqual('AC', accounts[0].Contacts[0].FirstName);
            Assert.areEqual('2', accounts[0].Contacts[1].LastName);
            Assert.areEqual('AC', accounts[0].Contacts[1].FirstName);
            Assert.areEqual('3', accounts[0].Contacts[2].LastName);
            Assert.areEqual('AC', accounts[0].Contacts[2].FirstName);
            Assert.areEqual('B', accounts[1].Name);
            Assert.areEqual('1', accounts[1].Contacts[0].LastName);
            Assert.areEqual('BC', accounts[1].Contacts[0].FirstName);
            Assert.areEqual('2', accounts[1].Contacts[1].LastName);
            Assert.areEqual('BC', accounts[1].Contacts[1].FirstName);
            Assert.areEqual('C', accounts[2].Name);
            Assert.areEqual('1', accounts[2].Contacts[0].LastName);
            Assert.areEqual('CC', accounts[2].Contacts[0].FirstName);
            Assert.areEqual('D', accounts[3].Name);
            Assert.areEqual('1', accounts[3].Contacts[0].LastName);
            Assert.isNull(accounts[3].Contacts[0].FirstName);

            accounts = (List<Account>) QueryV1.of(Account.SObjectType)
                    .security(AccessLevel.SYSTEM_MODE)
                    .returning(new Set<SObjectField> { Account.Name })
                    .returning(
                            QueryV1.of(Contact.SObjectType)
                                    .returning(new Set<SObjectField> { Contact.FirstName, Contact.LastName })
                                    .returning(Contact.AccountId, new Set<SObjectField> { Account.Name })
                                    .ordered(new Set<QueryV1.Order> {
                                            QueryV1.ascending(Contact.LastName),
                                            QueryV1.ascending(Contact.FirstName)
                                    })
                    )
                    .ordered(QueryV1.ascending(Account.Name))
                    .execute(OptionalV1.empty()).get();

            Assert.areEqual(4, accounts.size());
            Assert.areEqual('A', accounts[0].Name);
            Assert.areEqual('1', accounts[0].Contacts[0].LastName);
            Assert.areEqual('AC', accounts[0].Contacts[0].FirstName);
            Assert.areEqual('A', accounts[0].Contacts[0].Account.Name);
            Assert.areEqual('2', accounts[0].Contacts[1].LastName);
            Assert.areEqual('AC', accounts[0].Contacts[1].FirstName);
            Assert.areEqual('A', accounts[0].Contacts[1].Account.Name);
            Assert.areEqual('3', accounts[0].Contacts[2].LastName);
            Assert.areEqual('AC', accounts[0].Contacts[2].FirstName);
            Assert.areEqual('A', accounts[0].Contacts[2].Account.Name);
            Assert.areEqual('B', accounts[1].Name);
            Assert.areEqual('1', accounts[1].Contacts[0].LastName);
            Assert.areEqual('BC', accounts[1].Contacts[0].FirstName);
            Assert.areEqual('B', accounts[1].Contacts[0].Account.Name);
            Assert.areEqual('2', accounts[1].Contacts[1].LastName);
            Assert.areEqual('BC', accounts[1].Contacts[1].FirstName);
            Assert.areEqual('B', accounts[1].Contacts[1].Account.Name);
            Assert.areEqual('C', accounts[2].Name);
            Assert.areEqual('1', accounts[2].Contacts[0].LastName);
            Assert.areEqual('CC', accounts[2].Contacts[0].FirstName);
            Assert.areEqual('C', accounts[2].Contacts[0].Account.Name);
            Assert.areEqual('D', accounts[3].Name);
            Assert.areEqual('1', accounts[3].Contacts[0].LastName);
            Assert.isNull(accounts[3].Contacts[0].FirstName);
            Assert.areEqual('D', accounts[3].Contacts[0].Account.Name);

            try {
                QueryV1.of(Contact.SObjectType)
                        .security(AccessLevel.SYSTEM_MODE)
                        .returningAll()
                        .returning(QueryV1.of(Account.SObjectType).returningAll())
                        .execute(OptionalV1.empty());
                Assert.fail();
            } catch(QueryException qe) {
                Assert.areEqual('No relationship found to object Account', qe.getMessage());
            }
        }
    }

    @IsTest
    private static void testMax() {
        TestHelper.setNOW();
        createData();
        System.runAs(TestHelper.getUser(TESTING)) {
            List<Contact> contacts = (List<Contact>) QueryV1.of(Contact.SObjectType)
                    .security(AccessLevel.SYSTEM_MODE)
                    .returningAll()
                    .returning(Contact.AccountId, new Set<SObjectField>{
                            Account.Name
                    })
                    .ordered(new Set<QueryV1.Order>{
                            QueryV1.ascending(Contact.LastName),
                            QueryV1.ascending(Contact.FirstName)
                    })
                    .max(2)
                    .execute(OptionalV1.empty()).get();

            Assert.areEqual(2, contacts.size());
            Assert.areEqual('1', contacts[0].LastName);
            Assert.isNull(contacts[0].FirstName);
            Assert.areEqual('1', contacts[1].LastName);
            Assert.areEqual('AC', contacts[1].FirstName);

            contacts = (List<Contact>) QueryV1.of(Contact.SObjectType)
                    .security(AccessLevel.SYSTEM_MODE)
                    .returningAll()
                    .returning(Contact.AccountId, new Set<SObjectField>{
                            Account.Name
                    })
                    .ordered(new Set<QueryV1.Order>{
                            QueryV1.ascending(Contact.LastName),
                            QueryV1.ascending(Contact.FirstName)
                    })
                    .max(1)
                    .execute(OptionalV1.empty()).get();

            Assert.areEqual(1, contacts.size());
            Assert.areEqual('1', contacts[0].LastName);
            Assert.isNull(contacts[0].FirstName);
        }
    }

    @IsTest
    private static void testOffset() {
        TestHelper.setNOW();
        createData();
        System.runAs(TestHelper.getUser(TESTING)) {
            List<Contact> contacts = (List<Contact>) QueryV1.of(Contact.SObjectType)
                    .security(AccessLevel.SYSTEM_MODE)
                    .returning(new Set<SObjectField>{
                            Contact.FirstName, Contact.LastName
                    })
                    .ordered(new Set<QueryV1.Order>{
                            QueryV1.ascending(Contact.LastName),
                            QueryV1.ascending(Contact.FirstName)
                    })
                    .offset(1)
                    .execute(OptionalV1.empty()).get();

            Assert.areEqual(6, contacts.size());
            Assert.areEqual('1', contacts[0].LastName);
            Assert.areEqual('AC', contacts[0].FirstName);
            Assert.areEqual('1', contacts[1].LastName);
            Assert.areEqual('BC', contacts[1].FirstName);
            Assert.areEqual('1', contacts[2].LastName);
            Assert.areEqual('CC', contacts[2].FirstName);
            Assert.areEqual('2', contacts[3].LastName);
            Assert.areEqual('AC', contacts[3].FirstName);
            Assert.areEqual('2', contacts[4].LastName);
            Assert.areEqual('BC', contacts[4].FirstName);
            Assert.areEqual('3', contacts[5].LastName);
            Assert.areEqual('AC', contacts[5].FirstName);

            contacts = (List<Contact>) QueryV1.of(Contact.SObjectType)
                    .security(AccessLevel.SYSTEM_MODE)
                    .returning(new Set<SObjectField>{
                            Contact.FirstName, Contact.LastName
                    })
                    .ordered(new Set<QueryV1.Order>{
                            QueryV1.ascending(Contact.LastName),
                            QueryV1.ascending(Contact.FirstName)
                    })
                    .offset(5)
                    .execute(OptionalV1.empty()).get();

            Assert.areEqual(2, contacts.size());
            Assert.areEqual('2', contacts[0].LastName);
            Assert.areEqual('BC', contacts[0].FirstName);
            Assert.areEqual('3', contacts[1].LastName);
            Assert.areEqual('AC', contacts[1].FirstName);
        }
    }

    @IsTest
    private static void testJoin() {
        TestHelper.setNOW();
        createData();
        System.runAs(TestHelper.getUser(TESTING)) {
            List<Contact> contacts = (List<Contact>) QueryV1.of(Contact.SObjectType)
                    .security(AccessLevel.SYSTEM_MODE)
                    .returningAll()
                    .returning(Contact.AccountId, new Set<SObjectField> { Account.Name })
                    .ordered(new Set<QueryV1.Order>{
                            QueryV1.ascending(Contact.LastName),
                            QueryV1.ascending(Contact.FirstName)
                    })
                    .execute(OptionalV1.empty()).get();

            Assert.areEqual(7, contacts.size());
            Assert.areEqual('1', contacts[0].LastName);
            Assert.isNull(contacts[0].FirstName);
            Assert.areEqual('D', contacts[0].Account.Name);
            Assert.areEqual('1', contacts[1].LastName);
            Assert.areEqual('AC', contacts[1].FirstName);
            Assert.areEqual('A', contacts[1].Account.Name);
            Assert.areEqual('1', contacts[2].LastName);
            Assert.areEqual('BC', contacts[2].FirstName);
            Assert.areEqual('B', contacts[2].Account.Name);
            Assert.areEqual('1', contacts[3].LastName);
            Assert.areEqual('CC', contacts[3].FirstName);
            Assert.areEqual('C', contacts[3].Account.Name);
            Assert.areEqual('2', contacts[4].LastName);
            Assert.areEqual('AC', contacts[4].FirstName);
            Assert.areEqual('A', contacts[4].Account.Name);
            Assert.areEqual('2', contacts[5].LastName);
            Assert.areEqual('BC', contacts[5].FirstName);
            Assert.areEqual('B', contacts[5].Account.Name);
            Assert.areEqual('3', contacts[6].LastName);
            Assert.areEqual('AC', contacts[6].FirstName);
            Assert.areEqual('A', contacts[6].Account.Name);
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
        TestHelper.setNOW();
        createData();
        System.runAs(TestHelper.getUser(TESTING)) {
            Assert.areEqual(7, QueryV1.of(Contact.SObjectType).security(AccessLevel.SYSTEM_MODE).count().execute(OptionalV1.empty()).get());
            Assert.areEqual(
                    4,
                    QueryV1.of(Contact.SObjectType)
                            .security(AccessLevel.SYSTEM_MODE)
                            .count()
                            .matching('LastName = :lastName')
                            .execute(OptionalV1.of(new Map<String, Object> { 'lastName' => '1' }))
                            .get()
            );

            try {
                QueryV1.of(Contact.SObjectType).security(AccessLevel.SYSTEM_MODE).count().returningAll();
                Assert.fail();
            } catch (QueryException qe) {
                Assert.areEqual('Operation may not be performed on a count query', qe.getMessage());
            }

            try {
                QueryV1.of(Contact.SObjectType).security(AccessLevel.SYSTEM_MODE).count().returning(new Set<SObjectField>{ Contact.Name });
                Assert.fail();
            } catch (QueryException qe) {
                Assert.areEqual('Operation may not be performed on a count query', qe.getMessage());
            }

            try {
                QueryV1.of(Contact.SObjectType).security(AccessLevel.SYSTEM_MODE).count().returning(Contact.AccountId, new Set<SObjectField>{ Account.Name });
                Assert.fail();
            } catch (QueryException qe) {
                Assert.areEqual('Operation may not be performed on a count query', qe.getMessage());
            }

            try {
                QueryV1.of(Contact.SObjectType).security(AccessLevel.SYSTEM_MODE).count().returning(new Set<QueryV1.AggregatedField>{
                        QueryV1.aggregatedField(Contact.Name, 'ContactName')
                });
                Assert.fail();
            } catch (QueryException qe) {
                Assert.areEqual('Operation may not be performed on a count query', qe.getMessage());
            }
        }
    }

    @IsTest
    @SuppressWarnings('PMD.NcssMethodCount')
    private static void testDefaultOrder() {
        TestHelper.setNOW();
        createData();
        System.runAs(TestHelper.getUser(TESTING)) {
            List<Contact> contacts = (List<Contact>) QueryV1.of(Contact.SObjectType)
                    .security(AccessLevel.SYSTEM_MODE)
                    .returningAll()
                    .ordered(QueryV1.ascending(Contact.LastName))
                    .ordered(QueryV1.ascending(Contact.FirstName))
                    .execute(OptionalV1.empty())
                    .get();

            Assert.areEqual(7, contacts.size());
            Assert.areEqual('1', contacts[0].LastName);
            Assert.isNull(contacts[0].FirstName);
            Assert.areEqual('1', contacts[1].LastName);
            Assert.areEqual('AC', contacts[1].FirstName);
            Assert.areEqual('1', contacts[2].LastName);
            Assert.areEqual('BC', contacts[2].FirstName);
            Assert.areEqual('1', contacts[3].LastName);
            Assert.areEqual('CC', contacts[3].FirstName);
            Assert.areEqual('2', contacts[4].LastName);
            Assert.areEqual('AC', contacts[4].FirstName);
            Assert.areEqual('2', contacts[5].LastName);
            Assert.areEqual('BC', contacts[5].FirstName);
            Assert.areEqual('3', contacts[6].LastName);
            Assert.areEqual('AC', contacts[6].FirstName);

            contacts = (List<Contact>) QueryV1.of(Contact.SObjectType)
                    .security(AccessLevel.SYSTEM_MODE)
                    .returningAll()
                    .ordered(new Set<QueryV1.Order> {
                            QueryV1.ascending(Contact.LastName),
                            QueryV1.ascending(Contact.FirstName)
                    })
                    .execute(OptionalV1.empty())
                    .get();

            Assert.areEqual(7, contacts.size());
            Assert.areEqual('1', contacts[0].LastName);
            Assert.isNull(contacts[0].FirstName);
            Assert.areEqual('1', contacts[1].LastName);
            Assert.areEqual('AC', contacts[1].FirstName);
            Assert.areEqual('1', contacts[2].LastName);
            Assert.areEqual('BC', contacts[2].FirstName);
            Assert.areEqual('1', contacts[3].LastName);
            Assert.areEqual('CC', contacts[3].FirstName);
            Assert.areEqual('2', contacts[4].LastName);
            Assert.areEqual('AC', contacts[4].FirstName);
            Assert.areEqual('2', contacts[5].LastName);
            Assert.areEqual('BC', contacts[5].FirstName);
            Assert.areEqual('3', contacts[6].LastName);
            Assert.areEqual('AC', contacts[6].FirstName);

            contacts = (List<Contact>) QueryV1.of(Contact.SObjectType)
                    .security(AccessLevel.SYSTEM_MODE)
                    .returningAll()
                    .ordered(QueryV1.descending(Contact.LastName))
                    .ordered(QueryV1.descending(Contact.FirstName))
                    .execute(OptionalV1.empty())
                    .get();

            Assert.areEqual(7, contacts.size());
            Assert.areEqual('3', contacts[0].LastName);
            Assert.areEqual('AC', contacts[0].FirstName);
            Assert.areEqual('2', contacts[1].LastName);
            Assert.areEqual('BC', contacts[1].FirstName);
            Assert.areEqual('2', contacts[2].LastName);
            Assert.areEqual('AC', contacts[2].FirstName);
            Assert.areEqual('1', contacts[3].LastName);
            Assert.isNull(contacts[3].FirstName);
            Assert.areEqual('1', contacts[4].LastName);
            Assert.areEqual('CC', contacts[4].FirstName);
            Assert.areEqual('1', contacts[5].LastName);
            Assert.areEqual('BC', contacts[5].FirstName);
            Assert.areEqual('1', contacts[6].LastName);
            Assert.areEqual('AC', contacts[6].FirstName);

            contacts = (List<Contact>) QueryV1.of(Contact.SObjectType)
                    .security(AccessLevel.SYSTEM_MODE)
                    .returningAll()
                    .ordered(new Set<QueryV1.Order> {
                            QueryV1.descending(Contact.LastName),
                            QueryV1.descending(Contact.FirstName)
                    })
                    .execute(OptionalV1.empty())
                    .get();

            Assert.areEqual(7, contacts.size());
            Assert.areEqual('3', contacts[0].LastName);
            Assert.areEqual('AC', contacts[0].FirstName);
            Assert.areEqual('2', contacts[1].LastName);
            Assert.areEqual('BC', contacts[1].FirstName);
            Assert.areEqual('2', contacts[2].LastName);
            Assert.areEqual('AC', contacts[2].FirstName);
            Assert.areEqual('1', contacts[3].LastName);
            Assert.isNull(contacts[3].FirstName);
            Assert.areEqual('1', contacts[4].LastName);
            Assert.areEqual('CC', contacts[4].FirstName);
            Assert.areEqual('1', contacts[5].LastName);
            Assert.areEqual('BC', contacts[5].FirstName);
            Assert.areEqual('1', contacts[6].LastName);
            Assert.areEqual('AC', contacts[6].FirstName);

            contacts = (List<Contact>) QueryV1.of(Contact.SObjectType)
                    .security(AccessLevel.SYSTEM_MODE)
                    .returningAll()
                    .returning(Contact.AccountId, new Set<SObjectField> { Account.AccountNumber })
                    .ordered(QueryV1.ascending(Contact.AccountId, Account.AccountNumber))
                    .ordered(new Set<QueryV1.Order> {
                            QueryV1.ascending(Contact.LastName),
                            QueryV1.ascending(Contact.FirstName)
                    })
                    .execute(OptionalV1.empty())
                    .get();

            Assert.areEqual(7, contacts.size());
            Assert.isNull(contacts[0].Account.AccountNumber);
            Assert.areEqual('1', contacts[0].LastName);
            Assert.isNull(contacts[0].FirstName);
            Assert.areEqual('A1', contacts[1].Account.AccountNumber);
            Assert.areEqual('1', contacts[1].LastName);
            Assert.areEqual('AC', contacts[1].FirstName);
            Assert.areEqual('A1', contacts[2].Account.AccountNumber);
            Assert.areEqual('2', contacts[2].LastName);
            Assert.areEqual('AC', contacts[2].FirstName);
            Assert.areEqual('A1', contacts[3].Account.AccountNumber);
            Assert.areEqual('3', contacts[3].LastName);
            Assert.areEqual('AC', contacts[3].FirstName);
            Assert.areEqual('B1', contacts[4].Account.AccountNumber);
            Assert.areEqual('1', contacts[4].LastName);
            Assert.areEqual('BC', contacts[4].FirstName);
            Assert.areEqual('B1', contacts[5].Account.AccountNumber);
            Assert.areEqual('2', contacts[5].LastName);
            Assert.areEqual('BC', contacts[5].FirstName);
            Assert.areEqual('C1', contacts[6].Account.AccountNumber);
            Assert.areEqual('1', contacts[6].LastName);
            Assert.areEqual('CC', contacts[6].FirstName);

            contacts = (List<Contact>) QueryV1.of(Contact.SObjectType)
                    .security(AccessLevel.SYSTEM_MODE)
                    .returningAll()
                    .returning(Contact.AccountId, new Set<SObjectField> { Account.AccountNumber })
                    .ordered(QueryV1.descending(Contact.AccountId, Account.AccountNumber))
                    .ordered(new Set<QueryV1.Order> {
                            QueryV1.ascending(Contact.LastName),
                            QueryV1.ascending(Contact.FirstName)
                    })
                    .execute(OptionalV1.empty())
                    .get();

            Assert.areEqual(7, contacts.size());
            Assert.isNull(contacts[0].Account.AccountNumber);
            Assert.areEqual('1', contacts[0].LastName);
            Assert.isNull(contacts[0].FirstName);
            Assert.areEqual('C1', contacts[1].Account.AccountNumber);
            Assert.areEqual('1', contacts[1].LastName);
            Assert.areEqual('CC', contacts[1].FirstName);
            Assert.areEqual('B1', contacts[2].Account.AccountNumber);
            Assert.areEqual('1', contacts[2].LastName);
            Assert.areEqual('BC', contacts[2].FirstName);
            Assert.areEqual('B1', contacts[3].Account.AccountNumber);
            Assert.areEqual('2', contacts[3].LastName);
            Assert.areEqual('BC', contacts[3].FirstName);
            Assert.areEqual('A1', contacts[4].Account.AccountNumber);
            Assert.areEqual('1', contacts[4].LastName);
            Assert.areEqual('AC', contacts[4].FirstName);
            Assert.areEqual('A1', contacts[5].Account.AccountNumber);
            Assert.areEqual('2', contacts[5].LastName);
            Assert.areEqual('AC', contacts[5].FirstName);
            Assert.areEqual('A1', contacts[6].Account.AccountNumber);
            Assert.areEqual('3', contacts[6].LastName);
            Assert.areEqual('AC', contacts[6].FirstName);

            List<Account> accounts = (List<Account>) QueryV1.of(Account.SObjectType)
                    .security(AccessLevel.SYSTEM_MODE)
                    .returningAll()
                    .returning(
                            QueryV1.of(Contact.SObjectType)
                                    .returning(new Set<SObjectField> { Contact.LastName, Contact.FirstName })
                                    .ordered(new Set<QueryV1.Order> {
                                            QueryV1.ascending(Contact.LastName),
                                            QueryV1.ascending(Contact.FirstName)
                                    })
                    )
                    .ordered(QueryV1.ascending(Account.AccountNumber))
                    .execute(OptionalV1.empty())
                    .get();

            Assert.areEqual(4, accounts.size());
            Assert.isNull(accounts[0].AccountNumber);
            Assert.areEqual(1, accounts[0].Contacts.size());
            Assert.areEqual('1', accounts[0].Contacts[0].LastName);
            Assert.isNull(accounts[0].Contacts[0].FirstName);
            Assert.areEqual('A1', accounts[1].AccountNumber);
            Assert.areEqual(3, accounts[1].Contacts.size());
            Assert.areEqual('1', accounts[1].Contacts[0].LastName);
            Assert.areEqual('AC', accounts[1].Contacts[0].FirstName);
            Assert.areEqual('2', accounts[1].Contacts[1].LastName);
            Assert.areEqual('AC', accounts[1].Contacts[1].FirstName);
            Assert.areEqual('3', accounts[1].Contacts[2].LastName);
            Assert.areEqual('AC', accounts[1].Contacts[2].FirstName);
            Assert.areEqual('B1', accounts[2].AccountNumber);
            Assert.areEqual(2, accounts[2].Contacts.size());
            Assert.areEqual('1', accounts[2].Contacts[0].LastName);
            Assert.areEqual('BC', accounts[2].Contacts[0].FirstName);
            Assert.areEqual('2', accounts[2].Contacts[1].LastName);
            Assert.areEqual('BC', accounts[2].Contacts[1].FirstName);
            Assert.areEqual('C1', accounts[3].AccountNumber);
            Assert.areEqual(1, accounts[3].Contacts.size());
            Assert.areEqual('1', accounts[3].Contacts[0].LastName);
            Assert.areEqual('CC', accounts[3].Contacts[0].FirstName);

            accounts = (List<Account>) QueryV1.of(Account.SObjectType)
                    .security(AccessLevel.SYSTEM_MODE)
                    .returningAll()
                    .returning(
                            QueryV1.of(Contact.SObjectType)
                                    .returning(new Set<SObjectField> { Contact.LastName, Contact.FirstName })
                                    .ordered(new Set<QueryV1.Order> {
                                            QueryV1.descending(Contact.LastName),
                                            QueryV1.descending(Contact.FirstName)
                                    })
                    )
                    .ordered(QueryV1.descending(Account.AccountNumber))
                    .execute(OptionalV1.empty())
                    .get();

            Assert.areEqual(4, accounts.size());
            Assert.isNull(accounts[0].AccountNumber);
            Assert.areEqual(1, accounts[0].Contacts.size());
            Assert.areEqual('1', accounts[0].Contacts[0].LastName);
            Assert.isNull(accounts[0].Contacts[0].FirstName);
            Assert.areEqual('C1', accounts[1].AccountNumber);
            Assert.areEqual(1, accounts[1].Contacts.size());
            Assert.areEqual('1', accounts[1].Contacts[0].LastName);
            Assert.areEqual('CC', accounts[1].Contacts[0].FirstName);
            Assert.areEqual('B1', accounts[2].AccountNumber);
            Assert.areEqual(2, accounts[2].Contacts.size());
            Assert.areEqual('2', accounts[2].Contacts[0].LastName);
            Assert.areEqual('BC', accounts[2].Contacts[0].FirstName);
            Assert.areEqual('1', accounts[2].Contacts[1].LastName);
            Assert.areEqual('BC', accounts[2].Contacts[1].FirstName);
            Assert.areEqual('A1', accounts[3].AccountNumber);
            Assert.areEqual(3, accounts[3].Contacts.size());
            Assert.areEqual('3', accounts[3].Contacts[0].LastName);
            Assert.areEqual('AC', accounts[3].Contacts[0].FirstName);
            Assert.areEqual('2', accounts[3].Contacts[1].LastName);
            Assert.areEqual('AC', accounts[3].Contacts[1].FirstName);
            Assert.areEqual('1', accounts[3].Contacts[2].LastName);
            Assert.areEqual('AC', accounts[3].Contacts[2].FirstName);
        }
    }

    @IsTest
    @SuppressWarnings('PMD.NcssMethodCount')
    private static void testNullsFirstOrder() {
        TestHelper.setNOW();
        createData();
        System.runAs(TestHelper.getUser(TESTING)) {
            List<Contact> contacts = (List<Contact>) QueryV1.of(Contact.SObjectType)
                    .security(AccessLevel.SYSTEM_MODE)
                    .returningAll()
                    .ordered(QueryV1.ascending(Contact.LastName, true))
                    .ordered(QueryV1.ascending(Contact.FirstName, true))
                    .execute(OptionalV1.empty())
                    .get();

            Assert.areEqual(7, contacts.size());
            Assert.areEqual('1', contacts[0].LastName);
            Assert.isNull(contacts[0].FirstName);
            Assert.areEqual('1', contacts[1].LastName);
            Assert.areEqual('AC', contacts[1].FirstName);
            Assert.areEqual('1', contacts[2].LastName);
            Assert.areEqual('BC', contacts[2].FirstName);
            Assert.areEqual('1', contacts[3].LastName);
            Assert.areEqual('CC', contacts[3].FirstName);
            Assert.areEqual('2', contacts[4].LastName);
            Assert.areEqual('AC', contacts[4].FirstName);
            Assert.areEqual('2', contacts[5].LastName);
            Assert.areEqual('BC', contacts[5].FirstName);
            Assert.areEqual('3', contacts[6].LastName);
            Assert.areEqual('AC', contacts[6].FirstName);

            contacts = (List<Contact>) QueryV1.of(Contact.SObjectType)
                    .security(AccessLevel.SYSTEM_MODE)
                    .returningAll()
                    .ordered(new Set<QueryV1.Order> {
                            QueryV1.ascending(Contact.LastName, true),
                            QueryV1.ascending(Contact.FirstName, true)
                    })
                    .execute(OptionalV1.empty())
                    .get();

            Assert.areEqual(7, contacts.size());
            Assert.areEqual('1', contacts[0].LastName);
            Assert.isNull(contacts[0].FirstName);
            Assert.areEqual('1', contacts[1].LastName);
            Assert.areEqual('AC', contacts[1].FirstName);
            Assert.areEqual('1', contacts[2].LastName);
            Assert.areEqual('BC', contacts[2].FirstName);
            Assert.areEqual('1', contacts[3].LastName);
            Assert.areEqual('CC', contacts[3].FirstName);
            Assert.areEqual('2', contacts[4].LastName);
            Assert.areEqual('AC', contacts[4].FirstName);
            Assert.areEqual('2', contacts[5].LastName);
            Assert.areEqual('BC', contacts[5].FirstName);
            Assert.areEqual('3', contacts[6].LastName);
            Assert.areEqual('AC', contacts[6].FirstName);

            contacts = (List<Contact>) QueryV1.of(Contact.SObjectType)
                    .security(AccessLevel.SYSTEM_MODE)
                    .returningAll()
                    .ordered(QueryV1.descending(Contact.LastName, true))
                    .ordered(QueryV1.descending(Contact.FirstName, true))
                    .execute(OptionalV1.empty())
                    .get();

            Assert.areEqual(7, contacts.size());
            Assert.areEqual('3', contacts[0].LastName);
            Assert.areEqual('AC', contacts[0].FirstName);
            Assert.areEqual('2', contacts[1].LastName);
            Assert.areEqual('BC', contacts[1].FirstName);
            Assert.areEqual('2', contacts[2].LastName);
            Assert.areEqual('AC', contacts[2].FirstName);
            Assert.areEqual('1', contacts[3].LastName);
            Assert.isNull(contacts[3].FirstName);
            Assert.areEqual('1', contacts[4].LastName);
            Assert.areEqual('CC', contacts[4].FirstName);
            Assert.areEqual('1', contacts[5].LastName);
            Assert.areEqual('BC', contacts[5].FirstName);
            Assert.areEqual('1', contacts[6].LastName);
            Assert.areEqual('AC', contacts[6].FirstName);

            contacts = (List<Contact>) QueryV1.of(Contact.SObjectType)
                    .security(AccessLevel.SYSTEM_MODE)
                    .returningAll()
                    .ordered(new Set<QueryV1.Order> {
                            QueryV1.descending(Contact.LastName, true),
                            QueryV1.descending(Contact.FirstName, true)
                    })
                    .execute(OptionalV1.empty())
                    .get();

            Assert.areEqual(7, contacts.size());
            Assert.areEqual('3', contacts[0].LastName);
            Assert.areEqual('AC', contacts[0].FirstName);
            Assert.areEqual('2', contacts[1].LastName);
            Assert.areEqual('BC', contacts[1].FirstName);
            Assert.areEqual('2', contacts[2].LastName);
            Assert.areEqual('AC', contacts[2].FirstName);
            Assert.areEqual('1', contacts[3].LastName);
            Assert.isNull(contacts[3].FirstName);
            Assert.areEqual('1', contacts[4].LastName);
            Assert.areEqual('CC', contacts[4].FirstName);
            Assert.areEqual('1', contacts[5].LastName);
            Assert.areEqual('BC', contacts[5].FirstName);
            Assert.areEqual('1', contacts[6].LastName);
            Assert.areEqual('AC', contacts[6].FirstName);

            contacts = (List<Contact>) QueryV1.of(Contact.SObjectType)
                    .security(AccessLevel.SYSTEM_MODE)
                    .returningAll()
                    .returning(Contact.AccountId, new Set<SObjectField> { Account.AccountNumber })
                    .ordered(QueryV1.ascending(Contact.AccountId, Account.AccountNumber, true))
                    .ordered(new Set<QueryV1.Order> {
                            QueryV1.ascending(Contact.LastName, true),
                            QueryV1.ascending(Contact.FirstName, true)
                    })
                    .execute(OptionalV1.empty())
                    .get();

            Assert.areEqual(7, contacts.size());
            Assert.isNull(contacts[0].Account.AccountNumber);
            Assert.areEqual('1', contacts[0].LastName);
            Assert.isNull(contacts[0].FirstName);
            Assert.areEqual('A1', contacts[1].Account.AccountNumber);
            Assert.areEqual('1', contacts[1].LastName);
            Assert.areEqual('AC', contacts[1].FirstName);
            Assert.areEqual('A1', contacts[2].Account.AccountNumber);
            Assert.areEqual('2', contacts[2].LastName);
            Assert.areEqual('AC', contacts[2].FirstName);
            Assert.areEqual('A1', contacts[3].Account.AccountNumber);
            Assert.areEqual('3', contacts[3].LastName);
            Assert.areEqual('AC', contacts[3].FirstName);
            Assert.areEqual('B1', contacts[4].Account.AccountNumber);
            Assert.areEqual('1', contacts[4].LastName);
            Assert.areEqual('BC', contacts[4].FirstName);
            Assert.areEqual('B1', contacts[5].Account.AccountNumber);
            Assert.areEqual('2', contacts[5].LastName);
            Assert.areEqual('BC', contacts[5].FirstName);
            Assert.areEqual('C1', contacts[6].Account.AccountNumber);
            Assert.areEqual('1', contacts[6].LastName);
            Assert.areEqual('CC', contacts[6].FirstName);

            contacts = (List<Contact>) QueryV1.of(Contact.SObjectType)
                    .security(AccessLevel.SYSTEM_MODE)
                    .returningAll()
                    .returning(Contact.AccountId, new Set<SObjectField> { Account.AccountNumber })
                    .ordered(QueryV1.descending(Contact.AccountId, Account.AccountNumber, true))
                    .ordered(new Set<QueryV1.Order> {
                            QueryV1.ascending(Contact.LastName, true),
                            QueryV1.ascending(Contact.FirstName, true)
                    })
                    .execute(OptionalV1.empty())
                    .get();

            Assert.areEqual(7, contacts.size());
            Assert.isNull(contacts[0].Account.AccountNumber);
            Assert.areEqual('1', contacts[0].LastName);
            Assert.isNull(contacts[0].FirstName);
            Assert.areEqual('C1', contacts[1].Account.AccountNumber);
            Assert.areEqual('1', contacts[1].LastName);
            Assert.areEqual('CC', contacts[1].FirstName);
            Assert.areEqual('B1', contacts[2].Account.AccountNumber);
            Assert.areEqual('1', contacts[2].LastName);
            Assert.areEqual('BC', contacts[2].FirstName);
            Assert.areEqual('B1', contacts[3].Account.AccountNumber);
            Assert.areEqual('2', contacts[3].LastName);
            Assert.areEqual('BC', contacts[3].FirstName);
            Assert.areEqual('A1', contacts[4].Account.AccountNumber);
            Assert.areEqual('1', contacts[4].LastName);
            Assert.areEqual('AC', contacts[4].FirstName);
            Assert.areEqual('A1', contacts[5].Account.AccountNumber);
            Assert.areEqual('2', contacts[5].LastName);
            Assert.areEqual('AC', contacts[5].FirstName);
            Assert.areEqual('A1', contacts[6].Account.AccountNumber);
            Assert.areEqual('3', contacts[6].LastName);
            Assert.areEqual('AC', contacts[6].FirstName);

            List<Account> accounts = (List<Account>) QueryV1.of(Account.SObjectType)
                    .security(AccessLevel.SYSTEM_MODE)
                    .returningAll()
                    .returning(
                            QueryV1.of(Contact.SObjectType)
                                    .returning(new Set<SObjectField> { Contact.LastName, Contact.FirstName })
                                    .ordered(new Set<QueryV1.Order> {
                                            QueryV1.ascending(Contact.LastName, true),
                                            QueryV1.ascending(Contact.FirstName, true)
                                    })
                    )
                    .ordered(QueryV1.ascending(Account.AccountNumber, true))
                    .execute(OptionalV1.empty())
                    .get();

            Assert.areEqual(4, accounts.size());
            Assert.isNull(accounts[0].AccountNumber);
            Assert.areEqual(1, accounts[0].Contacts.size());
            Assert.areEqual('1', accounts[0].Contacts[0].LastName);
            Assert.isNull(accounts[0].Contacts[0].FirstName);
            Assert.areEqual('A1', accounts[1].AccountNumber);
            Assert.areEqual(3, accounts[1].Contacts.size());
            Assert.areEqual('1', accounts[1].Contacts[0].LastName);
            Assert.areEqual('AC', accounts[1].Contacts[0].FirstName);
            Assert.areEqual('2', accounts[1].Contacts[1].LastName);
            Assert.areEqual('AC', accounts[1].Contacts[1].FirstName);
            Assert.areEqual('3', accounts[1].Contacts[2].LastName);
            Assert.areEqual('AC', accounts[1].Contacts[2].FirstName);
            Assert.areEqual('B1', accounts[2].AccountNumber);
            Assert.areEqual(2, accounts[2].Contacts.size());
            Assert.areEqual('1', accounts[2].Contacts[0].LastName);
            Assert.areEqual('BC', accounts[2].Contacts[0].FirstName);
            Assert.areEqual('2', accounts[2].Contacts[1].LastName);
            Assert.areEqual('BC', accounts[2].Contacts[1].FirstName);
            Assert.areEqual('C1', accounts[3].AccountNumber);
            Assert.areEqual(1, accounts[3].Contacts.size());
            Assert.areEqual('1', accounts[3].Contacts[0].LastName);
            Assert.areEqual('CC', accounts[3].Contacts[0].FirstName);

            accounts = (List<Account>) QueryV1.of(Account.SObjectType)
                    .security(AccessLevel.SYSTEM_MODE)
                    .returningAll()
                    .returning(
                            QueryV1.of(Contact.SObjectType)
                                    .returning(new Set<SObjectField> { Contact.LastName, Contact.FirstName })
                                    .ordered(new Set<QueryV1.Order> {
                                            QueryV1.descending(Contact.LastName, true),
                                            QueryV1.descending(Contact.FirstName, true)
                                    })
                    )
                    .ordered(QueryV1.descending(Account.AccountNumber, true))
                    .execute(OptionalV1.empty())
                    .get();

            Assert.areEqual(4, accounts.size());
            Assert.isNull(accounts[0].AccountNumber);
            Assert.areEqual(1, accounts[0].Contacts.size());
            Assert.areEqual('1', accounts[0].Contacts[0].LastName);
            Assert.isNull(accounts[0].Contacts[0].FirstName);
            Assert.areEqual('C1', accounts[1].AccountNumber);
            Assert.areEqual(1, accounts[1].Contacts.size());
            Assert.areEqual('1', accounts[1].Contacts[0].LastName);
            Assert.areEqual('CC', accounts[1].Contacts[0].FirstName);
            Assert.areEqual('B1', accounts[2].AccountNumber);
            Assert.areEqual(2, accounts[2].Contacts.size());
            Assert.areEqual('2', accounts[2].Contacts[0].LastName);
            Assert.areEqual('BC', accounts[2].Contacts[0].FirstName);
            Assert.areEqual('1', accounts[2].Contacts[1].LastName);
            Assert.areEqual('BC', accounts[2].Contacts[1].FirstName);
            Assert.areEqual('A1', accounts[3].AccountNumber);
            Assert.areEqual(3, accounts[3].Contacts.size());
            Assert.areEqual('3', accounts[3].Contacts[0].LastName);
            Assert.areEqual('AC', accounts[3].Contacts[0].FirstName);
            Assert.areEqual('2', accounts[3].Contacts[1].LastName);
            Assert.areEqual('AC', accounts[3].Contacts[1].FirstName);
            Assert.areEqual('1', accounts[3].Contacts[2].LastName);
            Assert.areEqual('AC', accounts[3].Contacts[2].FirstName);
        }
    }

    @IsTest
    @SuppressWarnings('PMD.NcssMethodCount')
    private static void testNullsLastOrder() {
        TestHelper.setNOW();
        createData();
        System.runAs(TestHelper.getUser(TESTING)) {
            List<Contact> contacts = (List<Contact>) QueryV1.of(Contact.SObjectType)
                    .security(AccessLevel.SYSTEM_MODE)
                    .returningAll()
                    .ordered(QueryV1.ascending(Contact.LastName, false))
                    .ordered(QueryV1.ascending(Contact.FirstName, false))
                    .execute(OptionalV1.empty())
                    .get();

            Assert.areEqual(7, contacts.size());
            Assert.areEqual('1', contacts[0].LastName);
            Assert.areEqual('AC', contacts[0].FirstName);
            Assert.areEqual('1', contacts[1].LastName);
            Assert.areEqual('BC', contacts[1].FirstName);
            Assert.areEqual('1', contacts[2].LastName);
            Assert.areEqual('CC', contacts[2].FirstName);
            Assert.areEqual('1', contacts[3].LastName);
            Assert.isNull(contacts[3].FirstName);
            Assert.areEqual('2', contacts[4].LastName);
            Assert.areEqual('AC', contacts[4].FirstName);
            Assert.areEqual('2', contacts[5].LastName);
            Assert.areEqual('BC', contacts[5].FirstName);
            Assert.areEqual('3', contacts[6].LastName);
            Assert.areEqual('AC', contacts[6].FirstName);

            contacts = (List<Contact>) QueryV1.of(Contact.SObjectType)
                    .security(AccessLevel.SYSTEM_MODE)
                    .returningAll()
                    .ordered(new Set<QueryV1.Order> {
                            QueryV1.ascending(Contact.LastName, false),
                            QueryV1.ascending(Contact.FirstName, false)
                    })
                    .execute(OptionalV1.empty())
                    .get();

            Assert.areEqual(7, contacts.size());
            Assert.areEqual('1', contacts[0].LastName);
            Assert.areEqual('AC', contacts[0].FirstName);
            Assert.areEqual('1', contacts[1].LastName);
            Assert.areEqual('BC', contacts[1].FirstName);
            Assert.areEqual('1', contacts[2].LastName);
            Assert.areEqual('CC', contacts[2].FirstName);
            Assert.areEqual('1', contacts[3].LastName);
            Assert.isNull(contacts[3].FirstName);
            Assert.areEqual('2', contacts[4].LastName);
            Assert.areEqual('AC', contacts[4].FirstName);
            Assert.areEqual('2', contacts[5].LastName);
            Assert.areEqual('BC', contacts[5].FirstName);
            Assert.areEqual('3', contacts[6].LastName);
            Assert.areEqual('AC', contacts[6].FirstName);

            contacts = (List<Contact>) QueryV1.of(Contact.SObjectType)
                    .security(AccessLevel.SYSTEM_MODE)
                    .returningAll()
                    .ordered(QueryV1.descending(Contact.LastName, false))
                    .ordered(QueryV1.descending(Contact.FirstName, false))
                    .execute(OptionalV1.empty())
                    .get();

            Assert.areEqual(7, contacts.size());
            Assert.areEqual('3', contacts[0].LastName);
            Assert.areEqual('AC', contacts[0].FirstName);
            Assert.areEqual('2', contacts[1].LastName);
            Assert.areEqual('BC', contacts[1].FirstName);
            Assert.areEqual('2', contacts[2].LastName);
            Assert.areEqual('AC', contacts[2].FirstName);
            Assert.areEqual('1', contacts[3].LastName);
            Assert.areEqual('CC', contacts[3].FirstName);
            Assert.areEqual('1', contacts[4].LastName);
            Assert.areEqual('BC', contacts[4].FirstName);
            Assert.areEqual('1', contacts[5].LastName);
            Assert.areEqual('AC', contacts[5].FirstName);
            Assert.areEqual('1', contacts[6].LastName);
            Assert.isNull(contacts[6].FirstName);

            contacts = (List<Contact>) QueryV1.of(Contact.SObjectType)
                    .security(AccessLevel.SYSTEM_MODE)
                    .returningAll()
                    .ordered(new Set<QueryV1.Order> {
                            QueryV1.descending(Contact.LastName, false),
                            QueryV1.descending(Contact.FirstName, false)
                    })
                    .execute(OptionalV1.empty())
                    .get();

            Assert.areEqual(7, contacts.size());
            Assert.areEqual('3', contacts[0].LastName);
            Assert.areEqual('AC', contacts[0].FirstName);
            Assert.areEqual('2', contacts[1].LastName);
            Assert.areEqual('BC', contacts[1].FirstName);
            Assert.areEqual('2', contacts[2].LastName);
            Assert.areEqual('AC', contacts[2].FirstName);
            Assert.areEqual('1', contacts[3].LastName);
            Assert.areEqual('CC', contacts[3].FirstName);
            Assert.areEqual('1', contacts[4].LastName);
            Assert.areEqual('BC', contacts[4].FirstName);
            Assert.areEqual('1', contacts[5].LastName);
            Assert.areEqual('AC', contacts[5].FirstName);
            Assert.areEqual('1', contacts[6].LastName);
            Assert.isNull(contacts[6].FirstName);

            contacts = (List<Contact>) QueryV1.of(Contact.SObjectType)
                    .security(AccessLevel.SYSTEM_MODE)
                    .returningAll()
                    .returning(Contact.AccountId, new Set<SObjectField> { Account.AccountNumber })
                    .ordered(QueryV1.ascending(Contact.AccountId, Account.AccountNumber, false))
                    .ordered(new Set<QueryV1.Order> {
                            QueryV1.ascending(Contact.LastName, false),
                            QueryV1.ascending(Contact.FirstName, false)
                    })
                    .execute(OptionalV1.empty())
                    .get();

            Assert.areEqual(7, contacts.size());
            Assert.areEqual('A1', contacts[0].Account.AccountNumber);
            Assert.areEqual('1', contacts[0].LastName);
            Assert.areEqual('AC', contacts[0].FirstName);
            Assert.areEqual('A1', contacts[1].Account.AccountNumber);
            Assert.areEqual('2', contacts[1].LastName);
            Assert.areEqual('AC', contacts[1].FirstName);
            Assert.areEqual('A1', contacts[2].Account.AccountNumber);
            Assert.areEqual('3', contacts[2].LastName);
            Assert.areEqual('AC', contacts[2].FirstName);
            Assert.areEqual('B1', contacts[3].Account.AccountNumber);
            Assert.areEqual('1', contacts[3].LastName);
            Assert.areEqual('BC', contacts[3].FirstName);
            Assert.areEqual('B1', contacts[4].Account.AccountNumber);
            Assert.areEqual('2', contacts[4].LastName);
            Assert.areEqual('BC', contacts[4].FirstName);
            Assert.areEqual('C1', contacts[5].Account.AccountNumber);
            Assert.areEqual('1', contacts[5].LastName);
            Assert.areEqual('CC', contacts[5].FirstName);
            Assert.isNull(contacts[6].Account.AccountNumber);
            Assert.areEqual('1', contacts[6].LastName);
            Assert.isNull(contacts[6].FirstName);

            contacts = (List<Contact>) QueryV1.of(Contact.SObjectType)
                    .security(AccessLevel.SYSTEM_MODE)
                    .returningAll()
                    .returning(Contact.AccountId, new Set<SObjectField> { Account.AccountNumber })
                    .ordered(QueryV1.descending(Contact.AccountId, Account.AccountNumber, false))
                    .ordered(new Set<QueryV1.Order> {
                            QueryV1.ascending(Contact.LastName, false),
                            QueryV1.ascending(Contact.FirstName, false)
                    })
                    .execute(OptionalV1.empty())
                    .get();

            Assert.areEqual(7, contacts.size());
            Assert.areEqual('C1', contacts[0].Account.AccountNumber);
            Assert.areEqual('1', contacts[0].LastName);
            Assert.areEqual('CC', contacts[0].FirstName);
            Assert.areEqual('B1', contacts[1].Account.AccountNumber);
            Assert.areEqual('1', contacts[1].LastName);
            Assert.areEqual('BC', contacts[1].FirstName);
            Assert.areEqual('B1', contacts[2].Account.AccountNumber);
            Assert.areEqual('2', contacts[2].LastName);
            Assert.areEqual('BC', contacts[2].FirstName);
            Assert.areEqual('A1', contacts[3].Account.AccountNumber);
            Assert.areEqual('1', contacts[3].LastName);
            Assert.areEqual('AC', contacts[3].FirstName);
            Assert.areEqual('A1', contacts[4].Account.AccountNumber);
            Assert.areEqual('2', contacts[4].LastName);
            Assert.areEqual('AC', contacts[4].FirstName);
            Assert.areEqual('A1', contacts[5].Account.AccountNumber);
            Assert.areEqual('3', contacts[5].LastName);
            Assert.areEqual('AC', contacts[5].FirstName);
            Assert.isNull(contacts[6].Account.AccountNumber);
            Assert.areEqual('1', contacts[6].LastName);
            Assert.isNull(contacts[6].FirstName);

            List<Account> accounts = (List<Account>) QueryV1.of(Account.SObjectType)
                    .security(AccessLevel.SYSTEM_MODE)
                    .returningAll()
                    .returning(
                            QueryV1.of(Contact.SObjectType)
                                    .returning(new Set<SObjectField> { Contact.LastName, Contact.FirstName })
                                    .ordered(new Set<QueryV1.Order> {
                                            QueryV1.ascending(Contact.LastName, false),
                                            QueryV1.ascending(Contact.FirstName, false)
                                    })
                    )
                    .ordered(QueryV1.ascending(Account.AccountNumber, false))
                    .execute(OptionalV1.empty())
                    .get();

            Assert.areEqual(4, accounts.size());
            Assert.areEqual('A1', accounts[0].AccountNumber);
            Assert.areEqual(3, accounts[0].Contacts.size());
            Assert.areEqual('1', accounts[0].Contacts[0].LastName);
            Assert.areEqual('AC', accounts[0].Contacts[0].FirstName);
            Assert.areEqual('2', accounts[0].Contacts[1].LastName);
            Assert.areEqual('AC', accounts[0].Contacts[1].FirstName);
            Assert.areEqual('3', accounts[0].Contacts[2].LastName);
            Assert.areEqual('AC', accounts[0].Contacts[2].FirstName);
            Assert.areEqual('B1', accounts[1].AccountNumber);
            Assert.areEqual(2, accounts[1].Contacts.size());
            Assert.areEqual('1', accounts[1].Contacts[0].LastName);
            Assert.areEqual('BC', accounts[1].Contacts[0].FirstName);
            Assert.areEqual('2', accounts[1].Contacts[1].LastName);
            Assert.areEqual('BC', accounts[1].Contacts[1].FirstName);
            Assert.areEqual('C1', accounts[2].AccountNumber);
            Assert.areEqual(1, accounts[2].Contacts.size());
            Assert.areEqual('1', accounts[2].Contacts[0].LastName);
            Assert.areEqual('CC', accounts[2].Contacts[0].FirstName);
            Assert.isNull(accounts[3].AccountNumber);
            Assert.areEqual(1, accounts[3].Contacts.size());
            Assert.areEqual('1', accounts[3].Contacts[0].LastName);
            Assert.isNull(accounts[3].Contacts[0].FirstName);

            accounts = (List<Account>) QueryV1.of(Account.SObjectType)
                    .security(AccessLevel.SYSTEM_MODE)
                    .returningAll()
                    .returning(
                            QueryV1.of(Contact.SObjectType)
                                    .returning(new Set<SObjectField> { Contact.LastName, Contact.FirstName })
                                    .ordered(new Set<QueryV1.Order> {
                                            QueryV1.descending(Contact.LastName, false),
                                            QueryV1.descending(Contact.FirstName, false)
                                    })
                    )
                    .ordered(QueryV1.descending(Account.AccountNumber, false))
                    .execute(OptionalV1.empty())
                    .get();

            Assert.areEqual(4, accounts.size());
            Assert.areEqual('C1', accounts[0].AccountNumber);
            Assert.areEqual(1, accounts[0].Contacts.size());
            Assert.areEqual('1', accounts[0].Contacts[0].LastName);
            Assert.areEqual('CC', accounts[0].Contacts[0].FirstName);
            Assert.areEqual('B1', accounts[1].AccountNumber);
            Assert.areEqual(2, accounts[1].Contacts.size());
            Assert.areEqual('2', accounts[1].Contacts[0].LastName);
            Assert.areEqual('BC', accounts[1].Contacts[0].FirstName);
            Assert.areEqual('1', accounts[1].Contacts[1].LastName);
            Assert.areEqual('BC', accounts[1].Contacts[1].FirstName);
            Assert.areEqual('A1', accounts[2].AccountNumber);
            Assert.areEqual(3, accounts[2].Contacts.size());
            Assert.areEqual('3', accounts[2].Contacts[0].LastName);
            Assert.areEqual('AC', accounts[2].Contacts[0].FirstName);
            Assert.areEqual('2', accounts[2].Contacts[1].LastName);
            Assert.areEqual('AC', accounts[2].Contacts[1].FirstName);
            Assert.areEqual('1', accounts[2].Contacts[2].LastName);
            Assert.areEqual('AC', accounts[2].Contacts[2].FirstName);
            Assert.isNull(accounts[3].AccountNumber);
            Assert.areEqual(1, accounts[3].Contacts.size());
            Assert.areEqual('1', accounts[3].Contacts[0].LastName);
            Assert.isNull(accounts[3].Contacts[0].FirstName);
        }
    }

    private static void createData() {
        Account a = new Account(Name = 'A', AccountNumber = 'A1', AnnualRevenue = 1000);
        Account b = new Account(Name = 'B', AccountNumber = 'B1', AnnualRevenue = 1000);
        Account c = new Account(Name = 'C', AccountNumber = 'C1', AnnualRevenue = 1500);
        Account d = new Account(Name = 'D', AnnualRevenue = 2000);

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