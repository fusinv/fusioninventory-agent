package FusionInventory::Agent::Task::Inventory::Win32::Firewall;

use strict;
use warnings;

use FusionInventory::Agent::Tools;
use FusionInventory::Agent::Tools::Win32;
use FusionInventory::Agent::Task::Inventory::Generic::Firewall;

sub isEnabled {
    my (%params) = @_;
    return 0 if $params{no_category}->{firewall};
    return 1;
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger = $params{logger};

    my $profilesStatus = _getFirewallProfilesStatus(
        logger => $logger
    );
    $inventory->addEntry(
        section => 'FIREWALL',
        entry   => {
            STANDARD_STATUS => $profilesStatus->{standard} || '',
            PUBLIC_STATUS => $profilesStatus->{public} || '',
            DOMAIN_STATUS => $profilesStatus->{domain} || ''
        }
    );

}

sub _getFirewallProfilesStatus {
    my (%params) = @_;

    my $key = getRegistryKey(
        path => "HKEY_LOCAL_MACHINE/SYSTEM/CurrentControlSet/services/SharedAccess/Parameters/FirewallPolicy"
    );
    return unless $key;
    my $subKeys = {
        domain => 'DomainProfile',
        public => 'PublicProfile',
        standard => 'StandardProfile'
    };
    my $statuses = {};
    $params{logger}->debug2(join(' - ', keys %$key));
    for my $profile (keys %$subKeys) {
        next unless $key->{$subKeys->{$profile} . '/'};
        $params{logger}->debug2(join(' - ', keys %{$key->{$subKeys->{$profile}}}));
        next unless defined $key->{$subKeys->{$profile} . '/'}->{'/EnableFirewall'};
        $params{logger}->debug2($key->{$subKeys->{$profile} . '/'}->{'/EnableFirewall'});
        my $enabled = hex2dec($key->{$subKeys->{$profile} . '/'}->{'/EnableFirewall'});
        $params{logger}->debug2($enabled);
        $statuses->{$profile} = $enabled ?
            FusionInventory::Agent::Task::Inventory::Generic::Firewall::STATUS_ON :
            FusionInventory::Agent::Task::Inventory::Generic::Firewall::STATUS_OFF;
    }

    return $statuses;
}

sub _getFirewallProfiles {
    
}

sub _getCurrentConnectionsProfile {
    my (%params) = @_;

    $DB::single = 1;
    my $networkListKey = getRegistryKey(
	logger => $params{logger},
	path => 'HKEY_LOCAL_MACHINE/SOFTWARE/Microsoft/Windows NT/CurrentVersion/NetworkList'
    );
    my $profilesKey = $networkListKey->{'Profiles'};
    my $signaturesKey = $networkListKey->{'Signatures'};
    
    foreach my $interface (getInterfaces()) {
	if ($interface->{STATUS} eq 'Up') {
	    my $dnsDomain = $interface
	}
    }
}

1;
