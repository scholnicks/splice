package Splice::ResourceFile;

use strict;
use warnings;
use Splice::Utilities;

use overload
    q{""} => \&toString;

sub new {
    my $package = shift;

    my $obj = bless {
    	fileLocation => shift,
    	nodes        => {}
    }, $package;

    if (defined $obj->{fileLocation}) {
    	$obj->readFile( $obj->{fileLocation} );
    }

    $obj;
}

sub setFileLocation { $_[0]->{fileLocation} = $_[1]; }
sub getFileLocation { $_[0]->{fileLocation};         }

# returns all of the values
sub getAllValues { %{$_[0]->{nodes}}; }

sub getValue {			# returns a value for a key
	my $self  = shift;
	my $key   = shift;
	my $nodes = $self->{nodes};

	defined $nodes ? $nodes->{$key} : undef;
}

sub readFile
{
	my $self = shift;

	my $filePath = $self->{fileLocation};

    open(my $RC_FILE,'<',$filePath) or dieMessage("Cannot open $filePath\n");

    while (<$RC_FILE>) {
    	chomp;
    	s/#.*//;
    	s/^\s+//;
    	s/\s+$//;
    	next unless length;

    	my ($var,$value) = split(/\s*=\s*/,$_,2);
    	if ($value =~ /^(yes|on|true|1)$/i) {
    		$self->{nodes}->{$var} = 1;
    	}
    	elsif ($value =~ /^(no|off|false|0)$/i) {
    		$self->{nodes}->{$var} = 0;
    	}
    	else {
    		$self->{nodes}->{$var} = $value;
    	}

    }
	close $RC_FILE;
}

sub toString {
	$_[0]->getFileLocation();
}

1;

__END__

=head1 AUTHOR INFORMATION

Copyright 2000-, Steven Scholnick <scholnicks@gmail.com>

splice is published under MIT.  See license.html for details

