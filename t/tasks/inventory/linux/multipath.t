#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use Test::Deep;
use Test::Exception;
use Test::More;
use Test::NoWarnings;

use FusionInventory::Agent::Tools::Linux;

my %multipath_tests = (
    multipath1 => {
        names_in => [
            'sdo' .. 'sdz',
            'sdaa' .. 'sdaz',
            'sdba' .. 'sdbj',
        ],
        names_out => [
            'sdo' .. 'sdz',
            'sdaa' .. 'sdal',
        ],
    },
    multipath2 => {
        names_in => [
            'sda' .. 'sdz',
            'sdaa' .. 'sdaz',
            'sdba' .. 'sdbz',
            'sdca' .. 'sdcz',
            'sdda' .. 'sddz',
            'sdea' .. 'sdej',
        ],
        names_out => [
            'sda' .. 'sdz',
            'sdaa' .. 'sdaz',
            'sdba' .. 'sdbs',
        ],
    }
);

plan tests => (scalar keys %multipath_tests) + 1;

foreach my $test (keys %multipath_tests) {
    my $file = "resources/linux/multipath/$test";
    my @names = FusionInventory::Agent::Tools::Linux::_filterMultipath(
        file  => $file,
        names => $multipath_tests{$test}->{names_in}
    );
    cmp_bag(\@names, $multipath_tests{$test}->{names_out}, "$test: parsing");
}
