/**
 * @description
 * Common test data for unit tests.
 *
 * @author Mark Brennand
 */

public with sharing class TestData {
    public static Integer SINGLETON_INSTANCE = 0;
    public static Integer PROTOTYPE_INSTANCE = 0;

    public static void createUsers() {
        final Id profileId = [SELECT Id FROM Profile WHERE Name = 'Minimum Access - Salesforce' LIMIT 1].Id;

        User manager = new User(
                Alias = 'manager',
                ProfileId = profileId,
                Username = 'manager@test.com',
                Email = 'manager@test.com',
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
                Username = 'user@test.com',
                Email = 'user@test.com',
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
                PermissionSetId = [SELECT Id FROM PermissionSet WHERE Name = 'RegistryManager' LIMIT 1].Id
        );

        PermissionSetAssignment userAssignment = new PermissionSetAssignment(
                AssigneeId = user.Id,
                PermissionSetId = [SELECT Id FROM PermissionSet WHERE Name = 'RegistryUser' LIMIT 1].Id
        );

        insert new List<PermissionSetAssignment> { managerAssignment, userAssignment };
    }

    public static User getManager() {
        return [SELECT Id FROM User WHERE Username = 'manager@test.com' LIMIT 1];
    }

    public static User getUser() {
        return [SELECT Id FROM User WHERE Username = 'user@test.com' LIMIT 1];
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

    public with sharing class PrototypeTest extends AbstractTest implements Registry.Prototype {
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
            System.debug('SingletonCustomTest(' + SINGLETON_INSTANCE + ')');
            value = 'CUSTOM' + (++SINGLETON_INSTANCE);
        }
        public String getValue() {
            return value;
        }
    }

    public with sharing class PrototypeCustomTest extends AbstractTest implements Registry.Prototype {
        private String value;

        public PrototypeCustomTest() {
            value = 'CUSTOM' + (++PROTOTYPE_INSTANCE);
        }
        public String getValue() {
            return value;
        }
    }

    public with sharing class AbstractTestChecker implements Registry.BindingCheck {
        public Registry.ValidationResult validate(Type forType, Type withImpl) {
            Object instance = TypeHelper.newInstance(withImpl);
            SINGLETON_INSTANCE =
            PROTOTYPE_INSTANCE = 0;

            if (instance instanceof AbstractTest) {
                return new Registry.ValidationResult(true, null);
            } else {
                return new Registry.ValidationResult(
                        false,
                        'Type "' + withImpl.getName() + '" does not extend "AbstractTest"'
                );
            }
        }
    }

    public with sharing class TestInterfaceChecker implements Registry.BindingCheck {
        public Registry.ValidationResult validate(Type forType, Type withImpl) {
            Object instance = TypeHelper.newInstance(withImpl);
            SINGLETON_INSTANCE =
            PROTOTYPE_INSTANCE = 0;

            if (instance instanceof TestInterface) {
                return new Registry.ValidationResult(true, null);
            } else {
                return new Registry.ValidationResult(
                        false,
                        'Type "' + withImpl.getName() + '" does not implement "TestInterface"'
                );
            }
        }
    }
}