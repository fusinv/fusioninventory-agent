package FusionInventory::Agent::Task::Inventory::Win32::Modems;

use strict;
use warnings;

use Storable 'dclone';

use FusionInventory::Agent::Tools::Win32;

sub isEnabled {
    my (%params) = @_;
    return 0 if $params{no_category}->{modem};
    return 1;
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $wmiParams = {};
    $wmiParams->{WMIService} = dclone ($params{inventory}->{WMIService}) if $params{inventory}->{WMIService};
    foreach my $object (getWMIObjects(
        %$wmiParams,
        class      => 'Win32_POTSModem',
        properties => [ qw/Name DeviceType Model Description/ ]
    )) {

        $inventory->addEntry(
            section => 'MODEMS',
            entry   => {
                NAME        => $object->{Name},
                TYPE        => $object->{DeviceType},
                MODEL       => $object->{Model},
                DESCRIPTION => $object->{Description},
            }
        );
    }
}

1;
