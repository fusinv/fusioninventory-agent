package FusionInventory::Agent::Task::Deploy::ActionProcessor::Action::Move;

use strict;
use warnings;

$File::Copy::Recursive::CPRFComp = 1;
use File::Copy::Recursive qw(dirmove);


sub do {
    my ($params) = @_;

    my $log = [];
    my $status;
    $status = rmove($params->{from}, $params->{to});
    if (!$status) {
        $log = [ "Failed to move file: `".$_[0]->[0]."' to '".$_[0]->[1], $! ];
    }
    return {
    status => $status,
    log => $log,
    };
}

1;
