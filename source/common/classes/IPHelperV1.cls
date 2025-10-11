/**
 * @description
 * <p>
 * Helper methods for IP address operations.
 * <p>
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../LICENSE target="_blank">MIT License</a>.
 * 
 * @author Mark Brennand
 */
@SuppressWarnings('PMD.AvoidGlobalModifier')
global with sharing class IPHelperV1 {

    /**
     * @description
     * <p>
     * Exception thrown on failure in API.
     */
    global with sharing class APIException extends Exception {}

    /**
     * @description
     * <p>
     * API representation of an IP address.
     */
    global interface Address {

        /**
         * @description
         * <p>
         * Check whether address conforms to given CIDR value.
         *
         * @param cidr The CIDR value to be checked against.
         *
         * @return True if address matches CIDR, false if not.
         */
        Boolean isAllowed(final String cidr);
    }

    /**
     * @description
     * <p>
     * Builds an Address representation of the given IP address string.
     *
     * @param ipAddress The IP address.
     *
     * @return The Address representation.
     */
    global static Address getAddress(final String ipAddress) {
        return new AddressImpl(ipAddress);
    }

    private with sharing class AddressImpl implements Address {
        private final Long address;

        private AddressImpl(final String ipAddress) {
            final List<String> parts = ipAddress.split('\\.');
            if (parts.size() != 4) {
                throw new APIException('Invalid IP address ' + ipAddress);
            }

            final Long part1;
            final Long part2;
            final Long part3;
            final Long part4;

            try {
                part1 = Long.valueOf(parts[0]);
                part2 = Long.valueOf(parts[1]);
                part3 = Long.valueOf(parts[2]);
                part4 = Long.valueOf(parts[3]);
            } catch(Exception e) {
                throw new APIException('Invalid IP address ' + ipAddress);
            }

            isValid(ipAddress, part1);
            isValid(ipAddress, part2);
            isValid(ipAddress, part3);
            isValid(ipAddress, part4);

            Long computed = part1;
            computed = (computed * 256) + part2;
            computed = (computed * 256) + part3;
            address = (computed * 256) + part4;
        }

        @SuppressWarnings('PMD.ApexDoc')
        public Boolean isAllowed(final String cidr) {
            final List<String> parts = cidr.split('/');
            if (parts.size() != 2) {
                throw new APIException('Invalid CIDR ' + cidr);
            }

            final AddressImpl cidrAddress;
            final Integer bits;
            try {
                cidrAddress = (AddressImpl) getAddress(parts[0]);
                bits = Integer.valueOf(parts[1]);
            } catch(Exception e) {
                throw new APIException('Invalid CIDR ' + cidr);
            }

            if (bits < 0 || bits > 32) {
                throw new APIException('Invalid CIDR ' + cidr);
            }

            return checkCIDR(cidrAddress, bits);
        }

        private void isValid(final String ipAddress, final Long value) {
            if (value < 0 || value > 255) {
                throw new APIException('Invalid IP address ' + ipAddress);
            }
        }

        private Boolean checkCIDR(final AddressImpl cidrAddress, final Integer bits) {
            final Long cidrBits = cidrAddress.address;
            Long mask = (1L << 31);

            for (Integer bit = 0; bit < bits; bit++) {
                if ((cidrBits & mask) != (address & mask)) {
                    return false;
                }
                mask >>= 1;
            }

            return true;
        }
    }
}