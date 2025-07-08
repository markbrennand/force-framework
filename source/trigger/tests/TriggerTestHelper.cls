/**
 * @description
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../../LICENSE target="_blank">MIT License</a>.
 * <br><br>
 * Helper methods for Trigger API unit tests.
 *
 * @author Mark Brennand
 */
@IsTest
public with sharing class TriggerTestHelper {

    @TestVisible
    private static void createUsers() {
        final Id profileId = [SELECT Id FROM Profile WHERE Name = 'Minimum Access - Salesforce' LIMIT 1].Id;

        User user = new User(
                Alias = 'user',
                ProfileId = profileId,
                Username = 'user@trigger.force-fw.test.com',
                Email = 'user@trigger.force-fw.test.com',
                EmailEncodingKey = 'ISO-8859-1',
                TimeZoneSidKey = 'Europe/London',
                LocaleSidKey = 'en_US',
                LanguageLocaleKey = 'en_US',
                FirstName = 'Trigger',
                LastName = 'User'
        );

        insert new List<User> { user };

        Id managerPermSetId = [SELECT Id FROM PermissionSet WHERE Name = 'ForceFwManager' LIMIT 1].Id;
        delete [SELECT Id FROM PermissionSetAssignment WHERE AssigneeId = :user.Id AND PermissionSetId = :managerPermSetId];

        PermissionSetAssignment managerAssignment = new PermissionSetAssignment(
                AssigneeId = user.Id,
                PermissionSetId = managerPermSetId
        );

        insert managerAssignment;
    }

    public static User getUser() {
        return [SELECT Id FROM User WHERE Username = 'user@trigger.force-fw.test.com' LIMIT 1];
    }
}
