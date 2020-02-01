package Splice::Parameters;

use strict;
use warnings;

our $instance = undef;

sub getInstance         # singleton method
{
    $instance = _new Splice::Parameters() if ! defined $instance;
    $instance;
}

sub _new
{
    my $package  = shift;
    bless( {}, $package );
}

sub setData
{
    my $self   = shift;
    my %arg    = @_;

    # set up the data. use defaults if necessary

    $self->{aliasFile}          = $arg{aliasFile}          || undef;
    $self->{printTitles}        = $arg{printTitles}        || 0;
    $self->{generateSideLabels} = $arg{generateSideLabels} || 0;
    $self->{type}               = $arg{type}               || "cd";
    $self->{wrapWidth}          = $arg{wrapWidth}          || 99999;
    $self->{numberEachSong}     = $arg{numberEachSong}     || 0;
    $self->{cdDateLabels}       = $arg{cdDateLabels}       || 0;
    $self->{fillerTitle}        = $arg{fillerTitle}        || 0;
    $self->{useTimes}           = $arg{useTimes}           || 0;
    $self->{slim}               = $arg{slim}               || 0;
    $self->{itunesPlaylist}     = $arg{itunesPlaylist}     || undef;
    $self->{numberEachSong}     = $arg{numberEachSong}     || 0;
}

sub setTimes            { $_[0]->{useTimes} = $_[1];      }
sub isDigital           { $_[0]->{type} =~ /^(dat|cd)$/i; }
sub isCD                { $_[0]->{type} =~ /^cd$/i; 	  }
sub getAliasFile        { $_[0]->{aliasFile}; 			}
sub isSideLabels        { $_[0]->{generateSideLabels}; 	}
sub isNumberSongs       { $_[0]->{numberEachSong}; 		}
sub isCDDateLabels      { $_[0]->{cdDateLabels}; 		}
sub getType             { $_[0]->{type}; 				}
sub getWrapWidth        { $_[0]->{wrapWidth}; 			}
sub isFillerTitle       { $_[0]->{fillerTitle};         }
sub isUseTimes          { $_[0]->{useTimes};            }
sub isPrintTitles       { $_[0]->{printTitles};         }
sub isSlim              { $_[0]->{slim};            	}
sub getItunesPlaylist	{ $_[0]->{itunesPlaylist};      }

1;

__END__

=head1 AUTHOR INFORMATION

Copyright 2000-, Steven Scholnick <scholnicks@gmail.com>

splice is published under MIT.  See license.txt for details
