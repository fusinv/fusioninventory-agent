package FusionInventory::Agent::Task::Inventory::Virtualization::VirtualBox;

# This module detects only all VMs create by the user who launch this module (root VMs).

use strict;
use warnings;

use XML::TreePP;
use File::Glob ':glob';

use FusionInventory::Agent::Tools;

sub isInventoryEnabled {
    return
        can_run('VBoxManage');
}

sub doInventory {
    my $params = shift;
    my $inventory = $params->{inventory};
    my $scanhomedirs = $params->{config}{'scan-homedirs'};

    my ($version) = (`VBoxManage --version` =~ m/^(\d\.\d).*$/);
    my $cmd_list_vms = $version > 2.1 ?
        "VBoxManage -nologo list --long vms" : "VBoxManage -nologo list vms";

    my $in = 0;
    my $uuid;
    my $mem;
    my $status;
    my $name;

    foreach my $line (`$cmd_list_vms`) {
        chomp $line;
        # read only the information on the first paragraph of each vm
        if ($in == 0 and $line =~ m/^Name:\s+(.*)$/) {      # begin
            $name = $1;
            $in = 1; 
        } elsif ($in == 1 ) {
            if ($line =~ m/^\s*$/) {                        # finish
                $in = 0 ;

                $inventory->addVirtualMachine ({
                        NAME      => $name,
                        VCPU      => 1,
                        UUID      => $uuid,
                        MEMORY    => $mem,
                        STATUS    => $status,
                        SUBSYSTEM => "Sun xVM VirtualBox",
                        VMTYPE    => "VirtualBox",
                    });
                # useless but need it for security (new version, ...)
                $name = $status = $mem = $uuid = 'N\A';

            } elsif ($line =~ m/^UUID:\s+(.*)/) {
                $uuid = $1;
            } elsif ($line =~ m/^Memory size:\s+(.*)/ ) {
                $mem = $1;
            } elsif ($line =~ m/^State:\s+(.*)\(.*/) {
                $status = ( $1 =~ m/off/ ? "off" : $1 );
            }
        }
    }

    if ($in == 1) {
        # Anormal situation ! save the current vm information ...
        $inventory->addVirtualMachine ({
            NAME      => $name,
            VCPU      => 1,
            UUID      => $uuid,
            MEMORY    => $mem,
            STATUS    => $status,
            SUBSYSTEM => "Sun xVM VirtualBox",
            VMTYPE    => "VirtualBox",
        });
    }

    # try to found another VMs, not exectute by root
    my @vmRunnings = ();
    my $index = 0 ;
    foreach my $line ( `ps -efax` ) {
        chomp $line;
        next if $line =~ m/^root/;
        if ($line =~ m/^.*VirtualBox (.*)$/) {
            my @process = split (/\s*\-\-/, $1);     #separate options

            my ($name, $uuid);
            foreach my $option ( @process ) {
                print $option."\n";
                if ($option =~ m/^comment (.*)/) {
                    $name = $1;
                } elsif ($option =~ m/^startvm (\S+)/) {
                    $uuid = $1;
                }
            }

            if ($scanhomedirs == 1) {
                # If I will scan Home directories,
                $vmRunnings [$index] = $uuid;
                # save the no-root running machine
                $index += 1;
            } else {
                $inventory->addVirtualMachine ({  # add in inventory
                    NAME      => $name,
                    VCPU      => 1,
                    UUID      => $uuid,
                    STATUS    => "running",
                    SUBSYSTEM => "Sun xVM VirtualBox",
                    VMTYPE    => "VirtualBox",
                });
            }
        }
    }

    return unless $scanhomedirs == 1;

    # Read every Machines Xml File of every user
    foreach my $file (bsd_glob("/home/*/.VirtualBox/Machines/*/*.xml")) {
        # Open config file ...
        my $tpp = XML::TreePP->new();
        my $data = $tpp->parse($file);
          
        # ... and read it
        if ($data->{Machine}->{uuid}) {
            my $uuid = $data->{Machine}->{uuid};
            $uuid =~ s/^{?(.{36})}?$/$1/;
            my $status = "off";
            foreach my $vmRun (@vmRunnings) {
                if ($uuid eq $vmRun) {
                    $status = "running";
                }
            }

            $inventory->addVirtualMachine ({
                NAME      => $data->{Machine}->{name},
                VCPU      => $data->{Machine}->{Hardware}->{CPU}->{count},
                UUID      => $uuid,
                MEMORY    => $data->{Machine}->{Hardware}->{Memory}->{RAMSize},
                STATUS    => $status,
                SUBSYSTEM => "Sun xVM VirtualBox",
                VMTYPE    => "VirtualBox",
            });
        }
    }

    foreach my $file (bsd_glob("/home/*/.VirtualBox/VirtualBox.xml")) {
        # Open config file ...
        my $tpp = XML::TreePP->new();
        my $data = $tpp->parse($file);
        
        # ... and read it
        my $defaultMachineFolder =
            $data->{Global}->{SystemProperties}->{defaultMachineFolder};
        if (
            $defaultMachineFolder != 0 and
            $defaultMachineFolder != "Machines" and
            $defaultMachineFolder =~ /^\/home\/S+\/.VirtualBox\/Machines$/
        ) {
          
            foreach my $file (bsd_glob($defaultMachineFolder."/*/*.xml")) {
                my $tpp = XML::TreePP->new();
                my $data = $tpp->parse($file);
            
                if ($data->{Machine} != 0 and $data->{Machine}->{uuid} != 0 ) {
                    my $uuid = $data->{Machine}->{uuid};
                    $uuid =~ s/^{?(.{36})}?$/$1/;
                    my $status = "off";
                    foreach my $vmRun (@vmRunnings) {
                        if ($uuid eq $vmRun) {
                            $status = "running";
                        }
                    }

                    $inventory->addVirtualMachine ({
                        NAME      => $data->{Machine}->{name},
                        VCPU      => $data->{Machine}->{Hardware}->{CPU}->{count},
                        UUID      => $uuid,
                        MEMORY    => $data->{Machine}->{Hardware}->{Memory}->{RAMSize},
                        STATUS    => $status,
                        SUBSYSTEM => "Sun xVM VirtualBox",
                        VMTYPE    => "VirtualBox",
                    });
                }
            }
        }
    }
}

1;
