/**
 * @description
 * Common test data and methods for Binding related unit tests.
 *
 * @author Mark Brennand
 */
@IsTest
public with sharing class BindingTestHelper {
    public static Integer SINGLETON_INSTANCE = 0;
    public static Integer PROTOTYPE_INSTANCE = 0;

    public static void createUsers() {
        final Id profileId = [SELECT Id FROM Profile WHERE Name = 'Minimum Access - Salesforce' LIMIT 1].Id;

        User manager = new User(
                Alias = 'manager',
                ProfileId = profileId,
                Username = 'manager@sf-frameworks.test.com',
                Email = 'manager@sf-frameworks.test.com',
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
                Username = 'user@sf-frameworks.test.com',
                Email = 'user@sf-frameworks.test.com',
                EmailEncodingKey = 'ISO-8859-1',
                TimeZoneSidKey = 'Europe/London',
                LocaleSidKey = 'en_US',
                LanguageLocaleKey = 'en_US',
                FirstName = 'Registry',
                LastName = 'User'
        );

        insert new List<User> { manager, user };

        PermissionSetAssignment managerAssignment = new PermissionSetAssignment(
                AssigneeId = manager.Id,
                PermissionSetId = [SELECT Id FROM PermissionSet WHERE Name = 'FrameworkManager' LIMIT 1].Id
        );

        PermissionSetAssignment userAssignment = new PermissionSetAssignment(
                AssigneeId = user.Id,
                PermissionSetId = [SELECT Id FROM PermissionSet WHERE Name = 'InjectionUser' LIMIT 1].Id
        );

        insert new List<PermissionSetAssignment> { managerAssignment, userAssignment };
    }

    public static User getManager() {
        return [SELECT Id FROM User WHERE Username = 'manager@sf-frameworks.test.com' LIMIT 1];
    }

    public static User getUser() {
        return [SELECT Id FROM User WHERE Username = 'user@sf-frameworks.test.com' LIMIT 1];
    }

    public static void testBindingFailure(Type forType, String action, Type withImpl, String expectedError) {
        try {
            if (action == null) {
                Dependency.bind(forType, withImpl);
            } else {
                Dependency.bind(forType, action, withImpl);
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

    private static void handleException(Exception e, String expectedError) {
        if (! (e instanceof DMLException || e instanceof Dependency.APIException)) {
            throw e;
        }

        if (!e.getMessage().contains(expectedError)) {
            Assert.fail('Unexpected error message; ' + e.getMessage());
        }
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

    public with sharing class AbstractTestChecker implements Dependency.BindingCheck {
        public Dependency.ValidationResult validate(Type forType, Type withImpl) {
            Object instance = TypeHelper.newInstance(withImpl);
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

    public with sharing class TestInterfaceChecker implements Dependency.BindingCheck {
        public Dependency.ValidationResult validate(Type forType, Type withImpl) {
            Object instance = TypeHelper.newInstance(withImpl);
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

    public with sharing class IntegerFactory implements TypeHelper.Factory {
        public Object newInstance() {
            return 123;
        }
    }

    public with sharing class MapFactory implements TypeHelper.Factory {
        public Object newInstance() {
            return new Map<String, Integer> { 'a' => 456, 'b' => 789 };
        }
    }
}