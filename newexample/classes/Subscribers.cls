/**
 * Created by markbrennand on 15/07/2025.
 */
global with sharing class Subscribers {

    private with sharing class AccountSubscriber implements forcefw.TriggerV1.Subscriber {
        public void onEvent(forcefw.TriggerV1.Event event) {
            AccountManager manager = (AccountManager) forcefw.DependencyV1.inject(AccountManager.class);
            manager.newAccount((List<Account>) event.getRecords());
        }
    }

    private with sharing class ContactSubscriber implements forcefw.TriggerV1.Subscriber {
        public void onEvent(forcefw.TriggerV1.Event event) {
            AccountManager manager = (AccountManager) forcefw.DependencyV1.inject(AccountManager.class);
            switch on event.getOperation() {
                when INSERTING {
                    manager.insertContact((List<Contact>) event.getRecords());
                }
                when UPDATING {
                    manager.updateContact((List<Contact>) event.getRecords());
                }
                when DELETING {
                    manager.deleteContact((List<Contact>) event.getRecords());
                }
            }
        }
    }

    global with sharing class AccountSubscriberFactory implements forcefw.TypesV1.Factory {
        global Object newInstance() {
            return new AccountSubscriber();
        }
    }

    global with sharing class ContactSubscriberFactory implements forcefw.TypesV1.Factory {
        global Object newInstance() {
            return new ContactSubscriber();
        }
    }
}