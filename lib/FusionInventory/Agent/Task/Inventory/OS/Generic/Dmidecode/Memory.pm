package FusionInventory::Agent::Task::Inventory::OS::Generic::Dmidecode::Memory;

use strict;
use warnings;

use English qw(-no_match_vars);

sub doInventory {
    my $params = shift;
    my $inventory = $params->{inventory};

    my ($memories) = parseDmidecode('/usr/sbin/dmidecode', '-|');

    foreach my $memory (@$memories) {
        $inventory->addMemory($memory);
    }
}

sub parseDmidecode {
    my ($file, $mode) = @_;

    my $handle;
    if (!open $handle, $mode, $file) {
        warn "Can't open $file: $ERRNO";
        return;
    }

    my ($memories, $memory, $type);
    my $slot = 0;

    while (my $line = <$handle>) {
        chomp $line;

        if ($line =~ /DMI type (\d+)/i) {
            $type = $1;
            if ($memory) {
                $memory->{NUMSLOTS} = ++$slot;
                push @$memories, $memory;
                undef $memory;
            }
            next;
        }

        next unless defined $type;

        if ($type == 17) {
            if ($line =~ /^\s+Size:\s+(\S+)/i) {
                $memory->{CAPACITY} = $1;
            } elsif ($line =~ /^\s+Form Factor:\s+(.+)/i) {
                $memory->{DESCRIPTION} = $1;
            } elsif ($line =~ /^\s+Locator:\s*(.+)/i) {
                $memory->{CAPTION} = $1;
            } elsif ($line =~ /^\s+Speed:\s*(.+)/i) {
                $memory->{SPEED} = $1;
            } elsif ($line =~ /^\s+Type:\s*(.+)/i) {
                $memory->{TYPE} = $1;
            } elsif ($line =~ /^\s+Serial Number:\s*(.+)/i) {
                $memory->{SERIALNUMBER} = $1;
            }
        }

    }
    close $handle;

    return $memories;
}

1;
