#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use FusionInventory::Agent::Task::Inventory::Input::Generic::USB;

my %lsusb_tests = (
    'dell-xt2' => [
        {
            VENDORID   => '1d6b',
            SUBCLASS   => '0',
            CLASS      => '9',
            PRODUCTID  => '0001',
            SERIAL     => '0000',
        },
        {
            VENDORID   => '0a5c',
            SUBCLASS   => '0',
            CLASS      => '9',
            PRODUCTID  => '4500',
        },
        {
            VENDORID   => '413c',
            SUBCLASS   => '1',
            CLASS      => '3',
            PRODUCTID  => '8161',
        },
        {
            VENDORID   => '413c',
            SUBCLASS   => '1',
            CLASS      => '3',
            PRODUCTID  => '8162',
        },
        {
            VENDORID   => '413c',
            SUBCLASS   => '1',
            CLASS      => '254',
            PRODUCTID  => '8160',
        },
        {
            CLASS     => '9',
            SERIAL    => '0000',
            SUBCLASS  => '0',
            VENDORID  => '1d6b',
            PRODUCTID => '0001'
        },
        {
            CLASS     => '9',
            SERIAL    => '0000',
            SUBCLASS  => '0',
            VENDORID  => '1d6b',
            PRODUCTID => '0001'
        },
        {
            VENDORID  => '0a5c',
            SERIAL    => '0123456789ABCD',
            SUBCLASS  => '0',
            CLASS     => '254',
            PRODUCTID => '5801',
        },
        {
            CLASS     => '9',
            SERIAL    => '0000',
            SUBCLASS  => '0',
            VENDORID  => '1d6b',
            PRODUCTID => '0001'
        },
        {
            CLASS     => '9',
            SERIAL    => '0000',
            SUBCLASS  => '0',
            VENDORID  => '1d6b',
            PRODUCTID => '0001'
        },
        {
            CLASS     => '0',
            SUBCLASS  => '0',
            VENDORID  => '1b96',
            PRODUCTID => '0001'
        },
        {
            CLASS     => '9',
            SERIAL    => '0000',
            SUBCLASS  => '0',
            VENDORID  => '1d6b',
            PRODUCTID => '0001'
        },
        {
            VENDORID  => '047d',
            SUBCLASS  => '1',
            CLASS     => '3',
            PRODUCTID => '101f',
        },
        {
            CLASS     => '9',
            SERIAL    => '0000',
            SUBCLASS  => '0',
            VENDORID  => '1d6b',
            PRODUCTID => '0002'
        },
        {
            CLASS     => '9',
            SERIAL    => '0000',
            SUBCLASS  => '0',
            VENDORID  => '1d6b',
            PRODUCTID => '0002'
        }
    ]
);

my %usb_tests = (
    'dell-xt2' => [
        {
            VENDORID     => '0a5c',
            SUBCLASS     => '0',
            CLASS        => '9',
            PRODUCTID    => '4500',
            MANUFACTURER => 'Broadcom Corp.',
            CAPTION      => 'BCM2046B1 USB 2.0 Hub (part of BCM2046 Bluetooth)'
        },
        {
            VENDORID     => '413c',
            SUBCLASS     => '1',
            CLASS        => '3',
            PRODUCTID    => '8161',
            MANUFACTURER => 'Dell Computer Corp.',
            CAPTION      => 'Integrated Keyboard'
        },
        {
            VENDORID     => '413c',
            SUBCLASS     => '1',
            CLASS        => '3',
            PRODUCTID    => '8162',
            MANUFACTURER => 'Dell Computer Corp.',
            CAPTION      => 'Integrated Touchpad [Synaptics]'
        },
        {
            VENDORID     => '413c',
            SUBCLASS     => '1',
            CLASS        => '254',
            PRODUCTID    => '8160',
            MANUFACTURER => 'Dell Computer Corp.',
            CAPTION      => 'Wireless 365 Bluetooth'
        },
        {
            VENDORID     => '0a5c',
            SERIAL       => '0123456789ABCD',
            SUBCLASS     => '0',
            CLASS        => '254',
            PRODUCTID    => '5801',
            MANUFACTURER => 'Broadcom Corp.',
            CAPTION      => 'BCM5880 Secure Applications Processor with fingerprint swipe sensor'
        },
        {
            VENDORID     => '047d',
            SUBCLASS     => '1',
            CLASS        => '3',
            PRODUCTID    => '101f',
            MANUFACTURER => 'Kensington',
            CAPTION      => 'PocketMouse Pro'
        }
    ]
);

plan tests => (scalar keys %lsusb_tests) + (scalar keys %usb_tests);

foreach my $test (keys %lsusb_tests) {
    my $file = "resources/generic/lsusb/$test";
    my @devices = FusionInventory::Agent::Task::Inventory::Input::Generic::USB::_getDevicesFromLsusb(file => $file);
    is_deeply(\@devices, $lsusb_tests{$test}, "$test lsusb parsing");
}

foreach my $test (keys %usb_tests) {
    my $file = "resources/generic/lsusb/$test";
    my @devices = FusionInventory::Agent::Task::Inventory::Input::Generic::USB::_getDevices(file => $file, datadir => './share');
    is_deeply(\@devices, $usb_tests{$test}, "$test usb devices retrieval");
}
