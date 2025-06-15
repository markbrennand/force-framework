/**
 * @description
 * Example API to be mocked.
 *
 * @author Mark Brennand
 */
public interface MockerTestAPI {
    Datetime getCurrentTime();
    void setCurrentTime(Datetime currentTime);
    String getOrganizationId();
    List<Account> addAccounts(List<Account> accounts);
}