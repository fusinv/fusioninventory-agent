#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use Test::Deep;
use Test::Exception;
use Test::More;
use Test::NoWarnings;

use Data::Dumper;

use FusionInventory::Test::Inventory;
use FusionInventory::Agent::Task::Inventory::Generic::Ipmi::Fru::Controllers;

my %tests = (
    'dell-r630' => [
        {
            'MANUFACTURER' => 'DELL',
            'MODEL'        => '0GDJ3J',
            'NAME'         => 'Dell Storage Cntlr. H330 Mini-',
            'REV'          => 'A03',
            'SERIAL'       => 'CN7792169T02BB'
        },
        {
            'MANUFACTURER' => 'DELL',
            'MODEL'        => '0MG81C',
            'NAME'         => 'DRIVE BACKPLANE',
            'REV'          => 'A02',
            'SERIAL'       => 'CNIVC007CD4368'
        },
        {
            'MANUFACTURER' => 'DELL',
            'MODEL'        => '0G8RPD',
            'NAME'         => 'BRCM 10G/GbE 2+2P 57800-t rNDC',
            'REV'          => 'A00',
            'SERIAL'       => 'CN7543546H00HB'
        }
    ],
    'dell-r640' => [
        {
            'MANUFACTURER' => 'DELL',
            'MODEL'        => '0PGJ4P',
            'NAME'         => 'DRIVE BACKPLANE',
            'REV'          => 'A00',
            'SERIAL'       => 'CNIVC009C10097'
        },
        {
            'MANUFACTURER' => 'DELL',
            'MODEL'        => '00878M',
            'NAME'         => 'Dell Storage Cntlr. H740P - Mini',
            'REV'          => 'A03',
            'SERIAL'       => 'CNFCP0005M01NC'
        },
        {
            'MANUFACTURER' => 'DELL',
            'MODEL'        => '01224N',
            'NAME'         => 'BRCM 2P 1G BT + 2P 10G BT rNDC',
            'REV'          => 'A06',
            'SERIAL'       => 'VNFCVBA02O00AZ'
        }
    ],
    'dell-r720' => [
        {
            'MANUFACTURER' => 'DELL',
            'MODEL'        => '00JDG3',
            'NAME'         => 'DRIVE BACKPLANE',
            'REV'          => 'A00',
            'SERIAL'       => 'CN7543547100IK'
        },
        {
            'MANUFACTURER' => 'DELL',
            'MODEL'        => '0TY8F9',
            'NAME'         => 'Dell Storage Cntlr. H710P-Mini',
            'REV'          => 'A03',
            'SERIAL'       => 'CN7792147F03B1'
        },
        {
            'MANUFACTURER' => 'DELL',
            'MODEL'        => '0PGXHP',
            'NAME'         => 'DRIVE BACKPLANE',
            'REV'          => 'A02',
            'SERIAL'       => 'CN7792146F02MU'
        },
        {
            'MANUFACTURER' => 'DELL',
            'MODEL'        => '0FM487',
            'NAME'         => 'BRCM GbE 4P 5720-t rNDC',
            'REV'          => 'A03',
            'SERIAL'       => 'CN7543545U06YB'
        }
    ],
    'hp-dl360-gen7' => [],
    'hp-dl360-gen8' => [],
);

plan tests => 2 * (scalar keys %tests) + 1;

foreach my $test (keys %tests) {
    my $file = "resources/generic/ipmitool/fru/$test";
    my $inventory = FusionInventory::Test::Inventory->new();

    lives_ok {
        FusionInventory::Agent::Task::Inventory::Generic::Ipmi::Fru::Controllers::doInventory(
            inventory => $inventory,
            file      => $file
        );
    } "test $test: doInventory()";

    my $ctrl = $inventory->getSection('CONTROLLERS') || [];

    cmp_deeply(
        $ctrl,
        bag(@{$tests{$test}}),
        "test $test: section"
    );
}
