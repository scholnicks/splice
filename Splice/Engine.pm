package Splice::Engine;

use Cwd;

use Splice::Label;
use Splice::LabelFactory;
use Splice::Parameters;
use Splice::Utilities;

sub new {
    my $package = shift;
    my %prefs   = @_;
    
    my $obj = bless( {}, $package );
    
    $obj->initialize(%prefs);
    
    $obj;
}

sub initialize {
	my $self = shift;
    my %prefs   = @_;

    # set up the data. use defaults if necessary
    
    $self->{dolby}     = $prefs{dolby}     || "";
    $self->{oneColumn} = $prefs{oneColumn} || 0;
    $self->{rotate}    = $prefs{rotate}    || 0;
    
    $self->{labels}                = ();
    $self->{fillerExists}          = 0;
    $self->{stringRepresentation}  = '';
    $self->{flipSpine}             = defined($prefs{flipSpine}) ? $prefs{flipSpine} : 1;

    $self->{flipSpine} = 0 if Splice::Parameters::getInstance()->isCD(); 
}

sub readFile {       # reads in the songs files
    my $self  = shift; 
    my $fname = shift;
    my @text  = ();                 # holds the lines for 1 label

    open(my $IN,'<',$fname) or dieMessage("Cannot open input file : $fname\n");
    
    my $filler = 0;
    
    my $factory = new Splice::LabelFactory( Splice::Parameters::getInstance()->getType() );
    
    while (<$IN>) {
    	s/^\s+//;		# trim any whitespace
    	s/\s+$//;
    	
    	next if /^$/;
        next if /^(\n|\013)$/;
   	
        s/\|\|/\|/g;     # transform || to |
    
        if (m/^([#+])\W*$/) {   # a label separator
            push(@{$self->{labels}}, $factory->createLabel(\@text, $filler));
            splice @text;
            $filler = ($1 eq '+');
            
            $self->{fillerExists} = 1 if $filler;
            next;
        }
        
        push(@text,$_);
    }
    
    # any more text, create a label from it
    
    if (scalar(@text) > 0) {
        push(@{$self->{labels}}, $factory->createLabel(\@text,$filler));
    }
    
    close $IN;
}

sub getAllLabels {
    my $self = shift;
    
    if (! $self->{stringRepresentation}) {
		if ($self->{fillerExists}) {
			# labelIndex is used because in the _handleFiller method, we will need
			# both the current label and the previous one.  the easiest way to do this
			# was to use the label's index
		
			my $labelIndex = 0;
			foreach my $label (@{$self->{labels}}) {
				$self->_handleFiller($labelIndex) if ($label->isFiller());
				$labelIndex++;
			}
		}
		
		$self->{stringRepresentation} = $self->_getOpeningStatements();
		
		foreach my $label ( @{$self->{labels}} ) {
			$self->{stringRepresentation} .= $label->toString();
		}
		
		$self->{stringRepresentation} .= $self->_getClosingStatements();
	}
	
	return $self->{stringRepresentation};
}

sub asInputData {
	my $self = shift;
	
	my $s = "";
	
	foreach my $label ( @{$self->{labels}} ) {
		$s .= $label->asInputData();
	}
	
	return $s;
}


sub isPrintTitles {
	my $self = shift;
	foreach my $label ( @{$self->{labels}} ) {
		return 1 if $label->isPrintTitles();
	}
	
	return 0;
}

sub _handleFiller {      # moves the setlists around for filler (see bottom comments)
    my $self           = shift;
    my $labelIndex     = shift;
    my $label          = $self->{labels}->[$labelIndex];
    my $prevLabel      = $self->{labels}->[$labelIndex-1];
    
    # see end of this file for the filler algorithm
    if ($prevLabel->getArtist() eq $label->getArtist()) {
        $label->removeAllSideBreaks();              # remove sidebreaks from filler
        $prevLabel->combine( $label );              # combine the two labels
        splice(@{$self->{labels}}, $labelIndex, 1); # remove the 2nd one
    }
    else {
        $prevLabel->setPreFiller(1);
        $label->addSongs( $prevLabel->getSongsAfterSideBreak() );   
    }
}

sub _getOpeningStatements {       # returns the opening PS statements
    my $self = shift;
    
    my $printTitles = $self->isPrintTitles();
    
    my $s = Splice::Parameters::getInstance()->getType() . "-sizes\n";
    
    $s .= "Dolby$self->{dolby}\n" if $self->{dolby};
    
    $s .= "album-font band-font\nsong-font signature-font\n";
    
    $s .= "one-column\n/one-column true def\n" if $self->{oneColumn};
    
    $s .= "/song-font /Helvetica-Bold def\n";
    $s .= "/band-font /Helvetica-Bold def\n";
    $s .= "/signature-font /Helvetica-Bold def\n";
    $s .= "/album-font /Helvetica-Bold def\n\n";

    $s .= "flip-spine\n/flip-spine true def\n\n" if $self->{flipSpine};
        
    $s .= "columns-horizontally\n/columns-horizontally true def\n" if $self->{rotate};
    
    $s .= "print-inner-album-titles-p\n";
    if ($printTitles) {
        $s .= "/print-inner-album-titles-p true def\n";
    }
    else {
        $s .= "/print-inner-album-titles-p false def\n";
    }
    
    $s;
}

sub _getClosingStatements {   # returns the closing PS statements
    my $self = shift;
    my $s    = "";
    
    $s .= "\n/print-inner-album-titles-p exch def\n" if ! $self->{printTitles};
    $s .= "\n/signature-font exch def\n";
    $s .= "/song-font exch def\n";
    $s .= "/band-font exch def\n";
    $s .= "/album-font exch def\n\n";
    $s .= "/one-column exch def\n" if $self->{oneColumn};
    $s .= "/columns-horizontally exch def\n" if $self->{rotate};
    $s .= "/flip-spine exch def\n" if $self->{flipSpine};
 
    $s;  
}

1;

__END__

Filler is a very tricky subject.  It is the ability to combine more than one label 
into "one" label.  Further complication the issue is the fact that how the labels
are combined is based on whether or not the labels are for the same artist.  Here
are the algorithms for both scenarios.

First Label  = target
Second Label = filler
 
Same Artist
-----------
Set the target's date as filler's venue information.

Add onto the target's setlist the venue information of the filler label as
an italics song surrounded by empty songs.

Take all of the setlist of the second label (the filler label) and move them
to the end of the first label.

Delete the filler label from the array of labels.

Different Artist
----------------
Add onto the filler's setlist the artist/venue information of the filler label as
an italics song surrounded by empty songs.

Get all of the songs, after the last side break, from the target and prepend them
to the filler's setlist.

Remove the prepended songs from the target setlist.  Remove the endOfSide designation
from the last side break song.
