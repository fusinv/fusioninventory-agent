package FusionInventory::Agent::Task::WakeOnLan;

use strict;
use warnings;
use base 'FusionInventory::Agent::Task';

use constant ETH_P_ALL => 0x0003;
use constant PF_PACKET => 17;
use constant SOCK_PACKET => 10;

use Carp;
use English qw(-no_match_vars);
use Socket;

use FusionInventory::Agent::AccountInfo;
use FusionInventory::Agent::Config;
use FusionInventory::Agent::Job::Logger;
use FusionInventory::Agent::Network;
use FusionInventory::Agent::Storage;
use FusionInventory::Agent::Regexp;
use FusionInventory::Logger;

sub main {
    my ($self) = @_;

    if ($self->{target}->{type} ne 'server') {
        $self->{logger}->debug("No server. Exiting...");
        return;
    }

    my $options = $self->{prologresp}->getOptionsInfoByName('WAKEONLAN');
    if (!$options) {
        $self->{logger}->debug(
            "No wake on lan requested in the prolog, exiting"
        );
        return;
    }

    $self->{macaddress} = $options->{MAC};
    $self->{ip}         = $options->{IP};

    $self->{network} = FusionInventory::Agent::Network->new({
        logger => $self->{logger},
        config => $self->{config},
        target => $self->{target},
    });

    $self->StartMachine();
}


sub StartMachine {
    my ($self, $params) = @_;

    my $macaddress = $self->{macaddress};
    my $ip         = $self->{ip};
    my $logger     = $self->{logger};

    return unless defined $macaddress;

    if ($macaddress !~ /^$mac_address_pattern$/) {
        croak "Invalid MacAddress $macaddress . Exiting...";
    }
    $macaddress =~ s/://g;

    ###  for LINUX ONLY ###
    if ( eval { socket(SOCKET, PF_PACKET, SOCK_PACKET, 0); }) {

        setsockopt(SOCKET, SOL_SOCKET, SO_BROADCAST, 1)
            or warn "Can't do setsockopt: $ERRNO\n";

        open my $handle, '-|', '/sbin/ifconfig -a'
            or croak "Can't run /sbin/ifconfig: $ERRNO";
        while (my $line = <$handle>) {
            next unless $line =~ /(\S+) \s+ Link \s \S+ \s+ HWaddr \s (\S+)/x;
            my $netName = $1;
            my $netMac = $2;
            $logger->debug(
                "Send magic packet to $macaddress directly on card driver"
            );
            $netMac =~ s/://g;

            my $magic_packet =
                (pack('H12', $macaddress)) .
                (pack('H12', $netMac)) .
                (pack('H4', "0842"));
            $magic_packet .= chr(0xFF) x 6 . (pack('H12', $macaddress) x 16);
            my $destination = pack("Sa14", 0, $netName);
            send(SOCKET, $magic_packet, 0, $destination)
                or warn "Couldn't send packet: $ERRNO";
        }
        close $handle;
        # TODO : For FreeBSD, send to /dev/bpf ....
    } else { # degraded wol by UDP
        if ( eval { socket(SOCKET, PF_INET, SOCK_DGRAM, getprotobyname('udp')) }) {
            my $magic_packet = 
                chr(0xFF) x 6 .
                (pack('H12', $macaddress) x 16);
            my $sinbroadcast = sockaddr_in("9", inet_aton("255.255.255.255"));
            $logger->debug(
                "Send magic packet to $macaddress in UDP mode (degraded wol)"
            );
            send(SOCKET, $magic_packet, 0, $sinbroadcast);
        } else {
            $logger->debug("Impossible to send magic packet...");
        }
    }

    # For Windows, I don't know, just test
    # See http://msdn.microsoft.com/en-us/library/ms740548(VS.85).aspx
}

1;
