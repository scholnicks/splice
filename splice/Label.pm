package Splice::Label;

use strict;
use warnings;

use Carp;

use Splice::SongFactory;
use Splice::Parameters;
use Splice::Utilities;

use overload
    q{""} => \&toString;

sub new {
    my $package  = shift;
    my $dataRef  = shift;

    my $self = {};
    $self->{filler} = shift || 0;

    bless $self, $package;

    $self->parseData( $dataRef ) if $dataRef;

    return $self;
}

sub loadArtistVenueData {
    my $self        = shift;
    my $line        = shift;
    my @topInfo     = split(/\W+-\W+/,$line,3);

    $self->{artist} = trim($topInfo[0]);
    $self->{venue}  = trim($topInfo[1]);
    $self->{date}   = trim($topInfo[2]) if (scalar(@topInfo) > 2);

    $self->{artist} =~ s!\W+-(\W+)?$!!;	# clean up artist
}

sub loadNumberOfLabels  { # gets the number of labels from the input data
    my $self = shift;
    my $line = shift;

    $line =~ /^([1-9]+)\s+(\w+)$/i;

    $self->{numberOfLabels} = $1;

    if ($2 =~ /mix/)
    {
    	Splice::Parameters::getInstance()->setTimes(1);
    }

    # default to one for bad data
    $self->{numberOfLabels} = 1 if ($line !~ /^([1-9]+).*/);
}

sub loadRecordAtInfo {
    my $self    = shift;
    my $dataRef = shift;
    my $i       = 2;

    my $tagLine = "Recorded at ";

    while ($dataRef->[$i] && $dataRef->[$i] !~ /^_\w*/ && $i < scalar(@{$dataRef}))
    {
        chomp $dataRef->[$i];
        next if $dataRef->[$i] =~ /^$/;

        $self->{topFlap} .= "($tagLine$dataRef->[$i])\n";

        $tagLine = "";  # tag line only for first line

        $i++;
    }

    $i;
}

# parses the incoming data
sub parseData {
    my $self    = shift;
    my $dataRef = shift;

    dieMessage("No data\n") if ! defined $dataRef;

    $self->{artist}         = "";
    $self->{venue}          = "";
    $self->{date}           = "";
    $self->{numberOfLabels} = 0;
    $self->{topFlap}        = "";
    $self->{setList}        = ();
    $self->{addInfo1}       = ();
    $self->{addInfo2}       = ();
    $self->{currentTape}    = 1;
    $self->{preFiller}      = 0;
    $self->{oneColumn}      = 0;
    $self->{combined}       = 0;
    $self->loadArtistVenueData( $dataRef->[0] );
    $self->loadNumberOfLabels(  $dataRef->[1] );

    my $i = $self->loadRecordAtInfo( $dataRef );

    my $text = "";

    $i++;
    while ($i < scalar(@$dataRef) && $dataRef->[$i] !~ /^_\w*/)
    {
        $text .= $dataRef->[$i++];
        $text .= ' ';
    }

  	dieMessage("Missing _ from input file") if (! $text);

    $i++;
    $self->loadAddInfo($dataRef,$i);

    $self->loadSongs( $text );

}

sub asInputData {
	my $self = shift;

	my $isMix = Splice::Parameters::getInstance()->isUseTimes();

	my $s = $self->{artist} . " - " . $self->{venue};
	$s .= " - " . $self->{date} if $self->{date};
	$s .= "\n";
	$s .= $self->{numberOfLabels} . " label\n";
	$s .= "_";
	$s .= "\n";

    foreach my $song (@{$self->{setList}})
    {
    	next if ! $song;

    	$s .= '{' if ($song->isItalics());
    	$s .= $song->getText();
    	$s .= '}' if ($song->isItalics());

    	if ($isMix)
    	{
    		$s .= "/";
    		$s .= $song->getTimeLength();
    	}

        $s .= $song->isEndOfSide() ? "|" : "/";
        $s .= "\n";
    }

    $s .= "\n";

	$s;
}

sub loadAddInfo {
    my $self    = shift;
    my $dataRef = shift;
    my $i       = shift;

    my $nLines  = scalar(@$dataRef);

    return if $i == $nLines;

    while ($i < $nLines && $dataRef->[$i] !~ /^_\W*/)
    {
        chomp $dataRef->[$i];
        push( @{$self->{addInfo1}}, $dataRef->[$i++] );
    }

    $i++;
    while ($i < $nLines && $dataRef->[$i] !~ /^_\W*/)
    {
        chomp $dataRef->[$i];
        push( @{$self->{addInfo2}}, $dataRef->[$i++] );
    }

}

