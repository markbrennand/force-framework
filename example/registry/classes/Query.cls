/**
 * @description
 * Example interface.
 *
 * @author Mark Brennand
 */
public interface Query {
    List<SObject> query(String query, Map<String, Object> bindVars);
}