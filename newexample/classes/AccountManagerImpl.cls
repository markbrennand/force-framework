/**
 * Created by markbrennand on 15/07/2025.
 */
global with sharing class AccountManagerImpl implements AccountManager {
    private static final forcefw.OptionalV1 EMPTY = forcefw.OptionalV1.empty();

    public void newAccount(List<Account> accounts) {
        for (Account account : accounts) {
            account.TotalContacts__c = 0;
        }
    }

    public void insertContact(List<Contact> contacts) {
        setPeerCount(contacts);
    }

    public void updateContact(List<Contact> contacts) {
        setPeerCount(contacts);
    }

    public void deleteContact(List<Contact> contacts) {
        setPeerCount(contacts);
    }

    private void setPeerCount(List<Contact> contacts) {
        Set<Id> accountIds =
                (Set<Id>) forcefw.ArrayV1.over(contacts).reduce(new AccountIdExtractor(), new Set<Id>());

        forcefw.QueryV1.of(Contact.SObjectType)
                .security(AccessLevel.USER_MODE)
                .returning(forcefw.QueryV1.aggregatedField(Contact.AccountId, 'AccountId'))
                .returning(forcefw.QueryV1.aggregatedField('COUNT', Contact.Id, 'Total'))
                .matching('AccountId IN :accountIds')
                .group(new Set<SObjectField> { Contact.AccountId })
                .bindings(new Map<String, Object> { 'accountIds' => accountIds })
                .execute()
                .then(new UpdateAccounts())
                .then(new UpdateContacts());
    }

    global with sharing class BindingCheck implements forcefw.DependencyV1.BindingCheck {
        public forcefw.DependencyV1.ValidationResult validate(Type forType, Type withImpl) {
            Object impl = forcefw.TypesV1.newInstance(withImpl);
            if (impl instanceof AccountManager) {
                return forcefw.DependencyV1.valid();
            } else {
                return forcefw.DependencyV1.invalid(
                        'Implementation "' + withImpl.getName() + '" is not an instance of "' + forType.getName() + '"'
                );
            }
        }
    }

    private with sharing class AccountIdExtractor extends forcefw.ArrayV1.Callback {
        public override forcefw.OptionalV1 function(Object element, forcefw.OptionalV1 currentValue, Integer index) {
            ((Set<Id>) currentValue.get()).add(((Contact) element).AccountId);
            return currentValue;
        }
    }

    private with sharing class UpdateAccounts implements forcefw.OptionalV1.Function {
        public forcefw.OptionalV1 apply(forcefw.OptionalV1 value) {
            if (!value.isPresent()) {
                return value;
            }

            Map<Id, Integer> counts = new Map<Id, Integer>();
            for (AggregateResult result : (List<AggregateResult>) value.get()) {
                counts.put((Id) result.get('AccountId'), (Integer) result.get('Total'));
            }

            forcefw.OptionalV1.of(
                    forcefw.QueryV1.of(Account.SObjectType)
                            .security(AccessLevel.USER_MODE)
                            .returning(Account.Id)
                            .matching('Id IN :accountIds')
                            .bindings(new Map<String, Object> { 'accountIds' => counts.keySet() })
                            .execute()
                            .collection()
                            .sharing(counts)
                            .transform(new SetTotalContactsInAccount(), new List<Account>())
            ).then(new Persist());

            return forcefw.OptionalV1.of(counts);
        }
    }

    private with sharing class UpdateContacts implements forcefw.OptionalV1.Function {
        public forcefw.OptionalV1 apply(forcefw.OptionalV1 value) {
            if (!value.isPresent()) {
                return value;
            }

            Map<Id, Integer> counts = (Map<Id, Integer>) value.get();

            return forcefw.QueryV1.of(Contact.SObjectType)
                    .security(AccessLevel.USER_MODE)
                    .returning(Contact.Id)
                    .returning(Contact.AccountId)
                    .matching('AccountId IN :accountIds')
                    .bindings(new Map<String, Object> { 'accountIds' => counts.keySet() })
                    .execute()
                    .then(new SetPeerCountInContact(counts));
        }
    }

    private with sharing class Persist implements forcefw.OptionalV1.Function {
        public forcefw.OptionalV1 apply(forcefw.OptionalV1 value) {
            if (!value.isPresent()) {
                return value;
            }

            Database.upsert((List<SObject>) value.get(), AccessLevel.USER_MODE);
            return value;
        }
    }

    private with sharing class SetTotalContactsInAccount extends forcefw.ArrayV1.Callback {
        public override forcefw.OptionalV1 function(Object element, forcefw.OptionalV1 currentValue, Integer index) {
            Map<Id, Integer> counts = (Map<Id, Integer>) shared().get();
            ((Account) element).TotalContacts__c = counts.get(((Account) element).Id);
            return forcefw.OptionalV1.of((Account) element);
        }
    }

    private with sharing class SetPeerCountInContact implements forcefw.OptionalV1.Function {
        private final Map<Id, Integer> counts;

        public SetPeerCountInContact(Map<Id, Integer> counts) {
            this.counts = counts;
        }

        public forcefw.OptionalV1 apply(forcefw.OptionalV1 value) {
            if (!value.isPresent()) {
                return value;
            }

            List<Contact> contacts = (List<Contact>) value.get();
            for (Contact contact : contacts) {
                contact.NumberOfPeers__c = counts.get(contact.AccountId) - 1;
            }

            Database.update(contacts, AccessLevel.USER_MODE);
            return value;
        }
    }
}