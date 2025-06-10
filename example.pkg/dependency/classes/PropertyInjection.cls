/**
 * @description
 * Example of property injection.
 *
 * @author Mark Brennand
 */
public with sharing class PropertyInjection {

    // Setup a default registry. The default registry will take the Map to assign to the 'properties' member
    // variable from the DefaultConfiguration class.
    static {
        forcefw.DependencyV1.bind(Map<String, Integer>.class, 'animals', DefaultConfiguration.class);
    }

    // The member variable 'properties' value is injected into the class on construction.
    public final Map<String, Integer> properties =
            (Map<String, Integer>) forcefw.DependencyV1.inject(Map<String, Integer>.class, 'animals');


    /**
     * @description
     * Call this method using anonymous APEX to see the value assigned to 'properties' on construction.
     */
    public static void run() {
        PropertyInjection injection = new PropertyInjection();
        System.debug('The farm has ' + injection.properties.get('sheep') + ' sheep');
        System.debug('The farm has ' + injection.properties.get('cows') + ' cows');
        System.debug('The farm has ' + injection.properties.get('hens') + ' hens');
    }

    /**
     * @description
     * Default configuration values.
     */
    public class DefaultConfiguration implements forcefw.TypesV1.Factory {
        public Object newInstance() {
            return new Map<String, Integer> { 'sheep' => 100, 'cows' => 50, 'hens' => 2000 };
        }
    }

    /**
     * @description
     * New configuration values.
     */
    public class NewConfiguration implements forcefw.TypesV1.Factory {
        public Object newInstance() {
            return new Map<String, Integer> { 'sheep' => 1, 'cows' => 2, 'hens' => 3 };
        }
    }
}
