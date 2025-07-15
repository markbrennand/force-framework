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
        Optional opt = Optional.empty();
        Assert.isFalse(opt.isPresent());
        try {
            opt.get();
            Assert.fail();
        } catch(Optional.NoSuchElementException nsee) {}
    }

    @IsTest
    private static void testOf() {
        String value = 'TEST';
        Optional opt = Optional.of(value);
        Assert.isTrue(opt.isPresent());
        Assert.areEqual('TEST', opt.get());

        opt = Optional.of(null);
        Assert.isTrue(opt.isPresent());
        Assert.isNull(opt.get());
    }

    @IsTest
    private static void testOfNullable() {
        Optional opt = Optional.ofNullable('TEST');
        Assert.isTrue(opt.isPresent());
        Assert.areEqual('TEST', opt.get());

        opt = Optional.ofNullable(null);
        Assert.isFalse(opt.isPresent());
    }

    @IsTest
    private static void testOrElse() {
        Optional opt = Optional.of('TEST');
        Assert.areEqual('TEST', opt.orElse('OTHER'));

        opt = Optional.empty();
        Assert.areEqual('OTHER', opt.orElse('OTHER'));
    }

    @IsTest
    private static void TestCall() {
        Assert.isFalse(Optional.empty().call(new TestFunction()).isPresent());
        Assert.areEqual(1, Optional.of('one').call(new TestFunction()).get());
        Assert.areEqual(2, Optional.of('two').call(new TestFunction()).get());
    }

    @IsTest
    private static void TestCallChaining() {
        Assert.isFalse(Optional.empty().call(new TestFunction()).call(new TestFunction()).isPresent());
        Assert.areEqual(1, Optional.of(1).call(new TestFunction()).call(new TestFunction()).get());
        Assert.areEqual(2, Optional.of(2).call(new TestFunction()).call(new TestFunction()).get());
    }

    private with sharing class TestFunction implements Optional.Function {
        public Optional apply(final Optional value) {
            if (!value.isPresent()) {
                return value;
            }

            if (value.get() instanceof String) {
                return value.get() == 'one' ? Optional.of(1) : Optional.of(2);
            } else {
                return value.get() == 1 ? Optional.of('one') : Optional.of('two');
            }
        }
    }
}