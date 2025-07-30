/**
 * @description
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../../LICENSE target="_blank">MIT License</a>.
 * <br><br>
 * Unit tests to check registry can be mocked.
 *
 * @author Mark Brennand
 */
@IsTest
public with sharing class BindingMockingTests {
    @TestSetup
    private static void setup() {
        BindingTestHelper.createUsers();
    }

    @IsTest
    private static void testMocking() {
        TestHelper.setNOW();
        System.runAs(BindingTestHelper.getUser()) {
            DependencyAPI mockInjection = createMock();
            DependencyAPI.API = mockInjection;

            Assert.isTrue(DependencyV1.isBound(BindingTestHelper.TestInterface.class));
            Assert.isFalse(DependencyV1.isBound(BindingTestHelper.AbstractTest.class));
            Assert.isTrue(DependencyV1.isBound(BindingTestHelper.AbstractTest.class, 'Test'));
            Assert.isFalse(DependencyV1.isBound(BindingTestHelper.AbstractTest.class, 'NotTest'));
            Assert.isFalse(DependencyV1.isBound(BindingTestHelper.TestInterface.class, 'Test'));
            Assert.isTrue(DependencyV1.inject(BindingTestHelper.TestInterface.class) instanceof BindingTestHelper.SingletonTest);

            try {
                DependencyV1.inject(BindingTestHelper.AbstractTest.class);
                Assert.fail();
            } catch (DependencyV1.APIException ae) {
                Assert.areEqual('Binding for BindingTestHelper.AbstractTest is not defined', ae.getMessage());
            }

            Assert.isTrue(DependencyV1.inject(BindingTestHelper.AbstractTest.class, 'Test') instanceof BindingTestHelper.PrototypeTest);

            try {
                DependencyV1.inject(BindingTestHelper.AbstractTest.class, 'NotTest');
                Assert.fail();
            } catch (DependencyV1.APIException ae) {
                Assert.areEqual('Binding for BindingTestHelper.AbstractTest for action NotTest is not defined', ae.getMessage());
            }

            try {
                DependencyV1.inject(BindingTestHelper.TestInterface.class, 'Test');
                Assert.fail();
            } catch (DependencyV1.APIException ae) {
                Assert.areEqual('Binding for BindingTestHelper.TestInterface for action Test is not defined', ae.getMessage());
            }

            MockerV1.validate();
        }
    }

    private static DependencyAPI createMock() {
        MockerV1 mocked = MockerV1.of(DependencyAPI.class);

        mocked
            .whenArgument(BindingTestHelper.TestInterface.class)
                .forMethod('isBound')
                    .called(1)
                    .returns(  true)
                .forMethod('inject')
                    .called(1)
                    .returns(new BindingTestHelper.SingletonTest())
            .whenArguments(BindingTestHelper.TestInterface.class, 'Test')
                .forMethod('isBound')
                    .called(1)
                    .returns(false)
                .forMethod('inject')
                    .called(1)
                    .throws(new DependencyV1.APIException('Binding for BindingTestHelper.TestInterface for action Test is not defined'))
            .whenArgument(BindingTestHelper.AbstractTest.class)
                .forMethod('isBound')
                    .called(1)
                    .returns(false)
                .forMethod('inject')
                    .called(1)
                    .throws(new DependencyV1.APIException('Binding for BindingTestHelper.AbstractTest is not defined'))
            .whenArguments(BindingTestHelper.AbstractTest.class, 'Test')
                .forMethod('isBound')
                    .called(1)
                    .returns(true)
                .forMethod('inject')
                    .called(1)
                .returns(new BindingTestHelper.PrototypeTest())
            .whenArguments(BindingTestHelper.AbstractTest.class, 'NotTest')
                .forMethod('isBound')
                    .called(1)
                    .returns(false)
                .forMethod('inject')
                    .called(1)
                    .throws(new DependencyV1.APIException('Binding for BindingTestHelper.AbstractTest for action NotTest is not defined'));

        return (DependencyAPI) mocked.mock();
    }

    @IsTest
    private static void testExtendedClassesAreInert() {
        ExtendedClass extended = new ExtendedClass();

        try {
            extended.inject(null);
            Assert.fail();
        } catch (DependencyV1.APIException ae) {
            Assert.areEqual('Access denied', ae.getMessage());
        }

        try {
            extended.inject(null, null);
            Assert.fail();
        } catch (DependencyV1.APIException ae) {
            Assert.areEqual('Access denied', ae.getMessage());
        }

        try {
            extended.isBound(null);
            Assert.fail();
        } catch (DependencyV1.APIException ae) {
            Assert.areEqual('Access denied', ae.getMessage());
        }

        try {
            extended.isBound(null, null);
            Assert.fail();
        } catch (DependencyV1.APIException ae) {
            Assert.areEqual('Access denied', ae.getMessage());
        }

        try {
            extended.bind(null, null);
            Assert.fail();
        } catch (DependencyV1.APIException ae) {
            Assert.areEqual('Access denied', ae.getMessage());
        }

        try {
            extended.bind(null, null, null);
            Assert.fail();
        } catch (DependencyV1.APIException ae) {
            Assert.areEqual('Access denied', ae.getMessage());
        }

        try {
            extended.reload();
            Assert.fail();
        } catch (DependencyV1.APIException ae) {
            Assert.areEqual('Access denied', ae.getMessage());
        }
    }

    private with sharing class ExtendedClass extends DependencyAPI {}
}