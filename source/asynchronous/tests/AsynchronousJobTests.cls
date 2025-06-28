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
 * Unit test for the AsynchronousJob class.
 *
 * As Assert throws an Exception which cannot be caught, valid values must be supplied for the fields.
 *
 * @author Mark Brennand
 */
@IsTest
public with sharing class AsynchronousJobTests {

    @TestSetup
    private static void setup() {
        AsynchronousTestHelper.createUsers();
    }

    @IsTest
    static void testAllStatuses() {
        System.runAs(AsynchronousTestHelper.getUser()) {
            for (Asynchronous.Status status : Asynchronous.Status.values()) {
                AsynchronousJob__c asynchronous = new AsynchronousJob__c(
                        OwnerId = UserInfo.getUserId(),
                        Status__c = status.name(),
                        Runnable__c = AsynchronousJobTests.Runnable.class.getName(),
                        Reference__c = 'Test',
                        MaximumRetries__c = 1,
                        RetryInterval__c = 1000,
                        RetryNumber__c = 0,
                        ScheduledRunTime__c = Datetime.now()
                );
                AsynchronousJob.fromSObject(asynchronous);
            }
        }
    }

    @IsTest
    private static void testMandatoryFields() {
        System.runAs(AsynchronousTestHelper.getUser()) {
            AsynchronousJob__c asyncObject = new AsynchronousJob__c(
                    OwnerId = UserInfo.getUserId(),
                    Status__c = Asynchronous.Status.PENDING.name(),
                    Runnable__c = AsynchronousJobTests.Runnable.class.getName(),
                    MaximumRetries__c = 0,
                    RetryNumber__c = 0,
                    RetryInterval__c = 0,
                    ScheduledRunTime__c = Datetime.now()
            );

            try {
                AsynchronousJob__c copyObject = asyncObject.clone();
                copyObject.OwnerId = null;
                AsynchronousJob.fromSObject(copyObject);
                Assert.fail();

            } catch (Assertion.AssertionException ae) {
            }

            try {
                AsynchronousJob__c copyObject = asyncObject.clone();
                copyObject.Status__c = null;
                AsynchronousJob.fromSObject(copyObject);
                Assert.fail();
            } catch (Assertion.AssertionException ae) {
            }

            try {
                AsynchronousJob__c copyObject = asyncObject.clone();
                copyObject.Runnable__c = null;
                AsynchronousJob.fromSObject(copyObject);
                Assert.fail();
            } catch (Assertion.AssertionException ae) {
            }

            try {
                AsynchronousJob__c copyObject = asyncObject.clone();
                copyObject.MaximumRetries__c = null;
                AsynchronousJob.fromSObject(copyObject);
                Assert.fail();
            } catch (Assertion.AssertionException ae) {
            }

            try {
                AsynchronousJob__c copyObject = asyncObject.clone();
                copyObject.RetryNumber__c = null;
                AsynchronousJob.fromSObject(copyObject);
                Assert.fail();
            } catch (Assertion.AssertionException ae) {
            }

            try {
                AsynchronousJob__c copyObject = asyncObject.clone();
                copyObject.RetryInterval__c = null;
                AsynchronousJob.fromSObject(copyObject);
                Assert.fail();
            } catch (Assertion.AssertionException ae) {
            }

            try {
                AsynchronousJob__c copyObject = asyncObject.clone();
                copyObject.ScheduledRunTime__c = null;
                AsynchronousJob.fromSObject(copyObject);
                Assert.fail();
            } catch (Assertion.AssertionException ae) {
            }
        }
    }

    @IsTest
    static void testOptionalFields() {
        System.runAs(AsynchronousTestHelper.getUser()) {
            AsynchronousJob__c asynchronous = new AsynchronousJob__c(
                    OwnerId = UserInfo.getUserId(),
                    Status__c = Asynchronous.Status.PENDING.name(),
                    Runnable__c = 'AsynchronousJobTests.Runnable',
                    Reference__c = 'Test',
                    MaximumRetries__c = 1,
                    RetryInterval__c = 1000,
                    RetryNumber__c = 0,
                    ScheduledRunTime__c = Datetime.now()
            );
            AsynchronousJob.fromSObject(asynchronous);

            asynchronous.Reference__c = 'Test';
            AsynchronousJob.fromSObject(asynchronous);

            asynchronous.LastRunTime__c = Datetime.now();
            AsynchronousJob.fromSObject(asynchronous);
        }
    }

    @IsTest
    private static void testFromSObject() {
        System.runAs(AsynchronousTestHelper.getUser()) {
            try {
                AsynchronousJob.fromSObject(null);
                Assert.fail();
            } catch (Assertion.AssertionException ae) {
            }

            Datetime now = Datetime.now();
            AsynchronousJob__c asyncObject = new AsynchronousJob__c(
                    Id = MockerV1.fakeId(AsynchronousJob__c.SObjectType),
                    OwnerId = UserInfo.getUserId(),
                    Status__c = Asynchronous.Status.PENDING.name(),
                    Runnable__c = AsynchronousJobTests.Runnable.class.getName(),
                    Reference__c = 'Test',
                    MaximumRetries__c = 1,
                    RetryInterval__c = 1000,
                    RetryNumber__c = 0,
                    ScheduledRunTime__c = now.addMinutes(1),
                    LastRunTime__c = now
            );

            Asynchronous.Job job = AsynchronousJob.fromSObject(asyncObject);
            Assert.areEqual(UserInfo.getUserId(), job.getOwnerId());
            Assert.areEqual(Asynchronous.Status.PENDING, job.getStatus());
            Assert.isTrue(job.getRunnable() instanceof AsynchronousJobTests.Runnable);
            Assert.areEqual('Test', job.getReference());
            Assert.areEqual(1, job.getMaximumRetries());
            Assert.areEqual(1000, job.getRetryInterval());
            Assert.areEqual(0, job.getRetryNumber());
            Assert.areEqual(now.addMinutes(1), job.getScheduledRunTime());
            Assert.areEqual(now, job.getLastRunTime());
        }
    }

    public with sharing class Runnable extends AsynchronousV1.Runnable {
        public Runnable() {
            super(Runnable.class);
        }

        public override void run(Asynchronous.Job job, String apexJobId) {}
    }
}
