package FusionInventory::Agent::Task::Inventory::Generic::Drives::ASM;

use strict;
use warnings;

use parent 'FusionInventory::Agent::Task::Inventory::Module';

use English qw(-no_match_vars);

use FusionInventory::Agent::Tools;

sub isEnabled {
    return canRun('asmcmd');
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    # First try to find a user having GRID_HOME in his environment
    my ($user, $grid_home, $grid_sid);
    foreach $user (qw(grid oracle root)) {
        if ($user eq 'root') {
            $grid_home = $ENV{GRID_HOME};
            $grid_sid  = $ENV{ORACLE_SID};
        } else {
            $grid_home = getFirstLine(command => "su - $user -c 'echo \$GRID_HOME'");
            $grid_sid  = getFirstLine(command => "su - $user -c 'echo \$ORACLE_SID'");
            last if $grid_home;
        }
    }
    $grid_sid = "+ASM" unless $grid_sid;

    # Oracle documentation:
    # see https://docs.oracle.com/cd/E11882_01/server.112/e18951/asm_util004.htm#OSTMG94549
    # But also try oracle user if grid user doesn't exist, and finally try as root
    my $cmd = ($grid_home ? "ORACLE_HOME='$grid_home' ORACLE_SID=$grid_sid " : "")."asmcmd lsdg";
    $cmd = "su - $user -c \"$cmd\"" unless $user eq "root";
    my $diskgroups = _getDisksGroups(
        command => $cmd,
        logger  => $logger
    );

    return unless $diskgroups;

    # Add disks groups inventory as DRIVES
    foreach my $diskgroup (@{$diskgroups}) {
        my $name = $diskgroup->{NAME}
            or next;

        # Only report mounted group
        next unless ($diskgroup->{STATE} && $diskgroup->{STATE} eq 'MOUNTED');

        $inventory->addEntry(
            section => 'DRIVES',
            entry   => {
                LABEL   => $diskgroup->{NAME},
                VOLUMN  => 'diskgroup',
                TOTAL   => $diskgroup->{TOTAL},
                FREE    => $diskgroup->{FREE}
            }
        );
    }
}

sub _getDisksGroups {
    my (%params) = @_;

    my $handle = getFileHandle(%params);
    return unless $handle;

    my @groups = ();
    my $line_count = 0;
    while (my $line = <$handle>) {
        # Cleanup line
        chomp($line);
        $line = trimWhitespace($line);

        # Logic to skip header
        $line_count ++;
        next if ($line_count == 1 && $line =~ /^State.*Name$/);

        my @infos = split(/\s+/, $line);
        next unless @infos == 13 || @infos == 14;

        # Cleanup trailing slash on NAME
        $infos[$#infos] =~ s|/+$||;

        # Fix total against TYPE field
        my $total = int($infos[$#infos-6] || 0) - int($infos[$#infos-4] || 0);
        if ($infos[1] =~ /^NORMAL|HIGH$/) {
            $total /= $infos[1] eq 'HIGH' ? 3 : 2;
        }

        push @groups, {
            NAME        => $infos[$#infos] || 'NONAME',
            STATE       => $infos[0]  || 'UNKNOWN',
            TYPE        => $infos[1]  || 'EXTERN',
            TOTAL       => int($total),
            FREE        => int($infos[$#infos-3])
        };
    }

    close $handle;

    return \@groups;
}

1;
