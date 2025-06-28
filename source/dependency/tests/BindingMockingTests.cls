/**
 * MIT License
 *
 * Copyright (c) 2025 Mark Brennand
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */
/**
 * @description
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
    static void testMocking() {
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
            } catch (Dependency.APIException ae) {
                Assert.areEqual('Binding for BindingTestHelper.AbstractTest is not defined', ae.getMessage());
            }

            Assert.isTrue(DependencyV1.inject(BindingTestHelper.AbstractTest.class, 'Test') instanceof BindingTestHelper.PrototypeTest);

            try {
                DependencyV1.inject(BindingTestHelper.AbstractTest.class, 'NotTest');
                Assert.fail();
            } catch (Dependency.APIException ae) {
                Assert.areEqual('Binding for BindingTestHelper.AbstractTest for action NotTest is not defined', ae.getMessage());
            }

            try {
                DependencyV1.inject(BindingTestHelper.TestInterface.class, 'Test');
                Assert.fail();
            } catch (Dependency.APIException ae) {
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
                    .throws(new Dependency.APIException('Binding for BindingTestHelper.TestInterface for action Test is not defined'))
            .whenArgument(BindingTestHelper.AbstractTest.class)
                .forMethod('isBound')
                    .called(1)
                    .returns(false)
                .forMethod('inject')
                    .called(1)
                    .throws(new Dependency.APIException('Binding for BindingTestHelper.AbstractTest is not defined'))
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
                    .throws(new Dependency.APIException('Binding for BindingTestHelper.AbstractTest for action NotTest is not defined'));

        return (DependencyAPI) mocked.mock();
    }
}
