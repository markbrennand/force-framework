/**
 * @description
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../../LICENSE target="_blank">MIT License</a>.
 * <br><br>
 * Helper methods for Asynchronous unit tests.
 *
 * @author Mark Brennand
 */
@IsTest
public with sharing class AsynchronousTestHelper {

    @TestVisible
    private static void createUsers() {
        final Id profileId = [SELECT Id FROM Profile WHERE Name = 'Minimum Access - Salesforce' LIMIT 1].Id;

        User user = new User(
                Alias = 'user',
                ProfileId = profileId,
                Username = 'user@asynchronous.force-fw.test.com',
                Email = 'user@asynchronous.force-fw.test.com',
                EmailEncodingKey = 'ISO-8859-1',
                TimeZoneSidKey = 'Europe/London',
                LocaleSidKey = 'en_US',
                LanguageLocaleKey = 'en_US',
                FirstName = 'Asynchronous',
                LastName = 'User'
        );

        insert new List<User> { user };

        Id bindingPermSetId = [SELECT Id FROM PermissionSet WHERE Name = 'ForceFwDependencyInjectionPermissions' LIMIT 1].Id;
        Id asyncPermSetId = [SELECT Id FROM PermissionSet WHERE Name = 'ForceFwAsynchronousPermissions' LIMIT 1].Id;
        delete [SELECT Id FROM PermissionSetAssignment WHERE AssigneeId = :user.Id AND PermissionSetId IN (:asyncPermSetId, :bindingPermSetId)];

        PermissionSetAssignment bindingAssignment = new PermissionSetAssignment(
                AssigneeId = user.Id,
                PermissionSetId = bindingPermSetId
        );

        PermissionSetAssignment asyncAssignment = new PermissionSetAssignment(
                AssigneeId = user.Id,
                PermissionSetId = asyncPermSetId
        );

        insert new List<PermissionSetAssignment> { asyncAssignment, bindingAssignment };
    }

    public static User getUser() {
        return [SELECT Id FROM User WHERE Username = 'user@asynchronous.force-fw.test.com' LIMIT 1];
    }

    public with sharing class TestRunnable extends AsynchronousV1.Runnable {
        public TestRunnable() {
            super(TestRunnable.class);
        }

        public override void run(AsynchronousV1.Job asyncJob, String apexJobId) {}
    }
}
