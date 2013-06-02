package Splice::CDLabel;

use strict;
use warnings;

use Carp;

use Splice::Label;
use Splice::SongFactory;
use Splice::Parameters;
use Splice::Utilities;

use base qw( Splice::Label );

sub new
{
    my $package = shift; 
    my $self    = {};
    
    my $dataRef         = shift;
    $self->{filler}     = shift || 0;
    $self->{singleDisc} = shift || 0;

    bless $self, $package;

    $self->parseData( $dataRef ) if $dataRef;
    
    return $self;
}

sub isPrintTitles
{
	my $self = shift;
	
	my $param = Splice::Parameters::getInstance();

	return 1 if ($param->isSlim() && $self->isSingleDisc());

	return $param->isPrintTitles() ;
}

sub checkForEmptyTitle 
{
	my $self = shift;
	
	my $param = Splice::Parameters::getInstance();
	
	if ($self->isSingleDisc())
	{
		if ($self->isPrintTitles())
		{
			# single titles down the center look better with a space
			# between the title and the first song
			unshift( @{$self->{setList}}, Splice::SongFactory::getInstance()->createEmptySong() ); 
		}
		
		# for slim jewel cases combine the artist name and the venue together
		# these will be printed in the title line at the top
		
		if ($param->isSlim())
		{
			if ($self->getVenue()) {
				$self->setVenue( $self->getArtist() . " - " . $self->getVenue() );
			}
			else {
				$self->setVenue( $self->getArtist() );
			}
		}
	}
}

sub loadArtistVenueData
{
    my $self = shift;
    my $line = shift;

    $self->SUPER::loadArtistVenueData( $line );
     
    # date fields do not look nice with CD labels
    # so just put the date back together with the venue
    
    # this is now (4/22/01) a user pref, if they want it they can have it
    
    if ( ! Splice::Parameters::getInstance()->isCDDateLabels() && $self->getDate() ) 
    {
        $self->setVenue( $self->getVenue() . " " . $self->getDate() );
        $self->setDate("");
    }
}

sub combine
{
    my $self  = shift;
    my $other = shift;

    $self->SUPER::combine( $other );
    
    $self->setSingleDisc( 0 );	# combining 2 set lists, turn off single disc
}

sub loadNumberOfLabels  # gets the number of labels from the input data
{
    my $self = shift;
    my $line = shift;

    $self->SUPER::loadNumberOfLabels( $line ) if $line;
    
    if( $self->getNumberOfLabels() == 1 )
    {
	    # if there is only one disc specified, enabled one column
    	$self->setOneColumn( 1 );

    	$self->setSingleDisc( 1 );
    }
    
    # CDs are always one label, you can have a slim, a double, a triple or even a quad.
    $self->setNumberOfLabels( 1 );
}

#  returns the side label
sub getSideLabel
{
    my $self      = shift;
    my $sideCount = shift;
    
    return "";
}

sub prepareSetList
{
    my $self = shift;

	my $info1 = $self->getAddInfo1();
	my $info2 = $self->getAddInfo2();

	return if( ! $info1 && ! $info2 );			# no additional info to process
	
	# with a single disc the setlist is printed down the center
	# just combine the information
	
	if( $self->isSingleDisc() && $info2 )
	{
		push( @{$info1}, @{$info2} );
		$info2 = undef;
	}

	my $factory = Splice::SongFactory::getInstance();
	
	if( ! $info2 )			# just one
	{
		# just one set so put it on the end of hte setlist
		$self->addAdditionalInformationToSetlist( $info1 );
	}
	else
	{
		# where does the 2nd side start?
		my $secondSideStart = $self->getFirstSideBreakIndex() + 1;

		my $size = scalar(@{$self->{setList}});
		
		# remove the end of side marker
		@{$self->{setList}}[$secondSideStart-1]->setEndOfSide(0);
		
		# remove the second side from the setlist and save it
		my @secondSide = @{$self->{setList}}[ $secondSideStart .. $size ];
		splice( @{$self->{setList}}, $secondSideStart );

		$self->matchSizes( \@secondSide );

		# add the first info to the end of the first side
		# which is now the end of the setlist
		$self->addAdditionalInformationToSetlist( $info1 );

		# set the last add info entry as the end of the side
		@{$self->{setList}}[-1]->setEndOfSide(1);

		# add the 2nd side back
		push( @{$self->{setList}}, @secondSide );

		# load info2 onto the end
		$self->addAdditionalInformationToSetlist( $info2 );
	}
}

sub matchSizes
{
	my $self          = shift;
	my $secondSideRef = shift;
	
	my $aSize = scalar(@{$self->{setList}});
	my $bSize = scalar(@{$secondSideRef});

	my $factory = Splice::SongFactory::getInstance();

	if( $aSize > $bSize )
	{
		for( my $i=0; $i < ($aSize-$bSize)+1; $i++ )
		{
			push( @{$secondSideRef}, $factory->createEmptySong() );
		}
	}
	elsif( $bSize > $aSize )
	{
		for( my $i=0; $i < ($bSize-$aSize)-1; $i++ )
		{
			push( @{$self->{setList}}, $factory->createEmptySong() );
		}
	}
}

sub addAdditionalInformationToSetlist
{
	my $self = shift;
	my $info = shift;

	my $factory = Splice::SongFactory::getInstance();

	push( @{$self->{setList}}, $factory->createEmptySong() );
	push( @{$self->{setList}}, $factory->createEmptySong() );

	foreach my $line ( @{$info} )
	{
		push( @{$self->{setList}}, $factory->createItalicsSong($line) );
	}
}


sub getAddInfos
{
	# for CD labels, the additional information is part of the setlist
	my $self = shift;
	return "";
}


sub isSingleDisc
{
	return $_[0]->{singleDisc};
}

sub setSingleDisc
{
	$_[0]->{singleDisc} = $_[1];
}

1;

