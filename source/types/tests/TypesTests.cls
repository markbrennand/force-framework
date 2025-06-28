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
 * Unit tests for Types class.
 *
 * @author Mark Brennand
 */
@IsTest
public with sharing class TypesTests {

    @IsTest
    static void testLoadValidClass() {
        Type t = TypesV1.load('Integer');
        Assert.areEqual('Integer', t.getName());
    }

    @IsTest
    static void testLoadNonExistentClass() {
        try {
            Type t = TypesV1.load('TypeHelperTests.NoSuchClass');
            Assert.fail();
        } catch(TypesV1.APIException te) {
            Assert.areEqual('Class TypeHelperTests.NoSuchClass does not exist', te.getMessage());
        }
    }

    @IsTest
    static void testNewInstanceOfValidClass() {
        Object instance = TypesV1.newInstance(TestClass.class);
        Assert.isTrue(instance instanceof TestClass);
    }

    @IsTest
    static void testNewInstanceOfInvalidClasses() {
        try {
            TypesV1.newInstance(Integer.class);
            Assert.fail();
        } catch(TypesV1.APIException te) {
            Assert.isTrue(te.getMessage().endsWith('Integer could not be constructed'));
        }

        try {
            TypesV1.newInstance(TestInterface.class);
            Assert.fail();
        } catch(TypesV1.APIException te) {
            Assert.isTrue(te.getMessage().endsWith('TypesTests.TestInterface could not be constructed'));
        }

        try {
            TypesV1.newInstance(AbstractTestClass.class);
            Assert.fail();
        } catch(TypesV1.APIException te) {
            Assert.isTrue(te.getMessage().endsWith('TypesTests.AbstractTestClass could not be constructed'));
        }
    }

    @IsTest
    static void testFactory() {
        Assert.isTrue(TypesV1.newInstance(TestFactory.class) instanceof TestClass);
    }

    public interface TestInterface {}

    public with sharing class TestClass {}

    public with sharing abstract class AbstractTestClass {}

    public with sharing class TestFactory implements TypesV1.Factory {

        public Object newInstance() {
            return new TestClass();
        }
    }
}