package FusionInventory::LoggerBackend::File;

use strict;
use warnings;

use English qw(-no_match_vars);

sub new {
    my ($class, $params) = @_;

    my $self = {
        logfile         => $params->{config}->{'logfile'},
        logfile_maxsize => $params->{config}->{'logfile-maxsize'}
    };

    bless $self, $class;

    return $self;
}

sub logFileIsFull {
    my ($self) = @_;

    my @stat = stat($self->{logfile});
    return unless @stat;

    my $size = $stat[7];
    if ($size>$self->{logfile_maxsize}*1024*1024) {
        return 1;
    }

    return;
}

sub addMsg {
    my ($self, $args) = @_;

    my $level = $args->{level};
    my $message = $args->{message};

    return if $message =~ /^$/;

    if ($self->{config}{'logfile-maxsize'} && $self->logFileIsFull()) {
        unlink $self->{logfile} or warn "Can't ".
        "unlink ".$self->{logfile}." $!\n";
    }

    my $handle;
    if (open $handle, '>>', $self->{config}->{logfile}) {
        print {$handle}
            "[". localtime() ."]" .
            "[$level]" .
            " $message\n";
        close $handle;
    } else {
        warn "Can't open $self->{config}->{logfile}: $ERRNO";
    }

}

1;
__END__

=head1 NAME

FusionInventory::LoggerBackend::File - A file backend for the logger

=head1 DESCRIPTION

This is a file-based backend for the logger. It supports automatic filesize
limitation.

=head1 METHODS

=head2 new($params)

The constructor. The following parameters are allowed, as keys of the $params
hashref:

=over

=item I<config>

the agent configuration object

=back

=head2 addMsg($params)

Add a log message, with a specific level. The following arguments are allowed:

=over

=item I<level>

Can be one of:

=over

=item debug

=item info

=item error

=item fault

=back

=item I<message>

=back
