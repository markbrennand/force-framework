/**
 * Created by markbrennand on 15/07/2025.
 */
global interface AccountManager {
    void newAccount(List<Account> accounts);
    void insertContact(List<Contact> contacts);
    void updateContact(List<Contact> contacts);
    void deleteContact(List<Contact> contacts);
}