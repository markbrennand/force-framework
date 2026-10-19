/**
 * @description
 * <p>
 * Example of how a helper can be used with the MDN like methods of ArrayV1.
 *
 * <p>
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../LICENSE target="_blank">MIT License</a>.
 * 
 * @author Mark Brennand
 */
global with sharing class ExampleHelper {
    private enum Option { Caseless }

    public final static String Caseless = Option.Caseless.name();

    private final static Set<String> VALID_OPTIONS = new Set<String> { Caseless };

    private ExampleHelper() {}

    private static Boolean contains(final String value, final String match, final Set<Option> options) {
        if (options.contains(Option.Caseless)) {
            return value.toLowerCase().contains(match.toLowerCase());
        } else {
            return value.contains(match);
        }
    }

    private static String append(final String value, final String postfix) {
        return value + ' ' + postfix;
    }

    public static forcefw.ArrayV1.Callback contains(final String value) {
        return contains(new Set<String>(), value);
    }

    public static forcefw.ArrayV1.Callback contains(final Set<String> options, final String value) {
        return new Callback('contains', value, options);
    }

    public static forcefw.ArrayV1.Callback append(final String value) {
        return new Callback('append', value, new Set<String>());
    }

    private with sharing class Callback extends forcefw.ArrayV1.Callback {
        private final String action;
        private final forcefw.OptionalV1 value;
        private final Set<Option> options;

        public Callback(final String action) {
            this.action = action;
            this.value = forcefw.OptionalV1.empty();
            this.options = new Set<Option>();
        }

        public Callback(final String action, final Object value, final Set<String> options) {
            this.action = action;
            this.value = forcefw.OptionalV1.of(value);
            this.options = checkOptions(options);
        }

        public override forcefw.OptionalV1 function(Object element, forcefw.OptionalV1 currentValue, Integer index) {
            switch on action {
                when 'contains' {
                    return forcefw.OptionalV1.of(contains((String) element, (String) value.get(), options));
                }
                when 'append' {
                    return forcefw.OptionalV1.of(append((String) element, (String) value.get()));
                }
            }

            throw new forcefw.ArrayV1.APIException('Unsupported action ' + action);
        }

        private Set<Option> checkOptions(final Set<String> options) {
            final Set<String> copy = options.clone();
            copy.removeAll(VALID_OPTIONS);

            if (!copy.isEmpty()) {
                throw new forcefw.ArrayV1.APIException('Unsupported options ' + copy);
            }

            final Set<Option> result = new Set<Option>();
            for (String name : options) {
                result.add(Option.valueOf(name));
            }

            return result;
        }
    }
}