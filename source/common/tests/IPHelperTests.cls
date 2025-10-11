/**
 * @description
 * <p>
 * Unit tests for IPHelper class.
 * <p>
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../LICENSE target="_blank">MIT License</a>.
 * 
 * @author Mark Brennand
 */
@IsTest
public with sharing class IPHelperTests {

    @IsTest
    private static void testValidAddresses() {
        for (String part1 : new List<String> { '0', '128', '255' }) {
            for (String part2 : new List<String> { '0', '128', '255' }) {
                for (String part3 : new List<String> { '0', '128', '255' }) {
                    for (String part4 : new List<String> { '0', '128', '255' }) {
                        IPHelperV1.getAddress(String.join(new List<String> { part1, part2, part3, part4 }, '.'));
                    }
                }
            }
        }
    }

    @IsTest
    private static void testInvalidAddresses() {
        try {
            IPHelperV1.getAddress('192');
            Assert.fail();
        } catch(IPHelperV1.APIException ae) {
            Assert.areEqual('Invalid IP address 192', ae.getMessage());
        }

        try {
            IPHelperV1.getAddress('192..');
            Assert.fail();
        } catch(IPHelperV1.APIException ae) {
            Assert.areEqual('Invalid IP address 192..', ae.getMessage());
        }

        try {
            IPHelperV1.getAddress('192.150');
            Assert.fail();
        } catch(IPHelperV1.APIException ae) {
            Assert.areEqual('Invalid IP address 192.150', ae.getMessage());
        }

        try {
            IPHelperV1.getAddress('192.150..');
            Assert.fail();
        } catch(IPHelperV1.APIException ae) {
            Assert.areEqual('Invalid IP address 192.150..', ae.getMessage());
        }

        try {
            IPHelperV1.getAddress('192.150.50');
            Assert.fail();
        } catch(IPHelperV1.APIException ae) {
            Assert.areEqual('Invalid IP address 192.150.50', ae.getMessage());
        }

        try {
            IPHelperV1.getAddress('192.150.50.');
            Assert.fail();
        } catch(IPHelperV1.APIException ae) {
            Assert.areEqual('Invalid IP address 192.150.50.', ae.getMessage());
        }

        for (String part1 : new List<String> { '0', 'a', '-1', '256' }) {
            for (String part2 : new List<String> { '0', 'a', '-1', '256' }) {
                for (String part3 : new List<String> { '0', 'a', '-1', '256' }) {
                    for (String part4 : new List<String> { '0', 'a', '-1', '256' }) {
                        try {
                            IPHelperV1.getAddress(String.join(new List<String>{
                                    part1, part2, part3, part4
                            }, '.'));
                            Assert.isTrue(part1 == '0' && part2 == '0' && part3 == '0' && part4 == '0');
                        } catch(IPHelperV1.APIException ae) {
                            Assert.isFalse(part1 == '0' && part2 == '0' && part3 == '0' && part4 == '0');
                            Assert.isTrue(ae.getMessage().startsWith('Invalid IP address'));
                        }
                    }
                }
            }
        }
    }

    @IsTest
    private static void testCIDR() {
        IPHelperV1.Address address = IPHelperV1.getAddress('192.150.50.1');
        for (String cidr : new Set<String> { '192.150.50.0/24', '192.150.50.0/31', '192.150.50.1/32', '192.150.50.1/24', '191.150.50.0/0'}) {
            Assert.isTrue(address.isAllowed(cidr));
        }

        for (String cidr : new Set<String> { '191.150.50.0/24', '192.151.50.0/24', '192.150.51.0/24', '192.150.50.0/32'}) {
            Assert.isFalse(address.isAllowed(cidr));
        }
    }

    @IsTest
    private static void testInvalidCIDR() {
        IPHelperV1.Address address = IPHelperV1.getAddress('192.150.50.1');

        for (String cidr : new Set<String> { '192.150.50.0', '192.150.50.256/24', '192.150.50.0/-1', '192.150.50.0/33'}) {
            try {
                address.isAllowed(cidr);
                Assert.fail();
            } catch(IPHelperV1.APIException ae) {
                Assert.areEqual('Invalid CIDR ' + cidr, ae.getMessage());
            }
        }
    }
}