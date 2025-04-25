/**
 * @description
 * Example implementation of the Query interface which queries in SYSTEM_MODE.
 *
 * @author Mark Brennand
 */
public class SystemModeQueryImpl implements Query {
    public List<SObject> query(String query, Map<String, Object> bindVars) {
        System.debug('Querying in SYSTEM_MODE');
        return Database.queryWithBinds(query, bindVars, AccessLevel.SYSTEM_MODE);
    }
}