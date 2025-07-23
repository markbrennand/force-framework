/**
 * @description
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../../LICENSE target="_blank">MIT License</a>.
 * <br><br>
 * Unit tests for Optional class.
 *
 * @author Mark Brennand
 */
@IsTest
public with sharing class OptionalTests {

    @IsTest
    private static void testEmpty() {
        OptionalV1 opt = OptionalV1.empty();
        Assert.isFalse(opt.isPresent());
        try {
            opt.get();
            Assert.fail();
        } catch(OptionalV1.NoSuchElementException nsee) {}
    }

    @IsTest
    private static void testOf() {
        String value = 'TEST';
        OptionalV1 opt = OptionalV1.of(value);
        Assert.isTrue(opt.isPresent());
        Assert.areEqual('TEST', opt.get());

        opt = OptionalV1.of(null);
        Assert.isTrue(opt.isPresent());
        Assert.isNull(opt.get());
    }

    @IsTest
    private static void testOfNullable() {
        OptionalV1 opt = OptionalV1.ofNullable('TEST');
        Assert.isTrue(opt.isPresent());
        Assert.areEqual('TEST', opt.get());

        opt = OptionalV1.ofNullable(null);
        Assert.isFalse(opt.isPresent());
    }

    @IsTest
    private static void testOrElse() {
        OptionalV1 opt = OptionalV1.of('TEST');
        Assert.areEqual('TEST', opt.orElse('OTHER'));

        opt = OptionalV1.empty();
        Assert.areEqual('OTHER', opt.orElse('OTHER'));
    }

    @IsTest
    private static void TestCall() {
        Assert.isFalse(OptionalV1.empty().call(new TestFunction()).isPresent());
        Assert.areEqual(1, OptionalV1.of('one').call(new TestFunction()).get());
        Assert.areEqual(2, OptionalV1.of('two').call(new TestFunction()).get());
    }

    @IsTest
    private static void TestCallChaining() {
        Assert.isFalse(OptionalV1.empty().call(new TestFunction()).call(new TestFunction()).isPresent());
        Assert.areEqual(1, OptionalV1.of(1).call(new TestFunction()).call(new TestFunction()).get());
        Assert.areEqual(2, OptionalV1.of(2).call(new TestFunction()).call(new TestFunction()).get());
    }

    private with sharing class TestFunction implements OptionalV1.Function {
        public OptionalV1 apply(final OptionalV1 value) {
            if (!value.isPresent()) {
                return value;
            }

            if (value.get() instanceof String) {
                return value.get() == 'one' ? OptionalV1.of(1) : OptionalV1.of(2);
            } else {
                return value.get() == 1 ? OptionalV1.of('one') : OptionalV1.of('two');
            }
        }
    }
}