package FusionInventory::Agent::XML::Query;

use strict;
use warnings;

use Data::Dumper;

sub new {
    my (undef, $params) = @_;

    my $self = {};

    $self->{config} = $params->{config};
    $self->{accountinfo} = $params->{accountinfo};
    $self->{logger} = $params->{logger};
    $self->{target} = $params->{target};
    $self->{storage} = $params->{storage};

    my $rpc = $self->{rpc};
    my $target = $self->{target};
    my $logger = $self->{logger};

    $self->{h} = {};
    $self->{h}{QUERY} = ['UNSET!'];
    $self->{h}{DEVICEID} = [$target->{deviceid}];

    if ($target->{currentDeviceid} && ($target->{deviceid} ne $target->{currentDeviceid})) {
      $self->{h}{OLD_DEVICEID} = [$target->{currentDeviceid}];
    }
  
    $logger->fault("No DEVICEID") unless ($target->{deviceid});

    bless $self;
}


1;
