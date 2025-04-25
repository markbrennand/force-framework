/**
 * @description
 * Example implementation of the Query interface which queries in USER_MODE.
 *
 * @author Mark Brennand
 */
public class UserModeQueryImpl implements Query {
    public List<SObject> query(String query, Map<String, Object> bindVars) {
        System.debug('Querying in USER_MODE');
        return Database.queryWithBinds(query, bindVars, AccessLevel.USER_MODE);
    }
}