/**
 * @description
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../LICENSE target="_blank">MIT License</a>.
 * <br><br>
 * Common test data and methods for all unit tests.
 *
 * @author Mark Brennand
 */
@IsTest
@SuppressWarnings('PMD')
public with sharing class TestHelper {

    @TestVisible
    private static void createUsers(final String component, final Set<String> userPermissionSets) {
        final Id profileId = [SELECT Id FROM Profile WHERE Name = 'Minimum Access - Salesforce' LIMIT 1].Id;

        final String managerName = buildUsername('manager', component);
        final String userName = buildUsername('user', component);

        User manager = new User(
                Alias = 'manager',
                ProfileId = profileId,
                Username = managerName,
                Email = userName,
                EmailEncodingKey = 'ISO-8859-1',
                TimeZoneSidKey = 'Europe/London',
                LocaleSidKey = 'en_US',
                LanguageLocaleKey = 'en_US',
                FirstName = component,
                LastName = 'manager'
        );

        User user = new User(
                Alias = 'user',
                ProfileId = profileId,
                Username = userName,
                Email = managerName,
                EmailEncodingKey = 'ISO-8859-1',
                TimeZoneSidKey = 'Europe/London',
                LocaleSidKey = 'en_US',
                LanguageLocaleKey = 'en_US',
                FirstName = component,
                LastName = 'user'
        );

        insert new List<User> { manager, user };

        final Set<Id> permissionSetIds = new Set<Id>();
        for (String userPermissionSet : userPermissionSets) {
            permissionSetIds.add([SELECT Id FROM PermissionSet WHERE Name = :userPermissionSet].Id);
        }

        Id managerPermSetId = [SELECT Id FROM PermissionSet WHERE Name = 'ForceFwManager' LIMIT 1].Id;
        delete [SELECT Id FROM PermissionSetAssignment WHERE AssigneeId = :manager.Id AND PermissionSetId = :managerPermSetId];
        delete [SELECT Id FROM PermissionSetAssignment WHERE AssigneeId = :user.Id AND PermissionSetId IN :permissionSetIds];

        List<PermissionSetAssignment> assignments = new List<PermissionSetAssignment> {
                new PermissionSetAssignment(
                        AssigneeId = manager.Id,
                        PermissionSetId = managerPermSetId
                )
        };

        for (Id permissionSetId : permissionSetIds) {
            assignments.add(new PermissionSetAssignment(
                    AssigneeId = user.Id,
                    PermissionSetId = permissionSetId
            ));
        }

        insert assignments;
    }

    @TestVisible
    private static User getManager(final String component) {
        final String name = buildUsername('manager', component);
        return [SELECT Id FROM User WHERE Username = :name LIMIT 1];
    }

    @TestVisible
    private static User getUser(final String component) {
        final String name = buildUsername('user', component);
        return [SELECT Id FROM User WHERE Username = :name LIMIT 1];
    }

    @TestVisible
    private with sharing class ExceptionComparator implements Comparator<Object> {
        public Integer compare(final Object param1, final Object param2) {
            return param1 instanceof Exception
                    && param2 instanceof Exception
                    && ((Exception) param1).getMessage() == ((Exception) param2).getMessage()
                    && ((Exception) param1).getCause()?.getTypeName() == ((Exception) param2).getCause()?.getTypeName()
                    && ((Exception) param1).getCause()?.getMessage() == ((Exception) param2).getCause()?.getMessage()
                    ? 0 : -1;
        }
    }

    @TestVisible
    private static void setNOW() {
        CommonHelper.NOW = Datetime.newInstance(2025, 1, 1, 1, 0 ,0);
    }


    @TestVisible
    private static Boolean textContains(final String expected, final String text) {
        return text.replace(CommonHelper.getApexNamespace(), '').contains(expected);

    }

    @TestVisible
    private static Boolean exceptionContains(final String expectedMessage, final Exception exc) {
        return textContains(expectedMessage, exc.getMessage());
    }

    private static String buildUsername(final String prefix, final String component) {
        return prefix + '@' + component + '.test.forecefw.com';
    }
}