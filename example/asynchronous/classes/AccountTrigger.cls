/**
 * @description
 * Event handler for Account trigger.
 *
 * @author Mark Brennand
 */
public with sharing class AccountTrigger extends TriggersV1.Event {

    /**
     * @description
     * Prevent re-use.
     */
    private AccountTrigger() {}

    /**
     * @description
     * Called by event router after insert of new objects.
     *
     * @param records Inserted records.
     */
    public override void onAfterInsert(final List<SObject> records) {
        AccountContactTotals.startCalculationJob(records, new Set<Id>());
    }

    /**
     * @description
     * Called by event router after update of objects.
     *
     * @param records Updated records.
     */
    public override void onAfterUpdate(final List<SObject> records) {
        AccountContactTotals.startCalculationJob(records, new Set<Id>());
    }

    /**
     * @description
     * Factory to create the trigger Event instance.
     */
    public with sharing class Factory implements TypesV1.Factory {
        public Object newInstance() {
            return new AccountTrigger();
        }
    }
}