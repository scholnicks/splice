package Splice::Song;

use strict;
use warnings;
use Splice::Parameters;
use Splice::Utilities;

use overload
    q{""} => \&toString,
    cmp   => \&compareAsString;

sub new {
    my $package = shift;

    bless {
    	text     => shift || "",
    	italics  => shift || 0,
    	len      => shift || "",
    	endSide  => 0,
    	medley   => 0,
    	number   => ""
    }, $package;
}

sub compareAsString {
    my ($self,$other) = @_;
    $self->{text} cmp $other;
}

sub wrapSong {
    my $self = shift;
    my $ret  = "(";
    my $text = $self->{text};   # easy on the typing

    $ret  .= "$self->{number}. " if $self->{number};
    $text  = "$text->"          if $self->{medley};
    $ret  .= "$text)";

    if ($self->{italics}) {
       return "[$ret () /I]\n";
    }

    if ($self->{len}) {
        return "[$ret ($self->{len})]\n";
    }

	my $wrapWidth = Splice::Parameters::getInstance()->getWrapWidth();

    if (length($text) <= $wrapWidth || $text =~ /\(/) {
       return "$ret\n";
    }

    # walk backwards from the wrapwidth looking for a space

    my $spot = $wrapWidth;
    my $c    = substr($text,$spot,1);

    while ($c ne ' ' && $spot > 0) {
        $spot--;
        $c = substr($text,$spot,1);
    }

    my $first  = trim( substr($text, 0, $spot)    );
    my $second = trim( substr($text,$spot+1,9999) );

    $first  = "$self->{number} $first" if $self->{number};
    return "($first)\n(    $second)\n";
}

sub toString {
   my $self  = shift;
   return $self->wrapSong();
}

sub isEmpty {
   $_[0]->{text} eq "";
}

sub setText      { $_[0]->{text} = $_[1];       }
sub getText      { $_[0]->{text};               }

sub isEndOfSide  { $_[0]->{endSide};           }
sub setEndOfSide { $_[0]->{endSide} = $_[1];   }

sub isMedley     { $_[0]->{medley};            }
sub setMedley    { $_[0]->{medley} = $_[1];    }

sub isItalics    { $_[0]->{italics};           }
sub setItalics   { $_[0]->{italics} = $_[1];   }

sub setNumber    { $_[0]->{number} = $_[1];    }
sub getNumber    { $_[0]->{number};            }

sub setTimeLength { $_[0]->{len} = trim($_[1]); }
sub getTimeLength { $_[0]->{len};               }

1;
