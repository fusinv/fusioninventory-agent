package FusionInventory::Agent::XML::Query::Prolog;

use strict;
use warnings;
use base 'FusionInventory::Agent::XML::Query';

use XML::TreePP;
use Digest::MD5 qw(md5_base64);

#use FusionInventory::Agent::XML::Query::Prolog;

sub new {
    my ($class, $params) = @_;

    my $self = $class->SUPER::new($params);

    $self->{h}->{QUERY} = ['PROLOG'];
    $self->{h}->{TOKEN} = [$params->{token}];

    return $self;
}

sub dump {
    my $self = shift;
    print Dumper($self->{h});
}

sub getContent {
    my ($self, $args) = @_;

    $self->{accountinfo}->setAccountInfo($self);

    my $tpp = XML::TreePP->new();
    my $content= $tpp->write( { REQUEST => $self->{h} } );

    return $content;
}

1;
