/**
 * @description
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../../LICENSE target="_blank">MIT License</a>.
 * <br><br>
 * Common test data and methods for Binding related unit tests.
 *
 * @author Mark Brennand
 */
@IsTest
public with sharing class BindingTestHelper {

    @TestVisible
    private static Integer SINGLETON_INSTANCE = 0;

    @TestVisible
    private static Integer PROTOTYPE_INSTANCE = 0;

    @TestVisible
    private static void testBindingFailure(Type forType, OptionalV1 action, Type withImpl, String expectedError) {
        try {
            if (action.isPresent()) {
                DependencyV1.bind(forType, (String) action.get(), withImpl);
            } else {
                DependencyV1.bind(forType, withImpl);
            }
            Assert.fail();
        } catch(Exception e) {
            handleException(e, expectedError);
        }

        try {
            if (action.isPresent()) {
                insert new Binding__c(Type__c = forType.getName(), Action__c = (String) action.get(), Implementation__c = withImpl.getName());
            } else {
                insert new Binding__c(Type__c = forType.getName(), Implementation__c = withImpl.getName());
            }
            Assert.fail();
        } catch(Exception e) {
            handleException(e, expectedError);
        }
    }

    @TestVisible
    private static void handleException(Exception exc, String expectedError) {
        if (! (exc instanceof DMLException || exc instanceof DependencyV1.APIException)) {
            throw exc;
        }

        Assert.isTrue(TestHelper.exceptionContains(expectedError, exc), 'Unexpected exception: ' + exc);
    }

    public interface TestInterface {
        String getValue();
    }

    public abstract with sharing class AbstractTest implements TestInterface {}

    public with sharing class SingletonTest extends AbstractTest {
        private String value;

        public SingletonTest() {
            value = 'INSTANCE' + (++SINGLETON_INSTANCE);
        }
        public String getValue() {
            return value;
        }
    }

    public with sharing class PrototypeTest extends AbstractTest implements DependencyV1.Prototype {
        private String value;

        public PrototypeTest() {
            value = 'INSTANCE' + (++PROTOTYPE_INSTANCE);
        }
        public String getValue() {
            return value;
        }
    }

    public with sharing class SingletonCustomTest extends AbstractTest  {
        private String value;

        public SingletonCustomTest() {
            value = 'CUSTOM' + (++SINGLETON_INSTANCE);
        }
        public String getValue() {
            return value;
        }
    }

    public with sharing class PrototypeCustomTest extends AbstractTest implements DependencyV1.Prototype {
        private String value;

        public PrototypeCustomTest() {
            value = 'CUSTOM' + (++PROTOTYPE_INSTANCE);
        }
        public String getValue() {
            return value;
        }
    }

    public with sharing class AbstractTestBindingCheck implements DependencyV1.BindingCheck {
        public DependencyV1.ValidationResult validate(Type forType, Type withImpl) {
            Object instance = TypesV1.newInstance(withImpl);
            SINGLETON_INSTANCE =
            PROTOTYPE_INSTANCE = 0;

            if (instance instanceof AbstractTest) {
                return DependencyV1.valid();
            } else {
                return DependencyV1.invalid(
                        'Class ' + withImpl.getName() + ' does not extend AbstractTest'
                );
            }
        }
    }

    public with sharing class TestInterfaceBindingCheck implements DependencyV1.BindingCheck {
        public DependencyV1.ValidationResult validate(Type forType, Type withImpl) {
            Object instance = TypesV1.newInstance(withImpl);
            SINGLETON_INSTANCE =
            PROTOTYPE_INSTANCE = 0;

            if (instance instanceof TestInterface) {
                return DependencyV1.valid();
            } else {
                return DependencyV1.invalid(
                        'Class ' + withImpl.getName() + ' does not implement TestInterface'
                );
            }
        }
    }

    public with sharing class IntegerFactory implements TypesV1.Factory {
        public Object newInstance() {
            return 123;
        }
    }

    public with sharing class MapFactory implements TypesV1.Factory {
        public Object newInstance() {
            return new Map<String, Integer> { 'a' => 456, 'b' => 789 };
        }
    }
}