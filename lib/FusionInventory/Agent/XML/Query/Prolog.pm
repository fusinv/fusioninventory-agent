package FusionInventory::Agent::XML::Query::Prolog;

use strict;
use warnings;

use XML::TreePP;
use Digest::MD5 qw(md5_base64);
use FusionInventory::Agent::XML::Query;

our @ISA = ('FusionInventory::Agent::XML::Query');
#use FusionInventory::Agent::XML::Query::Prolog;

sub new {
  my ($class, $params) = @_;

  my $self = $class->SUPER::new($params);
  bless ($self, $class);

  my $logger = $self->{logger};
  my $target = $self->{target};
  my $rpc = $params->{rpc};


  $self->{h}{QUERY} = ['PROLOG'];

  # $rpc can be undef if thread not enabled in Perl
  if ($rpc) {
    $self->{h}{TOKEN} = [$rpc->getToken()];
  }

  return $self;
}

sub dump {
  my $self = shift;
  eval "use Data::Dumper;";
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
