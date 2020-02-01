package Splice::LabelFactory;

use strict;
use warnings;

use Splice::CDLabel;
use Splice::TapeLabel;

use overload
    q{""} => \&toString;

sub new {
    my $package = shift;
    my $self    = {};

	$self->{type} = shift || 'cd';		# cd is the default type

    bless( $self, $package );
}

sub createEmptyLabel {
	my $self = shift;

	my $label = undef;

	if ($self->{type} eq 'cd') {
		$label = new Splice::CDLabel();
	}
	else {
		$label = new Splice::TapeLabel();
	}

	$label;
}

sub createLabel {
	my $self      = shift;
	my $textRef   = shift;
	my $filler    = shift;

	my $label = undef;

	if ($self->{type} eq 'cd') {
#    	print scalar(@$textRef) . " data lines read in\n";

		$label = new Splice::CDLabel($textRef,$filler);
	}
	else {
		$label = new Splice::TapeLabel($textRef,$filler);
	}

	$label;
}

sub getType		{ $_[0]->{type}; 			}
sub setType		{ $_[0]->{type} = $_[1]; 	}

sub toString {
	my $self = shift;
	"LabelFactory : Creating $self->{type} labels";
}

1;

__END__

=head1 AUTHOR INFORMATION

Copyright 2000-, Steven Scholnick <scholnicks@gmail.com>

splice is published under MIT.  See license.txt for details
