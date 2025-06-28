/**
 * MIT License
 *
 * Copyright (c) 2025 Mark Brennand
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */
/**
 * @description
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

        public override void run(Asynchronous.Job asyncJob, String apexJobId) {}
    }
}
