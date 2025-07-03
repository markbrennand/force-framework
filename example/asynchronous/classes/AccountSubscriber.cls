/**
 * @description
 * Event handler for Account trigger.
 *
 * @author Mark Brennand
 */
public with sharing class AccountSubscriber {

    /**
     * @description
     * Prevent re-use.
     */
    private AccountSubscriber() {}

    private with sharing class Implementation implements TriggerV1.Subscriber {

        public void onEvent(TriggerV1.Event event) {
            if (event.isAfter()) {
                AccountContactTotals.startCalculationJob(event.getRecords(), new Set<Id>());
            }
        }

        public Set<TriggerV1.Operation> forOperations() {
            return new Set<TriggerV1.Operation> { TriggerV1.Operation.INSERTING, TriggerV1.Operation.UPDATING };
        }
    }

    /**
     * @description
     * Factory to create the trigger Event instance.
     */
    public with sharing class Factory implements TypesV1.Factory {
        public Object newInstance() {
            return new Implementation();
        }
    }
}