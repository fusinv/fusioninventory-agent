package FusionInventory::Agent::SNMP::MibSupport::UPS;

use strict;
use warnings;

use parent 'FusionInventory::Agent::SNMP::MibSupportTemplate';

use FusionInventory::Agent::Tools;
use FusionInventory::Agent::Tools::SNMP;

use constant    apc => '.1.3.6.1.4.1.318' ;
use constant    riello => '.1.3.6.1.4.1.5491' ;

# See UPS-MIB

use constant    upsMIB  => '.1.3.6.1.2.1.33' ;
use constant    upsIdentManufacturer        => upsMIB  .'.1.1.1.0' ;
use constant    upsIdentModel               => upsMIB  .'.1.1.2.0' ;
use constant    upsIdentUPSSoftwareVersion  => upsMIB  .'.1.1.3.0' ;

my $match = apc.'|'.upsMIB.'|'.riello;

our $mibSupport = [
    {
        name        => "apc",
        sysobjectid => qr/^$match/
    }
];

sub getModel {
    my ($self) = @_;

    return $self->get(upsIdentModel);
}

sub getFirmware {
    my ($self) = @_;

    return $self->get(upsIdentUPSSoftwareVersion);
}

sub getManufacturer {
    my ($self) = @_;

    return getCanonicalString($self->get(upsIdentManufacturer));
}

sub getType {
    # TODO remove when POWER is supported on server-side and replace by 'POWER'
    return 'NETWORKING';
}

1;

__END__

=head1 NAME

Inventory module for APC modules

=head1 DESCRIPTION

The module enhances APC devices support.
