package FusionInventory::Agent::Task::Inventory::Linux::Networks::DockerMacvlan;

use strict;
use warnings;

use parent 'FusionInventory::Agent::Task::Inventory::Module';

use JSON::PP;
use FusionInventory::Agent::Tools;
use FusionInventory::Agent::Tools::Network;

sub isEnabled {
    return canRun('docker');
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    my @networks = _getMacvlanNetworks(logger => $logger);

    foreach my $network (@networks) {
        my @interfaces = _getInterfaces(logger => $logger, networkId => $network);
        foreach my $interface (@interfaces) {
            $inventory->addEntry(
                section => 'NETWORKS',
                entry   => $interface
            );
        }
    }
}

sub _getMacvlanNetworks {
    my (%params) = (
        command => 'docker network ls --filter driver=macvlan -q',
        @_
    );
    my $handle = getFileHandle(%params);
    return unless $handle;

    my @networks;

    while (my $line = <$handle>) {
        chomp($line);
        push @networks, $line;
    }

    close $handle;
    return @networks;
}

sub _getInterfaces {
    my (%params) = @_;

    $params{command} = "docker network inspect $params{networkId}";

    my $lines = getAllLines(%params);
    my @interfaces;

    eval {
        my $json = JSON::PP->new;
        my $data = $json->decode($lines);

        foreach my $record (@$data) {
            while (my ($k, $container) = each %{$record->{Containers}}) {
                my $interface = {
                    DESCRIPTION => $record->{Name} . "@" . $container->{Name},
                    MACADDR     => $container->{MacAddress},
                    STATUS      => 'Up',
                    TYPE        => 'ethernet',
                };
                if ($container->{IPv4Address} =~ /^($ip_address_pattern)\/(\d+)$/) {
                    $interface->{IPADDRESS} = $1;
                    $interface->{IPMASK} = getNetworkMask($2);
                }
                if ($container->{IPv6Address} =~ /^(\S+)\/(\d+)$/) {
                    $interface->{IPADDRESS6} = $1;
                    $interface->{IPMASK6} = getNetworkMaskIPv6($2);
                }
                push @interfaces, $interface;
            } 
        }
    };

    return @interfaces;
}

1;
