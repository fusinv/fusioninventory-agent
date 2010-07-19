package FusionInventory::Agent::Storage;
        
use strict;
use warnings;

use threads;
use threads::shared;

use Carp;
use English qw(-no_match_vars);
use File::Glob ':glob';
use Storable;

my $lock :shared;

=over 4

=item new({ config => $config, target => $target })

Create the object

=cut
sub new {
    my ($class, $params) = @_;

    my $self = {
        config => $params->{config},
        target => $params->{target}
    };

    bless $self, $class;
}

sub getFileName {
    my ($self, $params ) = @_;

    my $module = $params->{module};


    my $callerModule;
    my $i = 0;
    while ($callerModule = caller($i++)) {
        last if $callerModule ne 'FusionInventory::Agent::Storage';
    }

    my $fileName = $module || $callerModule;
    $fileName =~ s/::/-/g; # Drop the ::
    # They are forbiden on Windows in file path


    return $fileName;
}

# Internal function, no POD doc
sub getFilePath {
    my ($self, $params ) = @_;

    my $target = $self->{target};
    my $config = $self->{config};

    my $idx = $params->{idx};
    my $module = $params->{module};

    my $fileName = $self->getFileName({
        module => $module
    });


    my $dirName = $self->getFileDir();

    my $extension = '';
    if ($idx) {
        if ($idx !~ /^\d+$/) {
            print "[fault] idx must be an integer!\n";
            die;
        } 
        $extension = '.'.$idx;
    }


    return $dirName."/".$fileName.$extension.".dump";

}


sub getFileDir {
    my ($self, $params ) = @_;

    my $target = $self->{target};
    my $config = $self->{config};

    my $module = $params->{module};
    my $idx = $params->{idx};

    my $dirName;
    if ($target) {
        $dirName = $target->{'vardir'};
    } elsif ($config) {
        $dirName = $config->{'basevardir'};
    } else {
        die;
    }

    if (!$dirName) {
        die "Can't get the basevardir\n";
    }

    return $dirName;
}

=item save({ data => $date, idx => $ref })

Save the reference.
$idx is an integer. You can use if if you want to save more than one file for the
module. This number will be add at the of the file

=cut
sub save {
    my ($self, $params) = @_;

    my $data = $params->{data};
    my $idx = $params->{idx};

    lock($lock);

    my $filePath = $self->_getFilePath({ idx => $idx });
#    print "[storage]save data in:". $filePath."\n";

    my $oldMask;

    if ($OSNAME ne 'MSWin32') {
        $oldMask = umask();
        umask(oct(77));
    }
    # TODO: restrict access to temp file under windows

    store ($data, $filePath) or warn;
    
    if ($OSNAME ne 'MSWin32') {
        umask $oldMask;
    }

}

=item restore({ module => $module, idx => $idx})

Returns a reference to the stored data. If $idx is defined, it will open this
substorage.

=cut
sub restore {
    my ($self, $params ) = @_;

    my $module = $params->{module};
    my $idx = $params->{idx};

    my $filePath = $self->_getFilePath({
        module => $module,
        idx => $idx
    });
    #print "[storage]restore data from: $filePath\n";

    if (-f $filePath) {
        return retrieve($filePath);
    }

    return {};
}

=item remove({ module => $module, idx => $idx })

Returns the files stored on the filesystem for the module $module or for the caller module.
If $idx is defined, only the submodule $idx will be removed.

=cut
sub remove {
    my ($self, $params) = @_;

    my $idx = $params->{idx};
    
    my $filePath = $self->_getFilePath({ idx => $idx });
    #print "[storage] delete $filePath\n";

    if (!unlink($filePath)) {
        #print "[storage] failed to delete $filePath\n";
    }
}

=item removeAll({ module => $module, idx => $idx })

Deletes the files stored on the filesystem for the module $module or for the caller module.

=cut
sub removeAll {
    my ($self, $params) = @_;
    
    my $idx = $params->{idx};

    my $filePath = $self->_getFilePath({ idx => $idx });
    #print "[storage] delete $filePath\n";

    if (!unlink($filePath)) {
        #print "[storage] failed to delete $filePath\n";
    }
}

=item removeSubDumps({ module => $module })

Deletes the sub files stored on the filesystem for the module $module or for the caller module.

=cut
sub removeSubDumps {
    my ($self, $params) = @_;
   
    my $module = $params->{module};

    my $fileDir = $self->_getFileDir();
    my $fileName = $self->_getFileName({ module => $module });

    foreach my $file (bsd_glob("$fileDir/$fileName.*.dump")) {
        unlink($file) or warn "[error] Can't unlink $file\n";
    }
}

sub _getFilePath {
    my ($self, $params) = @_;

    my $target = $self->{target};
    my $config = $self->{config};

    my $idx = $params->{idx};
    if ($idx && $idx !~ /^\d+$/) {
        croak "[fault] idx must be an integer!\n";
    } 
    my $module = $params->{module};

    my $path = 
        $self->_getFileDir() . 
        '/' . 
        $self->_getFileName({ module => $module }) .
        ($idx ? ".$idx" : "" ) .
        '.dump';

    return $path;
}

sub _getFileName {
    my ($self, $params) = @_;

    my $name;

    if ($params->{module}) {
        $name = $params->{module};
    } else {
        my $module;
        my $i = 0;
        while ($module = caller($i++)) {
            last if $module ne 'FusionInventory::Agent::Storage';
        }
        $name = $module;
    }

    # Drop colons, they are forbiden in Windows file path
    $name =~ s/::/-/g;

    return $name;
}

sub _getFileDir {
    my ($self, $params) = @_;

    my $dir = 
        $self->{target} ? $self->{target}->{vardir}     : 
        $self->{config} ? $self->{config}->{basevardir} : 
                          undef;

    return $dir;
}

1;
__END__

=head1 NAME

FusionInventory::Agent::Storage - the light data storage API. Data will be
stored in a subdirectory in the 'vardir' directory. This subdirectory depends
on the caller module name.

=head1 SYNOPSIS

  my $storage = FusionInventory::Agent::Storage->new({
      target => {
          vardir => $ARGV[0],
      }
  });
  my $data = $storage->restore({
          module => "FusionInventory::Agent"
      });

  $data->{foo} = 'bar';

  $storage->save({ data => $data });

=head1 DESCRIPTION

This module is a wrapper for restore and save.
it called $inventory in general.
