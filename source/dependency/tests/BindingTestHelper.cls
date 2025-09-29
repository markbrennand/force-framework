/**
 * @description
 * <p>
 * Common test data and methods for Binding related unit tests.
 * <p>
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../LICENSE target="_blank">MIT License</a>.
 *
 * @author Mark Brennand
 */
@IsTest
public with sharing class BindingTestHelper {

    @TestVisible
    private static Integer singletonInstance = 0;

    @TestVisible
    private static Integer prototypeInstance = 0;

    @TestVisible
    @SuppressWarnings('PMD.ExcessiveParameterList')
    private static void testBindingFailure(final Type forType, final OptionalV1 action, final Type withImpl, final String expectedError) {
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
    private static void handleException(final Exception exc, final String expectedError) {
        if (! (exc instanceof DmlException || exc instanceof DependencyV1.APIException)) {
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
        private final String value;

        public SingletonTest() {
            value = 'INSTANCE' + (++singletonInstance);
        }
        public String getValue() {
            return value;
        }
    }

    @SuppressWarnings('PMD.ApexDoc')
    public with sharing class PrototypeTest extends AbstractTest implements DependencyV1.Prototype {
        private final String value;

        public PrototypeTest() {
            value = 'INSTANCE' + (++prototypeInstance);
        }
        public String getValue() {
            return value;
        }
    }

    @SuppressWarnings('PMD.ApexDoc')
    public with sharing class SingletonCustomTest extends AbstractTest  {
        private final String value;

        public SingletonCustomTest() {
            value = 'CUSTOM' + (++singletonInstance);
        }
        public String getValue() {
            return value;
        }
    }

    @SuppressWarnings('PMD.ApexDoc')
    public with sharing class PrototypeCustomTest extends AbstractTest implements DependencyV1.Prototype {
        private final String value;

        public PrototypeCustomTest() {
            value = 'CUSTOM' + (++prototypeInstance);
        }
        public String getValue() {
            return value;
        }
    }

    @SuppressWarnings('PMD.ApexDoc')
    public with sharing class AbstractTestBindingCheck implements DependencyV1.BindingCheck {
        public DependencyV1.ValidationResult validate(final Type forType, final Type withImpl) {
            Object instance = TypesV1.newInstance(withImpl);
            singletonInstance =
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
        public DependencyV1.ValidationResult validate(final Type forType, final Type withImpl) {
            Object instance = TypesV1.newInstance(withImpl);
            singletonInstance =
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