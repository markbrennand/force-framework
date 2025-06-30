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
    private static void createUsers() {
        final Id profileId = [SELECT Id FROM Profile WHERE Name = 'Minimum Access - Salesforce' LIMIT 1].Id;

        User manager = new User(
                Alias = 'manager',
                ProfileId = profileId,
                Username = 'manager@dependency.force-fw.test.com',
                Email = 'manager@dependency.force-fw.test.com',
                EmailEncodingKey = 'ISO-8859-1',
                TimeZoneSidKey = 'Europe/London',
                LocaleSidKey = 'en_US',
                LanguageLocaleKey = 'en_US',
                FirstName = 'Registry',
                LastName = 'Manager'
        );

        User user = new User(
                Alias = 'user',
                ProfileId = profileId,
                Username = 'user@dependency.force-fw.test.com',
                Email = 'user@dependency.force-fw.test.com',
                EmailEncodingKey = 'ISO-8859-1',
                TimeZoneSidKey = 'Europe/London',
                LocaleSidKey = 'en_US',
                LanguageLocaleKey = 'en_US',
                FirstName = 'Registry',
                LastName = 'User'
        );

        insert new List<User> { manager, user };

        Id userPermSetId = [SELECT Id FROM PermissionSet WHERE Name = 'ForceFwDependencyInjectionPermissions' LIMIT 1].Id;
        Id managerPermSetId = [SELECT Id FROM PermissionSet WHERE Name = 'ForceFwManager' LIMIT 1].Id;
        delete [SELECT Id FROM PermissionSetAssignment WHERE AssigneeId IN (:user.Id, :manager.Id) AND PermissionSetId IN (:userPermSetId, :managerPermSetId)];

        PermissionSetAssignment managerAssignment = new PermissionSetAssignment(
                AssigneeId = manager.Id,
                PermissionSetId = managerPermSetId
        );

        PermissionSetAssignment userAssignment = new PermissionSetAssignment(
                AssigneeId = user.Id,
                PermissionSetId = userPermSetId
        );

        insert new List<PermissionSetAssignment> { managerAssignment, userAssignment };
    }

    @TestVisible
    private static User getManager() {
        return [SELECT Id FROM User WHERE Username = 'manager@dependency.force-fw.test.com' LIMIT 1];
    }

    @TestVisible
    private static User getUser() {
        return [SELECT Id FROM User WHERE Username = 'user@dependency.force-fw.test.com' LIMIT 1];
    }

    @TestVisible
    private static void testBindingFailure(Type forType, String action, Type withImpl, String expectedError) {
        try {
            if (action == null) {
                DependencyV1.bind(forType, withImpl);
            } else {
                DependencyV1.bind(forType, action, withImpl);
            }
            Assert.fail();
        } catch(Exception e) {
            handleException(e, expectedError);
        }

        try {
            if (action == null) {
                insert new Binding__c(Type__c = forType.getName(), Implementation__c = withImpl.getName());
            } else {
                insert new Binding__c(Type__c = forType.getName(), Action__c = action, Implementation__c = withImpl.getName());
            }
            Assert.fail();
        } catch(Exception e) {
            handleException(e, expectedError);
        }
    }

    @TestVisible
    private static void handleException(Exception exc, String expectedError) {
        if (! (exc instanceof DMLException || exc instanceof Dependency.APIException)) {
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

    public with sharing class PrototypeTest extends AbstractTest implements Dependency.Prototype {
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

    public with sharing class PrototypeCustomTest extends AbstractTest implements Dependency.Prototype {
        private String value;

        public PrototypeCustomTest() {
            value = 'CUSTOM' + (++PROTOTYPE_INSTANCE);
        }
        public String getValue() {
            return value;
        }
    }

    public with sharing class AbstractTestBindingCheck implements Dependency.BindingCheck {
        public Dependency.ValidationResult validate(Type forType, Type withImpl) {
            Object instance = TypesV1.newInstance(withImpl);
            SINGLETON_INSTANCE =
            PROTOTYPE_INSTANCE = 0;

            if (instance instanceof AbstractTest) {
                return new Dependency.ValidationResult(true, null);
            } else {
                return new Dependency.ValidationResult(
                        false,
                        'Class ' + withImpl.getName() + ' does not extend AbstractTest'
                );
            }
        }
    }

    public with sharing class TestInterfaceBindingCheck implements Dependency.BindingCheck {
        public Dependency.ValidationResult validate(Type forType, Type withImpl) {
            Object instance = TypesV1.newInstance(withImpl);
            SINGLETON_INSTANCE =
            PROTOTYPE_INSTANCE = 0;

            if (instance instanceof TestInterface) {
                return new Dependency.ValidationResult(true, null);
            } else {
                return new Dependency.ValidationResult(
                        false,
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