package FusionInventory::Agent::Task::Inventory::Linux::Videos;

use strict;
use warnings;

use FusionInventory::Agent::Tools;
use FusionInventory::Agent::Tools::Unix;

sub isEnabled {
    my (%params) = @_;
    return 0 if $params{no_category}->{video};
    return 1;
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    $logger->debug("retrieving display information:");
  
    my @nvidiasmiData;
    if (canRun('nvidia-smi')) {
	@nvidiasmiData = _getNvidiaSmiData(
            command => 'nvidia-smi --format=csv,noheader --query-gpu=gpu_name,gpu_serial,memory.total,gpu_bus_id,vbios_version,driver_version',
            logger  => $logger
        );
         $logger->debug_result(
             action => 'running nvidia-smi command',
             data   => @nvidiasmiData
         );
    } else {
        $logger->debug_result(
             action => 'running nvidia-smi command',
             status => 'command not available'
        );
    }


    my $ddcprobeData;
    if (canRun('ddcprobe')) {
        $ddcprobeData = _getDdcprobeData(
            command => 'ddcprobe',
            logger  => $logger
        );
         $logger->debug_result(
             action => 'running ddcprobe command',
             data   => $ddcprobeData
         );
    } else {
        $logger->debug_result(
             action => 'running ddcprobe command',
             status => 'command not available'
        );
    }

    my $xorgData;

    my $xorgPid;
    foreach my $process (getProcesses(logger  => $logger)) {
        next unless $process->{CMD} =~ m{
            ^
            (?:
                /usr/bin
                |
                /usr/X11R6/bin
                |
                /etc/X11
            )
            /X
        }x;
        $xorgPid = $process->{PID};
        last;
    }

    if ($xorgPid) {
        my $link = "/proc/$xorgPid/fd/0";
        if (-r $link) {
            $xorgData = _parseXorgFd(file => $link);
            $logger->debug_result(
                 action => 'reading Xorg log file',
                 data   => $xorgData
            );
        } else {
            $logger->debug_result(
                 action => 'reading Xorg log file',
                 status => "non-readable link $link"
            );
        }
    } else {
        $logger->debug_result(
             action => 'reading Xorg log file',
             status => 'unable to get Xorg PID'
        );
    }

    return unless @nvidiasmiData || $xorgData || $ddcprobeData;
    # TODO: other cards than NVIDIA will be ignored, when cards from multiple vendors are present in the system
    if (@nvidiasmiData) {
	for my $i (0 .. $#nvidiasmiData) {
            my $video = {
                MEMORY        => $nvidiasmiData[$i]->{memory},
                NAME          => $nvidiasmiData[$i]->{name},
                PCISLOT       => $nvidiasmiData[$i]->{pcislot},
                SERIAL        => $nvidiasmiData[$i]->{serial},
                BIOSVERSION   => $nvidiasmiData[$i]->{bios},
                DRIVERVERSION => $nvidiasmiData[$i]->{driver},
            };
            $inventory->addEntry(
                section => 'VIDEOS',
                entry   => $video
            );
	    }
    }
    # TODO: rewrite should be considered: in systems with multiple cards, only one is detected (and may have wrong infos from another card! [both in _parseXorgFd itself and mixing $xorgData/$ddcprobeData] )
    else { 
	    my $video = {
	        CHIPSET       => $xorgData->{product}    || $ddcprobeData->{product},
	        MEMORY        => $xorgData->{memory}     || $ddcprobeData->{memory},
	        NAME          => $xorgData->{name}       || $ddcprobeData->{oem},
	        RESOLUTION    => $xorgData->{resolution} || $ddcprobeData->{dtiming},
	        PCISLOT       => $xorgData->{pcislot},
	        PCIID         => $xorgData->{pciid},
	    };
	
	    if ($video->{MEMORY} && $video->{MEMORY} =~ s/kb$//i) {
	        $video->{MEMORY} = int($video->{MEMORY} / 1024);
	    }
	    if ($video->{RESOLUTION}) {
	        $video->{RESOLUTION} =~ s/@.*//;
	    }
	
	    $inventory->addEntry(
	        section => 'VIDEOS',
	        entry   => $video
	    );
    }


}

sub _getNvidiaSmiData {
    my $handle = getFileHandle(@_);
    return unless $handle;

    my @data;
    while (my $line = <$handle>) {
        my $data_entry;
        my @lineValues = split ", ", $line;
        $data_entry->{name} = $lineValues[0];
        $data_entry->{serial} = $lineValues[1];
        $data_entry->{memory} = $lineValues[2];
        $data_entry->{pcislot} = $lineValues[3];
        $data_entry->{bios} = $lineValues[4];
        $data_entry->{driver} = $lineValues[5];
        push @data, $data_entry;
    }
    close $handle;

    return @data;
}

sub _getDdcprobeData {
    my $handle = getFileHandle(@_);
    return unless $handle;

    my $data;
    while (my $line = <$handle>) {
        $line =~ s/[[:cntrl:]]//g;
        $line =~ s/[^[:ascii:]]//g;
        $data->{$1} = $2 if $line =~ /^(\S+):\s+(.*)/;
    }
    close $handle;

    return $data;
}

sub _parseXorgFd {
    my $handle = getFileHandle(@_);
    return unless $handle;

    my $data;
    while (my $line = <$handle>) {
        if ($line =~ /Modeline\s"(\S+?)"/) {
            $data->{resolution} = $1 if !$data->{resolution};
        } elsif ($line =~ /Integrated Graphics Chipset:\s+(.*)/) {
            # Intel
            $data->{name} = $1;
        } elsif ($line =~ /Virtual screen size determined to be (\d+)\s*x\s*(\d+)/) {
            # Nvidia
            $data->{resolution} = "$1x$2";
        } elsif ($line =~ /NVIDIA GPU\s*(.*?)\s*at/) {
            $data->{name} = $1;
        } elsif ($line =~ /VESA VBE OEM:\s*(.*)/) {
            $data->{name} = $1;
        } elsif ($line =~ /VESA VBE OEM Product:\s*(.*)/) {
            $data->{product} = $1;
        } elsif ($line =~ /VESA VBE Total Mem: (\d+)\s*(\w+)/i) {
            $data->{memory} = $1 . $2;
        } elsif ($line =~ /RADEON\(0\): Chipset: "(.*?)"/i) {
            # ATI /Radeon
            $data->{name} = $1;
        } elsif ($line =~ /Virtual size is (\S+)/i) {
            # VESA / XFree86
            $data->{resolution} = $1;
        } elsif ($line =~ /
            PCI: \* \( (?:\d+:)? (\d+) : (\d+) : (\d+) \) \s
            (\w{4}:\w{4}:\w{4}:\w{4})?
        /x) {
            $data->{pcislot} = sprintf("%02d:%02d.%d", $1, $2, $3);
            $data->{pciid}   = $4 if $4;
        } elsif ($line =~ /NOUVEAU\(0\): Chipset: "(.*)"/) {
            # Nouveau
            $data->{product} = $1;
        }
    }
    close $handle;

    return $data;
}

1;
