/**
 * @description
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../LICENSE target="_blank">MIT License</a>.
 * <br><br>
 * Common test data and methods for Binding related unit tests.
 *
 * @author Mark Brennand
 */
@IsTest
public with sharing class BindingTestHelper {

    @TestVisible
    private static Integer singletoInstance = 0;

    @TestVisible
    private static Integer prototypeInstance = 0;

    @TestVisible
    @SuppressWarnings('PMD.ExcessiveParameterList')
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

    @SuppressWarnings('PMD.ApexDoc')
    public interface TestInterface {
        String getValue();
    }

    @SuppressWarnings('PMD.ApexDoc')
    public abstract with sharing class AbstractTest implements TestInterface {}

    @SuppressWarnings('PMD.ApexDoc')
    public with sharing class SingletonTest extends AbstractTest {
        private String value;

        public SingletonTest() {
            value = 'INSTANCE' + (++singletoInstance);
        }
        public String getValue() {
            return value;
        }
    }

    @SuppressWarnings('PMD.ApexDoc')
    public with sharing class PrototypeTest extends AbstractTest implements DependencyV1.Prototype {
        private String value;

        public PrototypeTest() {
            value = 'INSTANCE' + (++prototypeInstance);
        }
        public String getValue() {
            return value;
        }
    }

    @SuppressWarnings('PMD.ApexDoc')
    public with sharing class SingletonCustomTest extends AbstractTest  {
        private String value;

        public SingletonCustomTest() {
            value = 'CUSTOM' + (++singletoInstance);
        }
        public String getValue() {
            return value;
        }
    }

    @SuppressWarnings('PMD.ApexDoc')
    public with sharing class PrototypeCustomTest extends AbstractTest implements DependencyV1.Prototype {
        private String value;

        public PrototypeCustomTest() {
            value = 'CUSTOM' + (++prototypeInstance);
        }
        public String getValue() {
            return value;
        }
    }

    @SuppressWarnings('PMD.ApexDoc')
    public with sharing class AbstractTestBindingCheck implements DependencyV1.BindingCheck {
        public DependencyV1.ValidationResult validate(Type forType, Type withImpl) {
            Object instance = TypesV1.newInstance(withImpl);
            singletoInstance =
            prototypeInstance = 0;

            if (instance instanceof AbstractTest) {
                return DependencyV1.valid();
            } else {
                return DependencyV1.invalid(
                        'Class ' + withImpl.getName() + ' does not extend AbstractTest'
                );
            }
        }
    }

    @SuppressWarnings('PMD.ApexDoc')
    public with sharing class TestInterfaceBindingCheck implements DependencyV1.BindingCheck {
        public DependencyV1.ValidationResult validate(Type forType, Type withImpl) {
            Object instance = TypesV1.newInstance(withImpl);
            singletoInstance =
            prototypeInstance = 0;

            if (instance instanceof TestInterface) {
                return DependencyV1.valid();
            } else {
                return DependencyV1.invalid(
                        'Class ' + withImpl.getName() + ' does not implement TestInterface'
                );
            }
        }
    }

    @SuppressWarnings('PMD.ApexDoc')
    public with sharing class IntegerFactory implements TypesV1.Factory {
        public Object newInstance() {
            return 123;
        }
    }

    @SuppressWarnings('PMD.ApexDoc')
    public with sharing class MapFactory implements TypesV1.Factory {
        public Object newInstance() {
            return new Map<String, Integer> { 'a' => 456, 'b' => 789 };
        }
    }
}