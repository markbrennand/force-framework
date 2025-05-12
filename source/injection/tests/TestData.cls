/**
 * @description
 * Common test data for unit tests.
 *
 * @author Mark Brennand
 */
@IsTest
public with sharing class TestData {
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
                Injection.add(forType, withImpl);
            } else {
                Injection.add(forType, action, withImpl);
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
        if (! (e instanceof DMLException || e instanceof Injection.APIException)) {
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

    public with sharing class PrototypeTest extends AbstractTest implements Injection.Prototype {
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

    public with sharing class PrototypeCustomTest extends AbstractTest implements Injection.Prototype {
        private String value;

        public PrototypeCustomTest() {
            value = 'CUSTOM' + (++PROTOTYPE_INSTANCE);
        }
        public String getValue() {
            return value;
        }
    }

    public with sharing class AbstractTestChecker implements Injection.BindingCheck {
        public Injection.ValidationResult validate(Type forType, Type withImpl) {
            Object instance = TypeHelper.newInstance(withImpl);
            SINGLETON_INSTANCE =
            PROTOTYPE_INSTANCE = 0;

            if (instance instanceof AbstractTest) {
                return new Injection.ValidationResult(true, null);
            } else {
                return new Injection.ValidationResult(
                        false,
                        'Class ' + withImpl.getName() + ' does not extend AbstractTest'
                );
            }
        }
    }

    public with sharing class TestInterfaceChecker implements Injection.BindingCheck {
        public Injection.ValidationResult validate(Type forType, Type withImpl) {
            Object instance = TypeHelper.newInstance(withImpl);
            SINGLETON_INSTANCE =
            PROTOTYPE_INSTANCE = 0;

            if (instance instanceof TestInterface) {
                return new Injection.ValidationResult(true, null);
            } else {
                return new Injection.ValidationResult(
                        false,
                        'Class ' + withImpl.getName() + ' does not implement TestInterface'
                );
            }
        }
    }

    public with sharing class SystemTypeChecker implements Injection.BindingCheck {
        public Injection.ValidationResult validate(Type forType, Type withImpl) {
            Object impl = TypeHelper.newInstance(withImpl);

            switch on forType.getName() {
                when 'Integer' {
                    if (impl instanceof Integer) {
                        return new Injection.ValidationResult(true, null);
                    }
                }
                when 'Map<String,Integer>' {
                    if (impl instanceof Map<String, Integer>) {
                        return new Injection.ValidationResult(true, null);
                    }
                }
                when else {
                    return new Injection.ValidationResult(
                            false,
                            'Class ' + withImpl + ' can not be validated'
                    );
                }
            }

            return new Injection.ValidationResult(
                    false,
                    'Implementation ' + withImpl.getName() + ' is not a super class of ' + forType.getName()
            );
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