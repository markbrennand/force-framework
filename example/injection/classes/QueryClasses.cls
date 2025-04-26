/**
 * @description
 * Example classes and interfaces.
 *
 * @author Mark Brennand
 */
public class QueryClasses {

    public interface QueryInterface {
        List<SObject> query(String query, Map<String, Object> bindVars);
    }

    public with sharing abstract class AbstractQuery {
        public abstract List<SObject> query(String query, Map<String, Object> bindVars);
    }

    public with sharing class SystemQueryInterfaceImpl implements QueryInterface {
        public List<SObject> query(String query, Map<String, Object> bindVars) {
            System.debug('Querying in SYSTEM_MODE');
            return Database.queryWithBinds(query, bindVars, AccessLevel.SYSTEM_MODE);
        }
    }

    public with sharing class UserQueryInterfaceImpl implements QueryInterface {
        public List<SObject> query(String query, Map<String, Object> bindVars) {
            System.debug('Querying in USER_MODE');
            return Database.queryWithBinds(query, bindVars, AccessLevel.USER_MODE);
        }
    }

    public with sharing class SystemAbstractQueryImpl extends AbstractQuery {
        public override List<SObject> query(String query, Map<String, Object> bindVars) {
            System.debug('Querying in SYSTEM_MODE');
            return Database.queryWithBinds(query, bindVars, AccessLevel.SYSTEM_MODE);
        }
    }

    public with sharing class UserAbstractQueryImpl extends AbstractQuery {
        public override List<SObject> query(String query, Map<String, Object> bindVars) {
            System.debug('Querying in USER_MODE');
            return Database.queryWithBinds(query, bindVars, AccessLevel.USER_MODE);
        }
    }

}