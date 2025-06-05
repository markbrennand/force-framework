/**
 * @description
 * Example classes and interfaces.
 *
 * @author Mark Brennand
 */
global class QueryClasses {

    global interface QueryInterface {
        List<SObject> query(String query, Map<String, Object> bindVars);
    }

    global with sharing abstract class AbstractQuery {
        global abstract List<SObject> query(String query, Map<String, Object> bindVars);
    }

    global with sharing class SystemQueryInterfaceImpl implements QueryInterface {
        public List<SObject> query(String query, Map<String, Object> bindVars) {
            System.debug('Querying in SYSTEM_MODE');
            return Database.queryWithBinds(query, bindVars, AccessLevel.SYSTEM_MODE);
        }
    }

    global with sharing class UserQueryInterfaceImpl implements QueryInterface {
        public List<SObject> query(String query, Map<String, Object> bindVars) {
            System.debug('Querying in USER_MODE');
            return Database.queryWithBinds(query, bindVars, AccessLevel.USER_MODE);
        }
    }

    global with sharing class SystemAbstractQueryImpl extends AbstractQuery {
        global override List<SObject> query(String query, Map<String, Object> bindVars) {
            System.debug('Querying in SYSTEM_MODE');
            return Database.queryWithBinds(query, bindVars, AccessLevel.SYSTEM_MODE);
        }
    }

    global with sharing class UserAbstractQueryImpl extends AbstractQuery {
        global override List<SObject> query(String query, Map<String, Object> bindVars) {
            System.debug('Querying in USER_MODE');
            return Database.queryWithBinds(query, bindVars, AccessLevel.USER_MODE);
        }
    }

}
