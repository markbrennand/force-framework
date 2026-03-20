public with sharing class AccountSubscriber {

    /**
     * @description
     * Prevent re-use.
     */
    private AccountSubscriber() {}

    private with sharing class Implementation implements forcefw.TriggerV1.Subscriber {

        public void onEvent(forcefw.TriggerV1.Event event) {
            if (event.isAfter()) {
                // UNCOMMENT TO RUN ASYNCHRONOUSLY AccountContactTotals.startCalculationJob(event.getRecords(), new Set<Id>());
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