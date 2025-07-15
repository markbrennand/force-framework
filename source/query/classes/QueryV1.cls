/**
 * @description
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../../LICENSE target="_blank">MIT License</a>.
 * <br><br>
 * Class providing Query API.
 *
 * @author Mark Brennand
 */
global with sharing class QueryV1 {

    global enum Security { NONE, SECURITY_ENFORCED, USER_MODE }

    global with sharing class AggregatedField {
        public final SObjectField field { public get; private set; }
        public final Optional returnAs  { public get; private set; }
        public final Optional function  { public get; private set; }

        global AggregatedField(final SObjectField field, final Optional function, final Optional returnAs) {
            if (returnAs.isPresent() && ! (returnAs.get() instanceof String)) {
                throw new QueryException('Return as qualifier for field must be a String');
            }

            if (function.isPresent() && ! (function.get() instanceof String)) {
                throw new QueryException('Function must be a String');
            }

            this.field = field;
            this.returnAs = returnAs;
            this.function = function;
        }

        public override String toString() {
            if (returnAs.isPresent()) {
                if (function.isPresent()) {
                    return ArrayV1.over(
                            new List<String> {
                                    (String) function.get(),
                                    '(',
                                    field.getDescribe().name,
                                    ') ',
                                    (String) returnAs.get()
                            }
                    ).join('');
                } else {
                    return ArrayV1.over(
                            new List<String> {
                                    field.getDescribe().name,
                                    ' ',
                                    (String) returnAs.get()
                            }
                    ).join('');
                }
            } else {
                if (function.isPresent()) {
                    return ArrayV1.over(
                            new List<String> {
                                    (String) function.get(),
                                    '(',
                                    field.getDescribe().name,
                                    ')'
                            }
                    ).join('');
                } else {
                    return field.getDescribe().name;
                }
            }
        }
    }

    global interface API {
        SObjectType type();
        API type(final SObjectType type);
        API security(final AccessLevel security);
        API count();
        API returning(final Set<SObjectField> fields);
        API returning(final SObjectField joinField, final Set<SObjectField> fields);
        API returning(final Set<AggregatedField> fields);
        API matching(final String condition);
        API ascending(final SObjectField field);
        API descending(final SObjectField field);
        API ascending(final SObjectField field, final Boolean nullsFirst);
        API descending(final SObjectField field, final Boolean nullsFirst);
        API aggregated(final Set<SObjectField> fields);
        API children(final API query);
        API max(final Optional max);
        API offset(final Optional offset);
        Optional execute(final Optional bindVars);
    }

    global static API of(final SObjectType type) {
        return QueryAPI.API.type(type);
    }
}