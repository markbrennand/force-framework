/**
 * @description
 * Event handler for Contact trigger.
 *
 * @author Mark Brennand
 */
global with sharing class ContactTrigger extends forcefw.TriggersV1.Event {

    /**
     * @description
     * Prevent re-use.
     */
    private ContactTrigger() {}

    /**
     * @description
     * Called by event router after insert of new objects.
     *
     * @param records Inserted records.
     */
    public override void onAfterInsert(final List<SObject> records) {
        AccountContactTotals.startCalculationJob(records, this);
    }

    /**
     * @description
     * Called by event router after update of objects.
     *
     * @param records Updated records.
     */
    public override void onAfterUpdate(final List<SObject> records) {
        AccountContactTotals.startCalculationJob(records, this);
    }

    /**
     * @description
     * Called by event router after deletion of objects.
     *
     * @param records Deleted records.
     */
    public override void onAfterDelete(final List<SObject> records) {
        AccountContactTotals.startCalculationJob(null, this);
    }

    /**
     * @description
     * Factory to create the trigger Event instance.
     */
    global with sharing class Factory implements forcefw.TypesV1.Factory {
        public Object newInstance() {
            return new ContactTrigger();
        }
    }
}