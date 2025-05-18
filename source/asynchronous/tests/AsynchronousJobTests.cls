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

    @IsTest
    static void testAllStatuses() {
        for (Asynchronous.Status status : Asynchronous.Status.values()) {
            Asynchronous__c asynchronous = new Asynchronous__c(
                    OwnerId = UserInfo.getUserId(),
                    Status__c = status.name(),
                    Runnable__c = 'AsynchronousJobTests.Runnable',
                    Reference__c = 'Test',
                    MaximumRetries__c = 1,
                    RetryInterval__c = 1000,
                    RetryNumber__c = 0,
                    ScheduledRunTime__c = Datetime.now()
            );
            AsynchronousJob.fromSObject(asynchronous);
        }
    }

    @IsTest
    static void testOptionalFields() {
        Asynchronous__c asynchronous = new Asynchronous__c(
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

    @IsTest
    private static void testAssignment() {
        Asynchronous__c asynchronous = new Asynchronous__c(
                Runnable__c = 'AsynchronousJobTests.Runnable'
        );

        Asynchronous.Job job = AsynchronousJob.fromSObject(asynchronous);
    }

    public with sharing class Runnable extends AsynchronousRunnable {
        public Runnable() {
            super(Runnable.class);
        }

        public override void run(Asynchronous.Job job) {}
    }
}