sub loadSongs {
    my $self = shift;
    local $_ = shift;

    s/\n/\//g   if ! /\//;

    s/\n/ /g;
    s/\013/ /g;

    # make the if tests shorter, save the property in an auto variable
    my $useTimes = Splice::Parameters::getInstance()->isUseTimes();

    # now get each track
    my @allSongs = split(m#(-?>|[|/}])#,$_);

    # because of the paren in the split's pattern
    # the allSongs array will have the delimiters as well
    # so we skip loopIncrement at a time

    my $loopIncrement = $useTimes ? 4 : 2;

    my $factory = Splice::SongFactory::getInstance();

    for (my $i = 0; $i < scalar(@allSongs); $i += $loopIncrement)
    {
        my $song = $factory->createSong($allSongs[$i],$allSongs[$i+1]);

        # clean the times also
        $song->setTimeLength( $factory->clean($allSongs[$i+2]) ) if $useTimes;

        $self->addSong( $song );
    }
}

sub addSong {
	my $self = shift;
	my $song = shift;

	push( @{$self->{setList}}, $song );
}

# takes another label and combines its songs with the currrent setlist
# the other's setlist is appended onto the current setlist
sub combine {
    my $self  = shift;
    my $other = shift;

    # remove the last song if it is empty. this guards against an empty |
    # at the end of the setlist
    pop(@{$self->{setList}}) if ($self->{setList}->[-1]->isEmpty());

    # find the side break song, if any exists

    my $foundSideBreak = 0;
    foreach my $song (@{$self->{setList}}) {
        if ($song->isEndOfSide())
        {
            $foundSideBreak = 1;
            last;
        }
    }

    if (! $foundSideBreak) {
        # make the (possible new) last song the side break
        $self->{setList}->[-1]->setEndOfSide(1);
    }

    $self->{date} = $other->getVenue();

    # tell the other to add its filler title before adding the setlist
    $other->addFillerTitle($foundSideBreak);

    # append the setlist
    push(@{$self->{setList}}, @{$other->getSetList()});

    # append the recorded at information
    $self->appendToRecordAtInfo( $other->getTopFlap() );

    $self->{combined}++;
}

sub isPrintTitles {
	my $self = shift;
	return Splice::Parameters::getInstance()->isPrintTitles() ;
}

sub appendToRecordAtInfo {
    my $self = shift;
    my $text = shift || "";

    $self->{topFlap} .= $text;
}

# adds a filler title to the "incoming" filler setlist
sub addFillerTitle {
    my $self           = shift;
    my $foundSideBreak = shift;

    return if( ! Splice::Parameters::getInstance()->isFillerTitle() );

    if ($foundSideBreak) {  # a sidebreak exists, so add the info with the blank borders
        $self->unshiftSongWithEmptyBorder($self->getVenue());
    }
    else  {                 # no sidebreak, add the info with a blank after it
        unshift( @{$self->{setList}},
                    Splice::SongFactory::getInstance()->createItalicsSong($self->getVenue()),
                    Splice::SongFactory::getInstance()->createEmptySong()
               );
    }
}

# prepends the incoming songs to the front of the setlist
sub addSongs {
    my $self  = shift;
    my @array = @_;

    # first pre-pend a title for this label
    if (Splice::Parameters::getInstance()->isFillerTitle())
    {
        $self->unshiftSongWithEmptyBorder("$self->{artist} - $self->{venue}");
    }

    # prepend the setlist with the added songs

    unshift(@{$self->{setList}},@array);
}

# adds a song (in italics), surrounded by empty songs, to the front of the setlist array
sub unshiftSongWithEmptyBorder {
    my $self = shift;
    my $text = shift;

    unshift( @{$self->{setList}},
            Splice::SongFactory::getInstance()->createEmptySong(),
            Splice::SongFactory::getInstance()->createItalicsSong($text),
            Splice::SongFactory::getInstance()->createEmptySong()
   );
}

# returns all the songs after the last sidebreak
# the songs are removed from the current setlist
# if no sidebreak is found, an empty array is returned
sub getSongsAfterSideBreak {
    my $self           = shift;
    my $foundSideBreak = 0;

    # find the LAST sidebreak

    for (my $songIndex = scalar(@{$self->{setList}})-1; $songIndex >= 0; $songIndex--) {
        if ($self->{setList}->[$songIndex]->isEndOfSide()) {
            $foundSideBreak = $songIndex;
            last;
        }
    }

    my @songsAfter = ();

    # grab all the songs after the side break
    # and turn off the side break flag
    if ($foundSideBreak != 0) {
        @songsAfter = splice(@{$self->{setList}},$foundSideBreak+1);
        $self->{setList}->[$foundSideBreak]->setEndOfSide(0);
    }

    @songsAfter;
}

#  returns the label in string format
sub toString {
    my $self    = shift;
    my $s       = "";

    $self->checkForEmptyTitle();

    if ($self->isPrintOneColumn()) {
        $self->removeAllSideBreaks();
        $self->createSideBreakAtEnd();
    }
    else {
        $self->checkForSideBreak();
    }

    $self->prepareSetList();

    $self->{currentTape} = 1;

    $s .= "\none-column\n/one-column true def\n\n" if( $self->isPrintOneColumn() );

    $s .= $self->getRecordedAtLines();
    $s .= $self->getArtistLine() . "[";
    $s .= $self->getSideLabel( 1 );

    my $sc = 0;
    my $i  = 1;
    my $numberSongs = Splice::Parameters::getInstance()->isNumberSongs();

    foreach my $song (@{$self->{setList}}) {
    	next if ! $song;

    	if ($numberSongs && ! $song->isEmpty() && ! $song->isItalics()) {
    		$song->setNumber($i++);
    	}

        $s .= "$song";

        if ($song->isEndOfSide()) {
           $sc++;

           if (($sc % 2) == 0) {
               $self->{currentTape}++;
               $s .= "]\n";                                 # close the current tape
               $s .= $self->getAlbumSpecification();        # open up for the next tape
               $s .= $self->getArtistLine() . "[";
           }
           else {
               $s .= "]\n[";                                # close the current side
               $s .= $self->getSideLabel($sc+1);            # and open up the new side
           }
        }
    }

    $s .= "]\n";
    $s .= $self->getAddInfos();
    $s .= $self->getAlbumSpecification();

    $s .= "/one-column exch def\n\n" if( $self->isPrintOneColumn() );

    $s;
}

sub prepareSetList {}

sub checkForEmptyTitle {
	# empty by default
}

#  returns the side label
sub getSideLabel {
    my $self      = shift;
    my $sideCount = shift;

    if ($self->{numberOfLabels} == 1 || ! Splice::Parameters::getInstance()->isSideLabels())
    {
        return "";
    }

    my $type   = Splice::Parameters::getInstance()->getType();
    my $number = ($sideCount %2)     ? "1"    : "2";
    my $label  = ($type =~ m/^cd$/i) ? "Disc" : "Side";

    "[($label $number) () /I]\n()\n";
}

# checks for at least one side break, if one does not exist
# it is created
sub checkForSideBreak {
    my $self = shift;

    return if( ! $self->allowedToCreateSideBreak() );

    my $numberOfSideBreaksFound = 0;

    foreach my $track ( @{$self->{setList}} ) {
        $numberOfSideBreaksFound++ if( $track->isEndOfSide() );
    }

    my $sideBreaksMissing = $self->getNumberOfSideBreaksNeeded() - $numberOfSideBreaksFound;

    # is the number of side breaks is the number that is needed?
    # if so just return

    return if( $sideBreaksMissing == 0 );

    if( $self->getNumberOfLabels() == 1 ) { # treat single labels special
        # there could be more than needed, so just start over
        # this can be done for single label, because there will be
        # exactly one side break needed
        # SS 12-22-02

        $self->removeAllSideBreaks();

        my $spot = int( scalar(@{$self->{setList}}) / 2 ); # just the 1/2 point
        $self->{setList}->[$spot]->setEndOfSide(1);
    }
    else {
        if ($sideBreaksMissing == 1) {         # they missed the last one
            $self->createSideBreakAtEnd();
        }
        else {                                  # they missed multiple breaks
            $self->handleMultipleMissingSideBreaks();
        }
    }
}

sub getFirstSideBreakIndex {
    my $self = shift;

    for( my $i=0; $i <= scalar(@{$self->{setList}}); $i++ ) {
    	return $i if( $self->{setList}->[$i]->isEndOfSide() );
    }

    return scalar(@{$self->{setList}})-1;
}

sub handleMultipleMissingSideBreaks {
    my $self = shift;

    # lets just start over
    $self->removeAllSideBreaks();

    my $needed      = $self->getNumberOfSideBreaksNeeded();
    my $setListSize = scalar(@{$self->{setList}});
    my $period      = int( $setListSize / $needed );

    my $sideBreaksMade = 0;

    # create the needed side breaks at regular intervals in the setlist

    for(my $spot = $period; $spot < $setListSize; $spot += $period) {
        $self->{setList}->[$spot]->setEndOfSide(1);
        $sideBreaksMade++;
    }

    # check to see if we need to make an end one
    $self->createSideBreakAtEnd() if( $sideBreaksMade < $needed );
}

# creates a single side break as the last song
sub createSideBreakAtEnd {
    my $self   = shift;

    return if( ! $self->allowedToCreateSideBreak() );

    # create the final song as a side break
    $self->{setList}->[-1]->setEndOfSide(1);

    # create an empty song for after the side break
    push( @{$self->{setList}}, Splice::SongFactory::getInstance()->createEmptySong() );
}

# returns if we need to create a side break
sub allowedToCreateSideBreak {
    my $self = shift;

    return 0 if not defined $self->{setList};
    return 0 if $self->{filler};
    return 0 if $self->{preFiller};

    return 1;
}

sub getAlbumSpecification {
    my $self = shift;

    return ""            if $self->{preFiller};
    return "two-bands\n" if $self->{filler};

    (! $self->{date} ) ? "double-album\n\n" : "two-albums\n\n";
}

sub getAddInfos {
    my $self = shift;

    return "" if( ! ( $self->{addInfo1} || ! $self->{addInfo2} ) );

    my $s = "\n\n";

    if ( $self->{addInfo1} ) {
    	$s .= "/additional-info-1 [";
		foreach my $line ( @{$self->{addInfo1}} ) {
			$s .= "($line) ";
		}
        $s .= "] def\n\n";
    }

    if( $self->{addInfo2} ) {
    	$s .= "/additional-info-2 [";
		foreach my $line ( @{$self->{addInfo2}} ) {
			$s .= "($line) ";
		}
        $s .= "] def\n\n";
    }

    $s;
}

sub getArtistLine {
    my $self = shift;
    my $s = "($self->{artist})   ($self->{venue}";

    $s .= " $self->{currentTape}/$self->{numberOfLabels}" if $self->{numberOfLabels} > 1;
    $s .= ") ()\n";

    if( $self->{date} ) {
       $s .= "                    ($self->{date}) ()\n";
    }

    $s;
}

sub getRecordedAtLines {
    my $self = shift;

    return "" if $self->{filler};

	my $topFlap = $self->getTopFlap();

	$topFlap = '' if( ! $topFlap );

    "/signature [\n$topFlap] def\n\n";
}

sub removeAllSideBreaks {
    my $self = shift;
    foreach my $song ( @{$self->{setList}} ) {
        $song->setEndOfSide(0);
    }
}

sub getAddInfo1   { $_[0]->{addInfo1};            }
sub getAddInfo2   { $_[0]->{addInfo2};            }

sub getArtist    { $_[0]->{artist};             }
sub setArtist    { $_[0]->{artist} = $_[1];     }

sub getVenue     { $_[0]->{venue};              }
sub setVenue     { $_[0]->{venue} = $_[1];      }

sub getDate      { $_[0]->{date};               }
sub setDate      { $_[0]->{date};               }

sub getSetList   { $_[0]->{setList};            }
sub setSetList   { $_[0]->{setList} = $_[1];    }

sub isPreFiller  { $_[0]->{preFiller};          }
sub setPreFiller { $_[0]->{preFiller} = $_[1];  }

sub isFiller     { $_[0]->{filler};             }
sub setFiller    { $_[0]->{filler} = $_[1];     }

sub getTopFlap   { $_[0]->{topFlap};            }
sub setTopFlap   { $_[0]->{topFlap} = $_[1];    }

sub isOneColumn  { $_[0]->{oneColumn};          }
sub setOneColumn { $_[0]->{oneColumn} = $_[1];  }

sub getNumberOfLabels { $_[0]->{numberOfLabels};                }
sub setNumberOfLabels { $_[0]->{numberOfLabels} = $_[1];        }

sub isPrintOneColumn {
    my $self = shift;

    return( $self->isOneColumn() &&
            ! ( $self->isPreFiller() || $self->isFiller() || $self->{combined} )
    );
}

sub getNumberOfSideBreaksNeeded
{
    my $self = shift;

    my $numberofLabels = $self->getNumberOfLabels();

    return( (2 * $numberofLabels) - 1);
}

1;

__END__

=head1 AUTHOR INFORMATION

Copyright 2000-, Steven Scholnick <scholnicks@gmail.com>

splice is published under MIT.  See license.txt for details

