/**
 * @description
 * Event handler for Contact trigger.
 *
 * @author Mark Brennand
 */
public with sharing class ContactSubscriber {

    /**
     * @description
     * Prevent re-use.
     */
    private ContactSubscriber() {}

    private with sharing class Implementation implements forcefw.TriggerV1.Subscriber {
        public void onEvent(forcefw.TriggerV1.Event event) {
            if (event.isAfter()) {
                // UNCOMMENT TO RUN ASYNCHRONOUSLY AccountContactTotals.startCalculationJob(event.getRecords(), event);
            }
        }
    }

    /**
     * @description
     * Factory to create the trigger Event instance.
     */
    public with sharing class Factory implements forcefw.TypesV1.Factory {
        public Object newInstance() {
            return new Implementation();
        }
    }
}