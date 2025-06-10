/**
 * @description
 * Class showing how an API interface can be implemented to prevent access to the implementing class through
 * anything other than then API it implements.
 *
 * The top level class implements the API and is virtual so it can be mocked.
 *
 * @author Mark Brennand
 */
global with sharing virtual class SimpleAdditionImpl implements SimpleAddition.API {

    // TestVisible so it can be replaced with a mocked version of the API.
    @TestVisible
    public static SimpleAddition.API INJECT {
        public get {
            // The injected class may be a Prototype, so leave it to the Dependency manager to determine whether
            // to use a singleton or a new instance on each use.
            return (SimpleAddition.API) forcefw.DependencyV1.inject(SimpleAddition.API.class);
        }
        private set;
    }

    /**
     * @description
     * Constructor is protected to allow class to be mocked.
     */
    protected SimpleAdditionImpl() {}

    /**
     * @description
     * Hidden implementation of API.
     *
     * Making it private, prevents any references to the class being made outside this class.
     */
    private class Implementation implements SimpleAddition.API {
        public Integer sum(List<Integer> values) {
            Integer total = 0;

            for (Integer value : values) {
                total += value;
            }

            return total;
        }
    }

    /**
     * @description
     * Factory to create the private API implementation.
     *
     * Has to be global so can be created from the Types class, which when packaged will be in a different
     * namespace to this class.
     */
    global class Factory implements forcefw.TypesV1.Factory {
        public Object newInstance() {
            return new Implementation();
        }
    }

    /**
     * @description
     * Solely for mocking.
     *
     * Must always throw an Exception if it is called.
     */
    public Integer sum(List<Integer> values) {
        throw new forcefw.TypesV1.APIException('Access denied');
    }

    static {
        // Set the default injection for the API.
        forcefw.DependencyV1.bind(SimpleAddition.API.class, Factory.class);
    }
}
