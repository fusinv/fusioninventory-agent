package FusionInventory::Agent::Task::Inventory::OS::Linux::Archs::ARM::CPU;

use strict;
use warnings;

use English qw(-no_match_vars);

use FusionInventory::Agent::Tools;

sub isInventoryEnabled { 
    return -r '/proc/cpuinfo';
}

sub doInventory {
    my $params = shift;
    my $inventory = $params->{inventory};

    my $handle;
    if (!open $handle, '<', '/proc/cpuinfo') {
        warn "Can't open /proc/cpuinfo: $ERRNO";
        return;
    }

    my @cpu;
    my $current;

    while (<$handle>) {
        if (/^Processor\s+:\s*:/) {

            if ($current) {
                $inventory->addCPU($current);
            }

            $current = {
                ARCH => 'ARM',
            };

        }
        $current->{TYPE} = $1 if /Processor\s+:\s+(\S.*)/;
    }
    close $handle;

    # The last one
    $inventory->addCPU($current);
}

1;
