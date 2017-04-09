#!/usr/bin/perl
#
# (c) Steven Scholnick <steve@scholnick.net>
#
# splice is published under MIT.  See http://www.scholnick.net/license.txt for details
#
# splice Home Page : http://www.scholnick.net/splice

use strict;
use warnings;

use lib '.';

use Cwd;
use Getopt::Long;
use Pod::Usage;

use Splice::Engine;
use Splice::PTapes;
use Splice::ResourceFile;
use Splice::CheckLabelFile;
use Splice::Parameters;
use Splice::Utilities;
use Splice::ITunesEngine;

our $VERSION = '2.6.1';

# start of main...
{
	my %prefs;
	my $rcFilePath = getResourceFilePath(".splicerc", "splice.rc");

	if ($rcFilePath) {
		%prefs = new Splice::ResourceFile( $rcFilePath )->getAllValues();
	}
	else {
		warnMessage( "No resource file found\n" );
	}

	GetOptions(
		'1column!'			=> \$prefs{oneColumn},
		'8mm'				=> sub { $prefs{type} = "8mm" },
		'addinfo=s'			=> \$prefs{add_info},
		'cassette'			=> sub { $prefs{type} = "cassette" },
		'dat'				=> sub { $prefs{type} = "DAT" },
  		'filler!' 			=> \$prefs{fillerTitle},
  		'flap=s'			=> \$prefs{flap},
  		'font=s'			=> \$prefs{font},
  		'itunes=s' 			=> \$prefs{itunesPlaylist},
 		'jewelcase'			=> sub { $prefs{type} = "cd" },
 		'help'      		=> \&help,
 		'number!'           => \$prefs{numberEachSong},
  		'mix!'				=> \$prefs{useTimes},
 		'postscript!'		=> \$prefs{postscript},
 		'slim!'				=> \$prefs{slim},
 		'size=s'			=> \$prefs{fontSize},
		'stdout!'           => \$prefs{stdout},
    	'times!' 			=> \$prefs{useTimes},
    	'title!'			=> \$prefs{printTitles},
		'version'   		=> \&version,
		'width=s'			=> \$prefs{wrapWidth},
	) or help();

	$prefs{wrapWidth} = 9999 if $prefs{oneColumn};

	$prefs{inFile} = scalar(@ARGV) == 0 ? $prefs{inFile} : $ARGV[0];

	dieMessage("Input file $prefs{inFile} not found\n") if (! -e $prefs{inFile} && ! $prefs{itunesPlaylist});

	Splice::Parameters::getInstance()->setData(%prefs);

	my $engine = undef;

	if ($prefs{itunesPlaylist}) {
		$prefs{inFile} = getItunesOutputPath(\%prefs);

		$engine = new Splice::ITunesEngine(%prefs);
	}
	else {
		$engine = new Splice::Engine(%prefs);
	}

	$engine->readFile( $prefs{inFile} );

	if ($prefs{stdout}) {
		print $engine->asInputData();
		exit 0;
	}

	runPtapes($engine->getAllLabels(),\%prefs);

	exit 0;
}

sub getItunesOutputPath {
	my $prefs = shift;

	my $directory = expandPath($prefs->{'itunes.output.directory'});
	$directory = $ENV{HOME} if ! $directory;

	my $inputFile = $prefs->{itunesPlaylist};
	$inputFile =~ s/ /_/g;
	$inputFile = normalizeText($inputFile,0);

	return "$directory/$inputFile";
}

sub runPtapes {			# runs ptapes to create the PS and (if required) the PDF files
	my $labels = shift;
	my $prefs  = shift;

	my $ptapes =  new Splice::PTapes(
		data        => $labels,
	    filePath    => $prefs->{inFile},
		ps2pdfPath  => $prefs->{ps2pdfPath},
		pdfViewPath => $prefs->{pdfViewPath},
		psViewPath  => $prefs->{psViewPath}
	);

	$ptapes->setAdditionalInfoFontSize( $prefs->{add_info} ) if (defined $prefs->{add_info}   );
	$ptapes->setSongFontSize( $prefs->{fontSize} ) 			 if (defined $prefs->{fontSize}   );
	$ptapes->setFlapFontSize( $prefs->{flap} ) 				 if (defined $prefs->{flap}       );
	$ptapes->setFont( $prefs->{font} ) 						 if (defined $prefs->{font}       );
	$ptapes->setPostscript( $prefs->{postscript} )			 if (defined $prefs->{postscript} );

  	$ptapes->generateLabel();
}

sub version {
	print "splice : Version $VERSION\n";
	pod2usage(-verbose=>99,-exitvalue=>1,-sections=>[ qw(COPYRIGHT)] );
}

sub help {
	pod2usage(-verbose=>99,-exitvalue=>1,-sections=>[ qw(OPTIONS)] );
}

__END__

=head1 NAME

splice - label maker

=head1 SYNOPSIS

splice [Options] [Input Song File]

=head1 DESCRIPTION

Splice is a label maker for: CDs, DAT tapes, 8mm tapes, and analog cassette tapes. It is primarily
intended for live music, but it can be used for any label need. The setlists are stored in a simple textual fashion
(see below) consisting of a header, the songs, and an optional trailer. The setlist format is designed to both easy
to use (both by splice and the person creating the setlist) and easy to read.

=head1 OPTIONS

 --1column           : one column, (implies -w9999)
 --8mm               : 8mm cassette labels
 --addinfo <size>    : additional information font size
 --cassette          : cassette labels
 --dat               : dat labels
 --filler            : produce a title for the filler
 --flap <size>       : flap font size
 --font <font>       : change the default font
 --help              : this help screen
 --itunes <playlist> : Read the songs from the specified iTunes playlist
 --jewelcase         : jewel case labels (default)
 --mix               : Create a mix disc (synonym for --times)
 --number            : Number each song
 --postscript	     : generate a PS file only (do not generate a PDF file)
 --size <size>       : font size
 --slim              : Single CD labels for "slim" cases
 --stdout            : Print out the input data (really only useful with --itunes)
 --times             : every other song is a time field
 --title             : generate a title at the top of the setlist
 --version           : prints version
 --width <width>     : song wrap width

=head1 SEE ALSO

splice Online at L<http://www.scholnick.net/splice/>

=head1 AUTHOR

Steven Scholnick <scholnicks@gmail.com>

=head1 COPYRIGHT

(c) Steven Scholnick <steve\@scholnick.net> 2000 -

splice is published under MIT. See http://www.scholnick.net/license.txt

