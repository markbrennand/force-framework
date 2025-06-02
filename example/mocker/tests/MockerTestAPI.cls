/**
 * @description
 * Example API to be mocked.
 *
 * @author Mark Brennand
 */
public interface MockerTestAPI {
    Datetime getCurrentTime();
    String getOrganizationId();
    List<Account> addAccounts(List<Account> accounts);
    void processError(DMLException de);
}