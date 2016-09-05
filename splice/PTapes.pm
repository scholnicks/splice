package Splice::PTapes;

use strict;
use warnings;

use Splice::Utilities;

# constants
#   use constant is not used here, because I want to be able
#   use these constants within double quoted strings

our $aif       = "additional-info-font-height";
our $fh        = "song-font-height";
our $sfh       = "song-font-height";
our $sigFH     = "signature-font-height";

sub new {
    my $package = shift;
    my $self    = {};
    my %arg     = @_;

    $self->{data}            = $arg{data}            || dieMessage "Data is required";
    $self->{filePath}        = $arg{filePath}        || "./songs.label";
    $self->{spliceObject}	 = $arg{spliceObject}	 || undef;
    $self->{addInfoFontSize} = $arg{addInfoFontSize} || 0;
    $self->{flapFontSize}    = $arg{flapFontSize}    || 0;
    $self->{font}            = $arg{font}            || "0";
    $self->{songFontSize}    = $arg{songFontSize}    || 0;
    $self->{ps2pdfPath}      = $arg{ps2pdfPath}      || "";
    $self->{pdfViewPath}     = $arg{pdfViewPath}     || "";
    $self->{psViewPath}      = $arg{psViewPath}      || "";

    $self->{postscript} = 0;

    $self->{ps2pdfPath} = "" if ( ! -e $self->{ps2pdfPath} );

    bless( $self, $package );
}

# generates the label
#	first in PS and then in PDF
sub generateLabel {
    my $self   = shift;
    my $psFile = "$self->{filePath}.ps";

    open(my $out,'>',$psFile) or dieMessage("Cannot open output file, $psFile\n");
    $self->generatePostscript($out);
    close $out;

	my $outFileName = $psFile;

	if ($self->isPostscript()) {
		system( $self->{psViewPath} . qq! "$outFileName"! ) if $self->{psViewPath};
	}
	else {
		$outFileName = $self->convertToPDF($psFile);
	}

    $outFileName;
}

# converts the PS file to PDF
#	ghostscript (gs) is used to do this conversion on all OSes
sub convertToPDF {
	my $self    = shift;
	my $psFile  = shift;

	if (! $self->{ps2pdfPath} || ! -e $self->{ps2pdfPath}) {
		my $app = $self->{ps2pdfPath} || "ps2pdf";
 		warnMessage("Unable to created PDF file. PS file $psFile exists. $app does not exist.");
		system( $self->{psViewPath} . qq! "$psFile"! ) if $self->{psViewPath};
		return;
	}

	my $pdfFile = $psFile;

	$pdfFile =~ s/ps$/pdf/;

    # use GhostScript's ps2pdf to convert the file from PS to PDF

	if (system($self->{ps2pdfPath} . qq! "$psFile" "$pdfFile"!) == 0) {
		unlink( $psFile );
		$self->openPDFFile($pdfFile);
	}
 	else {
 		warnMessage("Unable to created PDF file. PS file $psFile exists.");
		system( $self->{psViewPath} . qq! "$psFile"! ) if $self->{psViewPath};
 	}

	$pdfFile;
}

# opens the resulting PDF file
sub openPDFFile {
	my $self        = shift;
	my $pdfFilePath = shift;

	if ($^O =~/^Win/i) {
		system( qq!"$pdfFilePath"! );	# windows uses the extension to spawn the right app
	}
	else { # Unix (just call the viewer)
		system( $self->{pdfViewPath} . qq! "$pdfFilePath"! ) if $self->{pdfViewPath};
	}
}

# generates the postscript file
sub generatePostscript {
    my $self       = shift;
   	my $fileHandle = shift;

    print $fileHandle $self->transform( $self->getProlog() );
    print $fileHandle $self->{data};
    print $fileHandle $self->getTrailer();
}

sub transform {
	my $self = shift;
	local $_ = shift;

	s/$sfh/$self->{addInfoFontSize}/g  if ($self->{addInfoFontSize} && m/$aif/   );
	s/12/$self->{flapFontSize}/g       if ($self->{flapFontSize}    && m/$sigFH/ );
	s/Helvetica/$self->{font}/g        if ($self->{font}                         );
	s/14/$self->{songFontSize}/g       if ($self->{songFontSize}    && m/$sfh/   );

	return $_;
}

# the song font size
sub setSongFontSize { $_[0]->{songFontSize} = $_[1]; }
sub getSongFontSize { $_[0]->{songFontSize}          }

sub setAdditionalInfoFontSize { $_[0]->{addInfoFontSize} = $_[1]; 	}
sub getAdditionalInfoFontSize { $_[0]->{addInfoFontSize}; 			}

sub setFlapFontSize { $_[0]->{flapFontSize} = $_[1]; 	}
sub getFlapFontSize { $_[0]->{flapFontSize}; 			}

sub setFont 		{ $_[0]->{font} = $_[1]; 	}
sub getFont 		{ $_[0]->{font}; 			}

sub setPostscript 	{ $_[0]->{postscript} = $_[1]; 	}
sub isPostscript 	{ $_[0]->{postscript}; 			}


sub getTrailer
{
return <<'END_OF_TRAILER';
%%Trailer
%%  This form should always be here at the end, to make sure that the
%%  final page is dumped even if there are an odd number of labels
%%  being printed.
%%
tick 0 ne { showpage } if
end % pop the TapeDict
%%EOF
END_OF_TRAILER
}

sub getProlog
{
return <<'END_OF_PROLOG';
%!PS-Adobe-1
%%Creator: Jamie Zawinski <jwz@jwz.org>
%%Title: audio-tape.ps
%%Orientation: Landscape
%%CreationDate: 27-Sep-99
%%
%%  PostScript code to generate tape labels, version 1.29.
%%  For audio-cassette, DAT, CD, or 8mm video-cassette labels.
%%  Copyright (c) 1988-1999 Jamie Zawinski <jwz@jwz.org>.
%%
%%  Permission granted for non-commercial use and distribution so long as
%%  this notice of copyright and associated documentation remain intact.
%%
%%EndComments

%%BeginDocumentation
%%EndDocumentation

{ /TapeDict 500 dict def TapeDict begin } exec

% Some PostScript interpreters don't implement the `save' and `restore'
% operators.  If your PS interpreter is broken in this way, change the
% `false' on the following line to `true'.
/save-is-broken false def

/bdef { bind readonly def } bind readonly def

/box
{
  4 2 roll
  newpath moveto
    exch dup 0 rlineto
    exch 0 exch neg rlineto
    neg 0 rlineto
  closepath
} bdef

/rightshow
{
  dup stringwidth pop
  neg 0 rmoveto
  show
} bdef

/centershow
{
  dup stringwidth pop
  2 div neg 0 rmoveto
  show
} bdef

/max
{
  dup 3 -1 roll dup
  3 -1 roll gt
  { exch pop } { pop } ifelse
} bdef

/max-stringwidth
{
  stringwidth pop
  exch stringwidth pop
  max
} bdef


%% CMYK color model Color Defines
%%	-- John Werner <werner.wbst311@xerox.com>, 19-Oct-1993
%%
/cmyk_black {0.0 0.0 0.0 1.0} def	% black
/cmyk_pblck {1.0 1.0 1.0 0.0} def	% process black
/cmyk_cyan  {1.0 0.0 0.0 0.0} def	% cyan
/cmyk_mag   {0.0 1.0 0.0 0.0} def	% magenta
/cmyk_yel   {0.0 0.0 1.0 0.0} def	% yellow
/cmyk_red   {0.0 1.0 1.0 0.0} def	% red
/cmyk_green {1.0 0.0 1.0 0.0} def	% green
/cmyk_blue  {1.0 1.0 0.0 0.0} def	% blue
/cmyk_gray  {0.0 0.0 0.0 0.5} def	% gray
/cmyk_pgray {0.5 0.5 0.5 0.0} def	% process gray
/cmyk_white {0.0 0.0 0.0 0.0} def	% white

%% Some nice names.  These are currently set to use cmyk color model.
%%	-- John Werner <werner.wbst311@xerox.com>, 19-Oct-1993
%%
/black	    {{cmyk_black}}	def
/pblack	    {{cmyk_pblck}}	def
/cyan	    {{cmyk_cyan}}	def
/magenta    {{cmyk_mag}}	def
/yellow	    {{cmyk_yel}}	def
/red	    {{cmyk_red}}	def
/green	    {{cmyk_green}}	def
/blue	    {{cmyk_blue}}	def
/gray	    {{cmyk_gray}}	def
/pgray	    {{cmyk_pgray}}	def
/white	    {{cmyk_white}}	def
/light-gray {{0.0 0.0 0.0 0.2}} def
/orange	    {{0.0 0.5 1.0 0.0}} def
/brown	    {{0.0 0.5 1.0 0.5}} def
/dark-green {{1.0 0.5 1.0 0.5}} def
/aqua	    {{1.0 0.5 0.0 0.0}} def
/dark-aqua  {{1.0 0.5 0.0 0.5}} def
/dark-blue  {{1.0 1.0 0.0 0.7}} def
/deep-blue  {{1.0 1.0 0.5 0.0}} def
/midnight-blue	{{1.0 1.0 0.5 0.5}} def


%% Default font-names, sizes & colors.	The widths (and sometimes heights) are
%% stomped at runtime, but the names are the responsibility of the user.
%%
/outside-fill-color	white	def	% The color to fill the outside flap
/outside-box-color	black	def
/inside-fill-color	white	def	% The color to fill the inside flap
/inside-box-color	black	def
/big-box-fill-color	white	def	% The color to fill the big box
/big-box-box-color	black	def
/spine-fill-color	white	def	% The color to fill the big box
/spine-box-color	black	def
/back-spine-fill-color	white	def	% The color to fill the big box
/back-spine-box-color	black	def	% The color to fill the big box

/box-color	black	def	% The color for drawing the boxes in
/icon-color	black	def	% The color to print magic icons in.
					%  -- see also icon-fade-factor
/dolby-color	black	def	% The color to print the dobly symbols

/song-font /Helvetica def
/song-font-bold /Helvetica-Bold def
/song-font-italic /Helvetica-Oblique def
/song-font-bold-italic /Helvetica-BoldOblique def
/song-time-font song-font def
/song-font-height 14 def		%% SS changed 8 -> 14
/song-font-color black def

/signature-font /Helvetica def
/signature-font-height 8 def		%% SS changed 8 -> 12
/signature-font-color black def

/band-font /Helvetica def
/band-font-height 13 def
/band-font-color black def

/album-font /Helvetica def
/album-font-height 13 def
/album-font-color black def

/inner-album-font /Helvetica-Bold def
/inner-album-font-height 13 def
/inner-album-font-color black def

/date-font /Helvetica-Bold def
/date-font-height 8 def
/date-font-color black def

/tape-id-font /Helvetica def
/tape-id-font-height 14 def
/tape-id-font-color white def
/tape-id-background-color gray def

%%/additional-info-font song-font def

/additional-info-font inner-album-font def
/additional-info-font-bold song-font-bold def
/additional-info-font-italic song-font-italic def
/additional-info-font-bold-italic song-font-bold-italic def
/additional-info-font-height song-font-height def
/additional-info-font-color black def
/flip-additional-info false def

% if true, songs go inside the tape label, else outside.
/songs-go-inside false def

% if true, icons go inside the tape label, else outside.
/icons-go-inside false def

% If true, the spine will be printed with a nasty orientation.
/flip-spine false def

% If true, the song-listings will be printed other-side-up.
/flip-songs false def

% If true, the song-listings will be in one column instead of two.
/one-column false def

% If true, the song-listings will be horizontal instead of vertical.
/columns-horizontally false def

% if an icon and the song listings are being printed on the same flap, the
% icon will be faded by this amount (so that the songs will be readable).
%
% You may want to change this to a larger value is you are using color for
% the magic-icon.  0.20 is good for black icons.
%					-- John Werner
%
/icon-fade-factor 0.20 def
%% /icon-fade-factor 1.00 def	% uncomment me for color icons

% If true, the titles of the albums will be automatically printed above the
% song listings.  Otherwise, you must do it by hand with /Title in the song
% lists.
/print-inner-album-titles-p true def

% Whether inner album titles should be underlined.
/underline-titles-p true def

% If true, the signature strings will be centered on the back spine
% instead of left-justified.
/centered-signature false def

/cassette-sizes
{
  /margins 4 def
  /back-spine-height 40 def
  /spine-height 32 def
  /list-height 185 def
  /total-height margins back-spine-height add
		margins spine-height add add
		margins list-height add	 2 mul add
		margins add
		def
  /inner-width 280 def
  /total-width inner-width margins dup add add def
  % if there is anything else on the page already, force a page-break.
  DATp 8mmp or tape-side-p or tick 0 ne and { showpage /tick 0 def } if
  /DATp false def
  /8mmp false def
  /datap false def
  /slimp false def
  /cdp false def
  /tape-side-p false def
} bdef

/DAT-sizes
{
  % Length: 3 1/6 inches     - 228.95
  % Width: 2 7/8 in	     - 209.86
  % Folds:
  % 7/16 in from bottom	     - 31.63
  % 15/16 in from the bottom - 67.78
  /margins 3 def
  /back-spine-height 27 def
  /spine-height 33 def
  /list-height 156 2 sub def
  /total-height margins back-spine-height add
		margins spine-height add add
		margins list-height add	 2 mul add
		margins add
		def
  /inner-width 202 4 sub def
  /total-width inner-width margins dup add add def
  % if there is anything else on the page already, force a page-break.
  DATp not tape-side-p or tick 0 ne and { showpage /tick 0 def } if
  /DATp true def
  /8mmp false def
  /datap false def
  /slimp false def
  /cdp false def
  /tape-side-p false def
} bdef

/8mm-sizes   % by Allen Wade, 13 mar 91
{
  % Length: 3 5/8 inches     - 250
  % Width:  3 11/16 inches   - 279.86
  % Folds:
  % 1/2 in from bottom	     - 32.63
  % 1 1/8 in from the bottom - 77.78
  /margins 4 def
  /back-spine-height 34 def
  /spine-height 40 def
  /list-height 175 def
  /total-height margins back-spine-height add
		margins spine-height add add
		margins list-height add	 2 mul add
		margins add
		def
  /inner-width 260 def
  /total-width inner-width margins dup add add def
  % if there are normal cassette tapes on the page already, force a page-break.
  8mmp not tape-side-p or tick 0 ne and { showpage /tick 0 def } if
  /8mmp true def
  /DATp false def
  /datap false def
  /slimp false def
  /cdp false def
  /tape-side-p false def
} bdef

/data-sizes		% for data cartridges (DC300, DC600, DC6150, etc).
{			% by Howard Moftich <lsilwm!howardm@uunet.UU.NET>
  /margins 4 def
  /back-spine-height 81 def	% 28 Jul 92
  /spine-height 45 def
  /list-height 280 def
  /total-height margins back-spine-height add
		margins spine-height add add
		margins list-height add	 2 mul add
		margins add
		def
  /inner-width 420 def
  /total-width inner-width margins dup add add def
  datap not tape-side-p or tick 0 ne and { showpage /tick 0 def } if
  /datap true def
  /8mmp false def
  /DATp false def
  /slimp false def
  /cdp false def
} bdef

/slim-cassette-sizes	% by George Lindholm, 21 oct 92
{
  /margins 4 def
  /back-spine-height 40 def
  /spine-height 28.8 def
  /list-height 185 def
  /total-height margins back-spine-height add
		margins spine-height add add
		margins list-height add	 2 mul add
		margins add
		def
  /inner-width 280 def
  /total-width inner-width margins dup add add def
  % if there are DATs or 8mms on the page already, force a page-break.
  DATp 8mmp or tape-side-p or tick 0 ne and { showpage /tick 0 def } if
  /slimp true def
  /DATp false def
  /8mmp false def
  /datap false def
  /cdp false def
} bdef

/extraslim-cassette-sizes	% the Fuji kind?  By boche@vnet.ibm.com.
{
  slim-cassette-sizes
  /back-spine-height 38 def
  /spine-height 24.5 def
} bdef


/cd-sizes		% for standard CD jewel cases
{			% by jwz@jwz.org, 27-Sep-99
  /margins 4 def
  /back-spine-height 0 def
  /spine-height 15 def
  /list-height 387 def
  /total-height margins spine-height add dup add
		margins list-height add add
		margins add
		def
  /inner-width 326 def
  /cover-width 343 def
  /cover-height 342 def
  /total-width inner-width margins dup add add def
  cdp not tape-side-p or tick 0 ne and { showpage /tick 0 def } if
  /cdp true def
  /datap false def
  /8mmp false def
  /DATp false def
  /slimp false def
} bdef




/folder-label-setup
{
  % The "generic" folder label setup is really for the Avery white labels.

  % if there's anything other than these on the page, force a page-break.
  dup tape-side-label-type ne
  tape-side-p not
    or
    tick 0 ne
      and { showpage /tick 0 def } if
  /8mmp false def
  /DATp false def
  /tape-side-label-type exch def
  /labels-per-page 8 def
  /tape-side-p true def
  /margins 3 def
  /spine-height 40 def
  /label-height 40 def
  /inter-label-height 8 def
  /page-top-margin 32 def
  /label-span 48 def
  /left-margin 24 def
  /inner-width 216 def
} bdef

/avery-white-folder-label-sizes		% by Eric Benson, 9 Nov 1992
{
  % There isn't room for song listings on these labels, so we just print
  % band names and album titles using the same layout style used for
  % printing the spines of the case labels.
  %
  % These dimensions are for the labels without the color stripe on top.
  % 8 labels per page.
  % 32 points from the top of the page to the top of the first label.
  % Each label is 40 points high.
  % 8 points blank space above and below each label.
  % 4 points margin on the page on each side of the labels.
  % There are tick marks on each side of each label, centered vertically.
  % Each tick mark is 16 points long.
  % 216 points (3 inches), between the tick marks.
  /avery-white folder-label-setup
} bdef

/avery-color-stripe-folder-label-sizes		% by Eric Benson, 28 Nov 1992
{
  /avery-color folder-label-setup
  /spine-height 32 def
  /label-height 32 def
  /inter-label-height 16 def
  /page-top-margin 40 def
} bdef

/dennison-white-folder-label-sizes	% by Eric Benson, 28 Nov 1992
{
  /dennison-white folder-label-setup
  /page-top-margin 4 def
  /left-margin 14 def
  /inner-width 236 def
  /labels-per-page 9 def
} bdef

/avery-audio-tape-laser-label-sizes	% by Eric Benson, 22 Nov 1992
{
  % Avery Audio Tape Laser Labels #5198 are labels designed to stick
  % on cassette tapes.  They are 8 1/2 x 11 inch sheets with 12 labels
  % in two columns of six.  Each label has a "mail-slot" shape, designed
  % to fit around the hubs of a cassette.  This provides a drawing surface
  % above, below and on each side of the hubs.
  % The top and bottom margins on the page are each 37 points.
  % Each label is 120 points high, and there is no vertical space between them.
  % The left and right page margins and the center gutter are each
  % 1/2 inch, or 36 points.
  % Each label is 252 points wide.
  % The distance from the top of the label to the hub hole is 5/8 inch, or
  % 45 points.
  % The height of the hub hole is also 5/8 inch or 45 points.
  % The distance from the bottom of the hub hole to the bottom of the label
  % is 30 points.
  % The upper left and upper right corners of each label are clipped at
  % a 45 degree angle.  Each cut extends 1/8 inch, or 9 points, from the top
  % and from the side.
  % The hub hole is a rectangle with a semicircle at each end, like this:
  %   ____
  %  (____)
  %
  % The distance from the side to the outer edge of the hub hole is
  % 40 points on each side, and the hole is 172 points wide.  The radius of
  % the semicircles is 22.5 points, so the straight middle section of the
  % hub hole is 127 points.
  %
  %%%%%%% This isn't implemented yet, these measurements are just saved
  %%%%%%% here for future reference
} bdef


/tick 0 def		% How many tapes have been dumped on this page.
/DATp false def		% don't change this.
/8mmp false def		% don't change this.
/datap false def	% don't change this.
/slimp false def	% don't change this.
/tape-side-p false def	% don't change this.
/tape-side-label-type /avery-white def	% don't change this.
cassette-sizes


%% These are stubs to make up for some printers not handling color info
%%
%%    setcmykcolor & setrgbcolor
%%	    'setgray' to the average of the colors specified
%%
%%    currentcmykcolor & currentrgbcolor
%%	    push 0.0 on the stack for all but the last color component,
%%	    push 'currentgray' for the last color component.
%%
%%	-- John Werner <werner.wbst311@xerox.com>, 19-Oct-1993
%%
/min {dup 3 2 roll dup 4 1 roll lt {exch pop} {pop} ifelse} bdef

systemdict /setcmykcolor known not
{
  systemdict /setrgbcolor known not
  { %% We don't even know setrgbcolor
    /setcmykcolor
    { %% gray = 1.0 - min(1.0, 0.3*cyan + 0.59*magenta + 0.11*yellow + black)
       exch 0.11 mul add exch 0.59 mul add exch 0.3 mul add
      1.0 min 1.0 exch sub setgray
    } bdef
  }
  { %% we know setrgbcolor
    /setcmykcolor
    {
      %begin
	/__my_black exch def
	/__my_yel  exch def
	/__my_mag  exch def
	/__my_cyan exch def
	1.0 1.0 __my_cyan __my_black add min sub  % R = 1.0-min(1.0,cyan+black)
	1.0 1.0 __my_mag  __my_black add min sub  % G = 1.0-min(1.0,mag +black)
	1.0 1.0 __my_yel  __my_black add min sub  % B = 1.0-min(1.0,yel +black)
	setrgbcolor
      %end
    } bdef
  } ifelse
} if

%% end: Color Stubs


/extract-song-and-time-and-font-1
{
  dup type /stringtype eq
  { () /R }
  { dup length
    dup 0 eq
    { pop pop () () /R }
    { dup 1 eq
      { pop 0 get () /R }
      { 2 eq
	{ dup 0 get exch 1 get /R }
	{ dup 0 get exch dup 1 get exch 2 get }
	ifelse
      } ifelse
    } ifelse
  } ifelse
  % if the time is /Title or /title, set the font to
  % be the same.
  exch dup dup
  /Title eq
  exch
  /title eq
  or
    { pop pop /Title dup } if
  exch
} bdef

/extract-song-and-time-and-font	% takes a song spec and leaves three things
{				% on the stack - (song) (time) <font>.
  extract-song-and-time-and-font-1
  decode-song-font-name
} bdef

/song-fonts-w-scale 1 def
/song-fonts-h-scale 1 def
/song-fonts-title-w-scale 1 def

/decode-song-font-name	% takes a name, one of /R, /B, /I, /BI, or /Title
			% and converts that to a font scaled appropriately.
			% Leaves the font on the stack.
{
  song-font-height exch % put the height on the stack under the name.

  /titlep false def % set the Hack flag...

  % convert the name to a font-name.
  dup /B eq
  { pop song-font-bold }
  { dup /I eq
    { pop song-font-italic }
    { dup /BI eq
      { pop song-font-bold-italic }
       { dup /Title eq
	 exch /title eq or
	 % if the code was /Title or /title, take the default height off the
	 % stack and put the inner-album-font-height there instead.
	 { pop inner-album-font-height
	   inner-album-font
	   /titlep true def  % hack hack...
	   inner-album-font-color setcmykcolor	% if album, set color for album
	 }
	 {
	   song-font
	   song-font-color setcmykcolor		% not album, so must be song
	 }
	 ifelse
       } ifelse
    } ifelse
  } ifelse

  % set FH to the font height, leaving the font-name.
  exch /FH exch def
  % then find and scale the font, leaving it on the stack.
  findfont
  [ FH titlep {song-fonts-title-w-scale} {song-fonts-w-scale} ifelse mul
    0 0
    titlep { FH } { FH song-fonts-h-scale mul } ifelse
    0 0 ] makefont
} bdef

/compute-max-colheight
{
  songs1 compute-max-colheight-1
  songs2 compute-max-colheight-1
  max

  % Maybe this fixes something, I don't know...
  print-inner-album-titles-p
  {
    inner-album-font-height add
    one-column double-album-p not and { inner-album-font-height add } if
  } if

} bdef

/compute-max-colheight-1
{
  /total 0 def
  { extract-song-and-time-and-font-1
    exch pop exch pop
    /Title eq
    { /total total inner-album-font-height add 4 add def }
    { /total total song-font-height add def }
    ifelse
  } forall
  total
} bdef

/print-one-column		% write one column of the song listings
{
  /songs exch def
  /h exch def /w exch def
  /y exch def /x exch def
  gsave
    /w w 10 sub def
    /x x 5 add def
    one-column double-album-p not and not
      { /y y
	print-inner-album-titles-p { inner-album-font-height } { 0 } ifelse
	sub def } if
    x y translate
    /x 0 def
    /x2 x w add 5 sub def
    /y song-font-height neg def

    /maxh compute-max-colheight def
    maxh h y sub gt
    { 1 h y sub maxh div scale } if

    songs { extract-song-and-time-and-font
	    setfont
	    dup /Title eq
	    { /y y inner-album-font-height song-font-height sub sub def
	      pop x
	      one-column { margins add } { 5 sub } ifelse
	      dup /xx exch def
	      y moveto
	      show
	      underline-titles-p
	      {
		0 -2 rmoveto
		xx y 2 sub lineto stroke	 % underline it
	      } if
	      /y y inner-album-font-height song-font-height sub
		2 sub sub def		% frob y.
	    }
	    { exch
	      x y moveto
	      show
	      dup () ne {
		  song-time-font findfont
		  [ song-fonts-w-scale song-font-height mul 0 0
		    song-fonts-h-scale song-font-height mul 0 0 ]
		  makefont setfont
		  x2 y moveto
		  rightshow }
	      { pop }
	      ifelse
	    }
	    ifelse
	    /y y song-font-height song-fonts-h-scale mul sub def
	  } forall
  grestore
} bdef


/print-songs		% write a column of the song listings; 0=right.
{
  /left exch def
  gsave
    /x one-column { inner-width 20 sub max-songwidth sub 2 div 5 add }
		  { 10 } ifelse def
    /y	back-spine-height spine-height add
	margins 3 mul add
	neg  def
    /w	one-column { max-songwidth 20 add } { inner-width 2 div } ifelse def
    /h	list-height
	one-column double-album-p not and not
	print-inner-album-titles-p and
	  { inner-album-font-height margins 2 mul add sub } if
	() date1 eq () date2 eq and not
	  { date-font-height margins 2 mul add sub } if
    def

    songs-go-inside
    { flip-songs
      { /y y list-height margins add add def }
      { /y y list-height margins add sub def }
      ifelse }
    if

    1 left eq
      { /songs songs1 def }
      { /x x w add def
	/songs songs2 def }
    ifelse

    x y w h songs print-one-column
  grestore
} bdef

/draw-icon
{
  gsave
    total-width 2 div
    cdp { true } { icons-go-inside } ifelse
     { total-height list-height 2 div margins add sub neg }
     { total-height list-height 1.5 mul margins dup add add sub neg }
    ifelse
    translate

    cdp {
      -90 rotate
      spine-height margins add neg 0 translate
      0.65 0.65 scale
     } if

    list-height dup scale
    columns-horizontally { -90 rotate } if
    flip-songs { 180 rotate } if

    cdp
    icons-go-inside songs-go-inside and
    icons-go-inside not songs-go-inside not and or
    or
      { { 1 exch sub icon-fade-factor mul 1 exch sub } settransfer
	  icon-color setcmykcolor
%%	  0 setgray % ..to work around bug in GhostScript 2.0's settransfer.
	}
    if
    magic-icon
  grestore
} bdef

/set-songfont	    % compute width-scale of fonts for song listings.
{
  /tfont song-time-font findfont song-font-height scalefont def
  /maxw 0 def
  /song-fonts-w-scale 1 def   % set to 1 for width computation.
  songs1 { extract-song-and-time-and-font
	   setfont
	   dup /Title eq
	    { pop pop () 0 }
	    { stringwidth pop }	 %% oops, this isn't taking into account
	   ifelse		 %% the /song-time-font.
	   exch stringwidth pop
	   add
	   maxw max
	   /maxw exch def
	 } forall
  songs2 { extract-song-and-time-and-font
	   setfont
	   dup /Title eq
	    { pop pop () 0 }
	    { stringwidth pop }
	   ifelse
	   exch stringwidth pop
	   add
	   maxw max
	   /maxw exch def
	 } forall
  /w  one-column
      { inner-width 20 sub }
      { inner-width 2 div 5 sub } ifelse
      def
  /max-songwidth maxw 20 add def
  max-songwidth w gt
    { /song-fonts-w-scale w max-songwidth div def
      /max-songwidth w def }
  if

  one-column double-album-p not and
  { /Imaxw inline-album-titles-max-stringwidth def
    /song-fonts-title-w-scale
      Imaxw max-songwidth gt { max-songwidth Imaxw div } { 1 } ifelse
      def
  } if
} bdef


/inline-album-titles-max-stringwidth
{
  /Imaxw 0 def
  /Imaxh 0 def
  /ofsws song-fonts-w-scale def
  /ofshs song-fonts-h-scale def
  /song-fonts-w-scale 1 def   % set to 1 for width computation.
  songs1 { extract-song-and-time-and-font
	   setfont
	   /Title eq
	    { stringwidth pop Imaxw max /Imaxw exch def
	      /Imaxh Imaxh inner-album-font-height add 4 add def }
	    { pop }
	   ifelse } forall
  songs2 { extract-song-and-time-and-font
	   setfont
	   /Title eq
	    { stringwidth pop Imaxw max /Imaxw exch def
	      /Imaxh Imaxh inner-album-font-height add 4 add def }
	    { pop }
	   ifelse } forall
  /song-fonts-w-scale ofsws def
  /song-fonts-h-scale ofshs def
  Imaxw
} bdef


/print-two-inner-album-titles	% write album titles above the song listings
{
  gsave
    /x 10 def
    /y	back-spine-height spine-height add
	margins 3 mul  add
	neg  def
    /w	inner-width 2 div 10 sub def
    /x2 w 20 add def

    one-column { /w2 w def } if

    songs-go-inside
    { flip-songs
      { /y y list-height margins add add def }
      { /y y list-height margins add sub def }
      ifelse }
    if

    /font  inner-album-font findfont inner-album-font-height scalefont	def
    font setfont
    /maxw albumname1 albumname2 max-stringwidth def
    /maxw maxw inline-album-titles-max-stringwidth max def

    /song-fonts-title-w-scale
      maxw w gt { w maxw div } { 1 } ifelse
    def

    print-inner-album-titles-p
    {
      font [ song-fonts-title-w-scale 0 0 1 0 0 ] makefont setfont

      gsave
	inner-album-font-color setcmykcolor
	x y w inner-album-font-height 1.5 add box clip newpath
	x  y inner-album-font-height sub 2 add	moveto
	albumname1 show
	underline-titles-p
	{
	  0 -2 rmoveto
	  x  y inner-album-font-height sub  lineto stroke       % underline it.
	} if
      grestore
      gsave
	inner-album-font-color setcmykcolor
	x2 y w inner-album-font-height 1.5 add box clip newpath
	x2 y inner-album-font-height sub 2 add	moveto
	albumname2 show
	underline-titles-p
	{
	  0 -2 rmoveto
	  x  y inner-album-font-height sub  lineto stroke       % underline it.
	} if
      grestore
    grestore
    } if
} bdef


/print-one-inner-album-title	% write album title centered above songs.
{
  gsave
    /x margins dup add def
    /y	back-spine-height spine-height add
	margins 3 mul  add
	neg  def
    /w	inner-width margins 2 add sub def
    /w2 inner-width 2 div margins 2 add sub def

    one-column { /w2 w def } if

    songs-go-inside
    { flip-songs
      { /y y list-height margins add add def }
      { /y y list-height margins add sub def }
      ifelse }
    if

    /font inner-album-font findfont inner-album-font-height scalefont def
    font setfont
    /maxw albumname1 stringwidth pop def
    /innerw inline-album-titles-max-stringwidth def
    /maxw maxw innerw max def

    /w3 innerw 0 eq { w } { w2 } ifelse def
    /song-fonts-title-w-scale
      maxw w3 gt
      { w3 maxw div } { 1 } ifelse
    def

    print-inner-album-titles-p
    {
      font [ song-fonts-title-w-scale 0 0 1 0 0 ] makefont setfont

      gsave
	inner-album-font-color setcmykcolor
	x y w inner-album-font-height 1.5 add box clip newpath
	x w 2 div add  y inner-album-font-height sub 2 add  moveto
	albumname1 centershow
	newpath
	underline-titles-p
	{
	  x  y inner-album-font-height sub  moveto
	  w
	  columns-horizontally not { margins sub } if   % fmh!
	  columns-horizontally one-column and { margins dup add sub } if % FMH!
	  0 rlineto stroke
	} if
      grestore
    } if
  grestore
} bdef


/print-inner-album-titles
{
  double-album-p
  { print-one-inner-album-title }
  { print-two-inner-album-titles }
  ifelse
} bdef


/print-one-date		% write a date centered below the song listings
{
  gsave
    /x 10 def
    /y	back-spine-height spine-height add
	list-height  add
	margins 2 mul  add
	print-inner-album-titles-p { inner-album-font-height sub } if
	neg  def
    /w	inner-width x sub def

    songs-go-inside
    { flip-songs
      { /y y list-height margins add add def }
      { /y y list-height margins add sub def }
      ifelse }
    if

    date-font findfont date-font-height scalefont setfont
    date-font-color setcmykcolor
    newpath
    x w 2 div add  y
      print-inner-album-titles-p { inner-album-font-height } { 0 } ifelse
      sub 2 add	 moveto
    /datew date1 stringwidth pop def
    datew w gt { currentfont [ w datew div 0 0 1 0 0 ] makefont setfont } if
    date1 centershow
  grestore
} bdef


/print-two-dates		% write the dates below the song listings
{
  gsave
    /x 25 def
    /y	back-spine-height spine-height add
	list-height add
	margins 2 mul  add
	date-font-height sub
	neg  def
    /w	inner-width 2 div def
    /x2 w x add def

    songs-go-inside
    { flip-songs
      { /y y list-height margins add add def }
      { /y y list-height margins add sub def }
      ifelse }
    if

    date-font findfont date-font-height scalefont setfont
    date-font-color setcmykcolor
    /datew date1 date2 max-stringwidth def
    gsave
      date-font-color setcmykcolor
      x y w date-font-height box clip newpath
      x	 y date-font-height sub 2 add  moveto
      datew w x sub gt
	{ currentfont [ w x sub datew div 0 0 1 0 0 ] makefont setfont } if
      date1 show
    grestore
    gsave
      date-font-color setcmykcolor
      x2 y w date-font-height box clip newpath
      x2  y date-font-height sub 2 add	moveto
      datew w x sub gt
	{ currentfont [ w x sub datew div 0 0 1 0 0 ] makefont setfont } if
      date2 show
    grestore
  grestore
} bdef

/print-dates
{
  one-column double-album-p not and
  { () date1 eq
    { /date1 date2 def
      /date2 () def }
    { () date2 eq not
      {
	/l1 date1 length def
	/l2 date2 length def
	/s l1 l2 add 2 add string def
	0 1 l1 1 sub { s exch dup date1 exch get put } for
	s l1 (,) 0 get put
	s l1 1 add ( ) 0 get put
	0 1 l2 1 sub { s exch dup date2 exch get exch l1 2 add add exch put }
	  for
	/date1 s def
	/date2 () def
      } if
    } ifelse
  } if
  double-album-p one-column or
  { print-one-date }
  { print-two-dates }
  ifelse
} bdef


% This is such an incredible hack.  This program is way outta control...
/print-additional-info
{
  gsave
    /old-sf song-font def
    /old-sfb song-font-bold def
    /old-sfi song-font-italic def
    /old-sfbi song-font-bold-italic def
    /old-sfh song-font-height def
    /old-piatp print-inner-album-titles-p def
    /old-flip flip-songs def
    /old-sfc {song-font-color} def

    /song-font additional-info-font def
    /song-font-bold additional-info-font-bold def
    /song-font-italic additional-info-font-italic def
    /song-font-bold-italic additional-info-font-bold-italic def
    /song-font-height additional-info-font-height def
    /print-inner-album-titles-p false def
    /flip-songs flip-additional-info def
    /songs-go-inside songs-go-inside not def
    /song-font-color {additional-info-font-color} def

    columns-horizontally
    {
      inner-width margins add
      old-flip { neg } if
      list-height margins 3 mul add
      old-flip flip-songs and { margins sub } if
      old-flip { margins 3 mul sub neg } if
      translate
    } if

    flip-songs
    { 180 rotate total-width neg
      list-height
      columns-horizontally { margins 2 mul add } if
       spine-height back-spine-height add margins 3 mul add 2 mul
      add
      translate
    } if

    old-flip
    { 0 list-height 2 mul margins dup add add
      flip-songs { neg } if
      translate
    } if


    /songs1 additional-info-1 false eq { [] } { additional-info-1 } ifelse def
    /songs2 additional-info-2 false eq { [] } { additional-info-2 } ifelse def
    one-column
    {
      songs1 aload pop
      songs2 aload pop
      songs1 length songs2 length add array astore
      /songs1 exch def
      /songs2 [] def
    } if
    set-songfont
    0 print-songs
    1 print-songs

    /songs1 false def
    /songs2 false def
    /song-font old-sf def
    /song-font-bold old-sfb def
    /song-font-italic old-sfi def
    /song-font-bold-italic old-sfbi def
    /song-font-height old-sfh def
    /print-inner-album-titles-p old-piatp def
    /songs-go-inside songs-go-inside not def
    /flip-songs old-flip def
    /song-font-color {old-sfc} def

  grestore
} bdef

/compute-spine-font-xscale
{
  % compute horizontal size of largest band name string...
  magic-name-p
   { magic-name-width }
   { band-font findfont band-font-height scalefont setfont
     bandname1 bandname2 max-stringwidth }
  ifelse
  % compute horizontal size of largest album name string...
  album-font findfont album-font-height scalefont setfont
  albumname1 albumname2 max-stringwidth
  albumname3 albumname4 max-stringwidth max
  add			  % add them and divide inner-width by them to get
  spine-height mul	  % the ratio to scale the fonts by.  If this is
  inner-width		  % less than 1, don't do any scaling.
  10 sub     % subtract 10 from inner-width to account for the 5 point margin
	     % between the text and the right and left edges.
  % if the two fonts are the same height, insert an additional 10 point gap.
%  band-font-height album-font-height eq { 10 sub } if
  % no, always insert it.
  10 sub

  exch

  dup 0 eq
  { pop pop 1 }	% avoid division by 0 if the strings are empty...
  {
    div
    % don't scale up, only down.
    dup 1 ge { pop 1 } if
  } ifelse
} bdef


/box-name-printers-p false def	 % For debugging.  You don't want this.


/draw-spine		% draw the spine of the tape
{
  gsave
    margins  margins margins add  back-spine-height add neg  translate

    flip-spine not { 180 rotate inner-width neg spine-height translate } if

    0 0	 inner-width  spine-height
    spine-fill-color setcmykcolor
    box fill			       % the box around the spine
    0 0	 inner-width  spine-height
    spine-box-color setcmykcolor
    box stroke			       % the box around the spine
    0 0	 inner-width  spine-height  box clip newpath

    % Based on code from Joerg Stippa <stippa@isa.de>
    tape-id () eq not
    {
      inner-width		% save value on stack
      gsave
	tape-id-font findfont tape-id-font-height scalefont setfont
	/additional-indent tape-id-font-height 1.5 mul def
	/inner-width inner-width additional-indent sub def
	-90 rotate
	tape-id-background-color setcmykcolor
	1 1 spine-height 2 sub tape-id-font-height 1.25 mul neg box fill
	tape-id-font-color setcmykcolor
	1 1 spine-height 2 sub tape-id-font-height 1.25 mul neg box stroke
	spine-height 2 div tape-id-font-height 0.3 mul moveto
	tape-id centershow
      grestore
      additional-indent 0 translate
    } if

    margins spine-height neg translate
    /xscale compute-spine-font-xscale def
    gsave
      band-font-color setcmykcolor
      0 0 moveto
      spine-height xscale mul spine-height scale
      magic-name-p
      { box-name-printers-p  % debugging magic-name-printer sizing.
	{ 0 setgray 0 0 magic-name-width -1 box fill
	  { 1 exch sub } settransfer 0.01 setlinewidth 0 setgray
	  0 1 9 { 0 moveto 0 1 rlineto stroke } for }
	if
%	bandname2 () eq not
%	{
%	  0 0.6 translate
%	  0.45 0.45 scale
%	  gsave magic-name grestore
%	  0 -1 translate
%	  magic-name2
%	}
%	{
	  0 0.2222 translate
	  0.9 0.9 scale
	  magic-name
%	} ifelse
      }
      { band-font findfont band-font-height scalefont setfont
	0 1 band-font-height sub moveto
	same-band-p { 0 -0.1 rmoveto } if
	bandname1 show
	0 1 band-font-height dup add sub moveto
	bandname2 show
      }
      ifelse
    grestore
    inner-width margins sub margins sub 0 translate
    gsave
      album-font-color setcmykcolor
      spine-height xscale mul spine-height scale
      /afh album-font-height def
      album-font findfont afh scalefont setfont
      1 afh sub
      dup 0 exch moveto
      double-album-p { 0 -0.1 rmoveto } if
      % albumname1 and albumname2 are the first album on each side.
      % albumname3 and albumname4 are the second album on each side.
      albumname1 () eq not {		      albumname1 rightshow afh sub }if
      albumname3 () eq not {dup 0 exch moveto albumname3 rightshow afh sub }if
      albumname2 () eq not {dup 0 exch moveto albumname2 rightshow afh sub }if
      albumname4 () eq not {dup 0 exch moveto albumname4 rightshow }if
      pop
    grestore
    tape-id () eq not { /inner-width exch def } if	% pop old value
  grestore
} bdef

/coerce-to-array-of-strings	% if given a string, puts it in an array.
{
  dup
  type /stringtype eq
  { 1 array astore }
  if
} bdef


/draw-back-spine		% draw the short flap on the back.
{
  /x margins def
  /y margins neg def
  /w inner-width def
  /h back-spine-height def
  gsave
    x y w h box
    back-spine-fill-color setcmykcolor
    fill
    x y w h box
    back-spine-box-color setcmykcolor
    stroke
    x y w h box clip newpath
    x w add  y h add neg  translate
    180 rotate
    signature-font findfont signature-font-height scalefont setfont
    signature-font-color setcmykcolor
    /s signature coerce-to-array-of-strings def
    /sx margins
	centered-signature { w 2 div add } if
    def
    /sy h margins 3 mul sub neg
	s length 1 sub signature-font-height mul add
       def
    s { sx sy moveto
	centered-signature { centershow } { show } ifelse
	/sy sy signature-font-height sub def
      } forall
  grestore
} bdef


/reset			% resets all the tape-specific parameters.
{
  /tape-id () def
  /bandname1 () def
  /bandname2 () def
  /albumname1 () def
  /albumname2 () def
  /albumname3 () def
  /albumname4 () def
  /date1 () def
  /date2 () def
  /magic-name-p false def
  /magic-icon-p false def
  /double-album-p false def
  /same-band-p false def
  /dolby false def
  /additional-info-1 false def
  /additional-info-2 false def

  %% This shouldn't be necessary, but it seems to be.
  %% As I said, this program is way outta control...
  /song-fonts-w-scale 1 def
  /song-fonts-h-scale 1 def
  /song-fonts-title-w-scale 1 def
} bdef

reset			% do it now to give them their initial values.
/signature () def	% probably redefined later.


/draw-tape-label	% draw one.  Assumes all variables have been filled in.
{			% Takes X and Y on the stack.
  /tty exch def
  /ttx exch def

  save-is-broken not { save } if

  gsave
    90 rotate
    ttx tty translate

    datap {
      90 rotate
      total-width neg 0 translate
     } if

    cdp {
      total-width 0 translate		% assumes one per sheet
     } if

    %% Big box (around everything)
    0 0 total-width total-height
    big-box-fill-color setcmykcolor	% set new color
    box fill				% fill box

    0 0 total-width total-height
    big-box-box-color setcmykcolor	% set new color
    box stroke				% draw box

    %% Outside Box (flap)
    cdp not {
      margins total-height neg
	      list-height 2 mul add
	      margins 2 mul add
      inner-width list-height
      outside-fill-color setcmykcolor	% set new color
      box fill				% draw a box around the back.
    } if

    cdp not {
      margins total-height neg
	      list-height 2 mul add
	      margins 2 mul add
      inner-width list-height
      outside-box-color setcmykcolor	% set new color
      box stroke			% draw a box around the back.
    } if

    %% Inside Box (flap)
    margins total-height neg
	    list-height add
	    margins add
            cdp { spine-height margins add add } if
    inner-width list-height
    inside-fill-color setcmykcolor	% set new color
    box fill				% draw a box around the listings.

    margins total-height neg
	    list-height add
	    margins add
            cdp { spine-height margins add add } if
    inner-width list-height
    inside-box-color setcmykcolor		% set new color
    box stroke				% draw a box around the listings.

    cdp {
      gsave
        180 rotate
        total-width neg spine-height margins 3 mul add translate
        draw-spine
      grestore
      gsave
        0 total-height margins sub neg translate
        0 spine-height margins dup add add translate
        draw-spine
      grestore
    }
    {
      draw-back-spine
      draw-spine
    } ifelse

    0 0 total-width total-height
    spine-box-color setcmykcolor		% set new color
    box					% draw the outermost box.

    magic-icon-p { draw-icon } if

    % You are not expected to understand this.
    %
    flip-songs
    { 180 rotate total-width neg
      list-height
       spine-height back-spine-height add margins 3 mul add 2 mul
      add
      translate } if

    /frobbed-columns false def
    columns-horizontally
    cdp { not } if
    { /frobbed-columns true def
      -90 rotate 0 inner-width translate
      back-spine-height spine-height add 3 margins mul add
      dup margins sub exch translate
      flip-songs
	{
	  columns-horizontally not
	  { 0 total-width neg margins add translate }
	  if
	  songs-go-inside
	  { list-height margins add neg total-width neg margins add translate }
	  if
	}
	{ songs-go-inside
	  { list-height margins add total-width translate }
	  if }
      ifelse
      one-column { margins 0 translate } if    % hack
      /iw inner-width def
      /inner-width list-height def
      /list-height iw def
      /total-width inner-width margins dup add add def
    } if

    cdp { margins neg 0 translate } if

    one-column
    { double-album-p not print-inner-album-titles-p and
      { [ albumname1 /Title ] } if
      songs1 aload pop
      double-album-p not { () } if
      double-album-p not print-inner-album-titles-p and
	 { albumname2 () eq not { [ albumname2 /Title ] } if } if
      songs2 aload pop
      songs1 length songs2 length add
      double-album-p not { 1 add } if
      double-album-p not print-inner-album-titles-p and
	 { albumname2 () eq not {2} {1} ifelse add } if
      array astore
      /songs1 exch def
      /songs2 [] def
      double-album-p print-inner-album-titles-p and
      { print-inner-album-titles } if
      set-songfont
      song-font-color setcmykcolor
      1 print-songs
    }
    { print-inner-album-titles
      set-songfont
      song-font-color setcmykcolor
      0 print-songs
      1 print-songs }
    ifelse

    cdp not  % argh
    additional-info-2 false ne additional-info-1 false ne or
    and
    { print-additional-info } if


    print-dates
    frobbed-columns  % fix up the sizes we've screwed with
      { DATp
	{DAT-sizes}
	{ 8mmp
	  {8mm-sizes}
	  { slimp
	    {slim-cassette-sizes}
	    { datap
	      {data-sizes}
	      { cdp
	        {cd-sizes}
	        {cassette-sizes}
                ifelse }
	      ifelse }
	    ifelse }
	  ifelse }
	ifelse
      } if

    % If we're printing for CDs, print out the booklet cover too.
    %
    cdp {

      margins 0 translate
      columns-horizontally {
        -90 rotate
        spine-height margins 2 mul add
        inner-width spine-height margins 3 mul add add
        translate
      } if


      spine-height margins 2 mul add neg
      inner-width spine-height margins 4 mul add add neg
      translate

      % Big box (around everything)
      0 0 cover-width cover-height
      spine-fill-color setcmykcolor	% set new color
      box fill				% fill box

      0 0 cover-width cover-height
      spine-box-color setcmykcolor	% set new color
      box stroke			% draw box

      inner-width			% save these
      spine-height
      {spine-box-color}
      {back-spine-fill-color}
      {back-spine-box-color}

      /spine-box-color {spine-fill-color} def
      /back-spine-box-color {spine-fill-color} def
      /back-spine-fill-color {spine-fill-color} def
      /inner-width cover-width 0.8 mul def
      /spine-height cover-height 0.1 mul def
      180 rotate
      inner-width neg spine-height translate
      cover-width -0.1 mul cover-height 0.1 mul translate
      draw-spine
      back-spine-height
      /back-spine-height 20 def
      0 cover-width 0.75 mul translate
      draw-back-spine
      /back-spine-height exch def

      /back-spine-box-color exch def	% restore these
      /back-spine-fill-color exch def
      /spine-box-color exch def
      /spine-height exch def
      /inner-width exch def

      /frobbed-columns true def

    } if


  grestore
  gsave
    print-inner-album-titles-p
    { 90 rotate ttx tty translate } if

    datap {
      90 rotate
      total-width neg 0 translate
     } if

    -90 rotate margins 2 add dup translate
    dolby false eq not cdp not and { draw-dolby } if
  grestore
  reset

  save-is-broken not
  {
    dup type /savetype eq not
    { (\nError: our save object is not at the top of the stack.\n) print
      (Possibly a magic-name-printer left junk on the stack?\n) print
      (Stack is:\n\n) print
      pstack
      flush
      stop
    } if
    restore
  } if

} bdef


/draw-tape-side-label	% draw one.  Assumes all variables have been filled in.
			% Takes X and Y on the stack.
{
  /tty exch def
  /ttx exch def

  save-is-broken not { save } if

  gsave

    tty ttx translate
    draw-spine

  grestore
  reset

  save-is-broken not
  {
    dup type /savetype eq not
    { (\nError: our save object is not at the top of the stack.\n) print
      (Possibly a magic-name-printer left junk on the stack?\n) print
      (Stack is:\n\n) print
      pstack
      flush
      stop
    } if
    restore
  } if

} bdef


% Do it like this instead of assuming it's in systemdict, so that we
% get any encapsulations that a previewer may have made as well.
% Suggested by Gregory Silvus <silvus@vauxhall.ece.cmu.edu>.
/orig-showpage /showpage load def

/showpage
{
  save-is-broken not { save } if
  gsave
    initgraphics
    0 setgray
    40 50 moveto 90 rotate

    tape-side-p { 0 -250 rmoveto } if

    currentpoint
    /Helvetica findfont 10 scalefont dup setfont
    (audio-tape.ps, version 1.29, ) show
    /Symbol findfont 10 scalefont setfont (\343) show
    setfont ( 1988-1999 Jamie Zawinski <jwz@jwz.org>) show
    moveto 0 -25 rmoveto
    currentpoint
    gsave
      currentpoint translate 10 10 scale
      1 0 translate recycle
    grestore
    moveto
    /Helvetica-Oblique findfont 8 scalefont setfont
    30 2 rmoveto
    currentpoint
    (If you aren't printing this on the back of a used sheet of paper,) show
    moveto
    0 -8 rmoveto
    (you should be feeling very guilty about killing trees right now.) show
  grestore
  save-is-broken not { restore } if
%  systemdict begin showpage end
  orig-showpage
} def


%% Dolby symbols.  This code is derived from code written by Michael L. Brown.
%%
/draw-dolby-internal
{
  gsave
    dolby-color setcmykcolor
    dup () eq
    { pop }
    {
      % text
      /Helvetica-Bold findfont 36 scalefont setfont
      92 12 moveto
      dup stringwidth pop /dolbytextw exch def
      show % from stack
      4 setlinewidth
      82 2 moveto
      0 46 rlineto
      dolbytextw 20 add 0 rlineto
      0 -46 rlineto
      closepath stroke
      % Trademark
% aaah, who needs this.
%      /Helvetica-Bold findfont 28 scalefont setfont
%      dolbytextw 110 add 29.5 moveto
%      (TM) show
    }
    ifelse
    % left D box
    0 0 moveto 0 50 rlineto 32 0 rlineto 0 -50 rlineto closepath fill
    % right D box
    38 0 moveto 0 50 rlineto 32 0 rlineto 0 -50 rlineto closepath fill
    1.0 setgray
    4 setlinewidth
    % left D
    10 8 moveto 0 34 rlineto stroke
    gsave
      back-spine-fill-color setcmykcolor
      newpath
      1.0 1.2142857 scale
      12 20.588236 14 270 90 arc fill
    grestore
    % right D
    60 8 moveto 0 34 rlineto stroke
    gsave
      back-spine-fill-color setcmykcolor
      newpath
      1.0 1.2142857 scale
      58 20.588236 14 90 270 arc fill
    grestore
    0.0 setgray
  grestore
} bdef

/draw-dolby	% stack: x y
{		% draw a dolby symbol at x,y, with a boxed string next to it.
  gsave		% if string=(), don't draw box.	 DD symbol is 1 point square.
    0.0143 9 mul dup scale
    dolby type /stringtype eq
    { dolby draw-dolby-internal }
    { /Helvetica-Bold findfont 36 scalefont setfont
      gsave
	5 setlinewidth
	/d dolby 3 string cvs def
	0 0 d stringwidth pop 12 add -36 box stroke
	7 7 translate 0 0 moveto d show
      grestore
    }
    ifelse
  grestore
} bdef

/Dolby	{ /dolby () def } def
/DolbyB { /dolby (DOLBY	 B) def } def
/DolbyC { /dolby (DOLBY	 C) def } def
/DolbyS { /dolby (DOLBY	 S) def } def
/AAD	{ /dolby /AAD def } def
/DAD	{ /dolby /DAD def } def
/ADD	{ /dolby /ADD def } def
/DDD	{ /dolby /DDD def } def
/dbx	{ /dolby /dbx def } def


%% A recycle logo, by hdavids@mswe.ms.philips.nl.
%% Colorized by John Werner <werner.wbst311@xerox.com>
/arrowback
{
  17.32	 62.32 moveto
 -24.00	 62.32 -45.00  25.94 11.6 arcto 4 {pop} repeat
 -45.00	 25.94 lineto
 -19.02	 10.94 lineto
  17.32	 73.89	34.50  44.13 11.6 arcto 4 {pop} repeat
  34.50	 44.13 lineto
  41.43	 48.13 lineto		% start arrowhead
  28.15	 25.13 lineto		% point of arrow
   1.59	 25.13 lineto		% inner extreme
   8.52	 29.13 lineto		% end of arrowhead
   0.00	 43.88 lineto
  gsave
    0.5 0.0 0.5 0.0 setcmykcolor	% dark green
    fill				% fill the symbol
  grestore
  stroke				% now outline it in prevailing color
} bdef

/arrowfront
{
 -17.32	 62.32 moveto
  24.00	 62.32	34.50  44.13 11.6 arcto 4 {pop} repeat
  34.50	 44.13 lineto
  41.43	 48.13 lineto		% start arrowhead
  28.15	 25.13 lineto		% point of arrow
   1.59	 25.13 lineto		% inner extreme
   8.52	 29.13 lineto		% end of arrowhead
 -17.32	 73.89 -45.00  25.94 11.6 arcto 4 {pop} repeat
 -45.00	 25.94 lineto
 -19.02	 10.94 lineto
   0.00	 43.88 lineto
  gsave
    0.5 0.0 0.5 0.0 setcmykcolor	% dark green
    fill				% fill the symbol
  grestore
  stroke				% now outline it in prevailing color
} bdef

/recycle
{
  gsave
    0.015 0.015 scale
    4 setlinewidth
    arrowback
    120 rotate
    arrowfront
    120 rotate
    arrowfront
  grestore
} bdef

%%% Using the ISO/8859-1 encoding.  This might not work on some older printers.

/reencode-Latin1
{
  dup dup findfont dup length dict begin
    { 1 index /FID ne { def } { pop pop } ifelse } forall
    /Encoding ISOLatin1Encoding def
    currentdict end definefont
    def
} def

%%% Case-insensitive dictionary lookup.	 Yowza.

/nsdc-buf 255 string def
/nstring-downcase	% target-string source-string
{			% convert a string to lowercase; copies source-string
			% into target-string, doing the conversion.  The two
			% strings may be the same, and the source-string may
			% be a 'name'.
  dup type /nametype eq { nsdc-buf cvs } if
  0 exch
  { dup dup 65 ge
    exch 90 le and
     { 32 add } if
    exch dup
    4 1 roll exch
    2 index 5 1 roll
    put 1 add
  } forall
  pop
} bdef

/CIget { % like get, but uses a lowercase version of the string.
    dup length string exch nstring-downcase cvn get
} bdef

/CIput { % like put, but uses a lowercase version of the string.
    exch dup length string exch nstring-downcase cvn exch put
} bdef

/CIknown { % like known, but uses a lowercase version of the string.
    dup length string exch nstring-downcase cvn known
} bdef


% Dictionaries for storing magic band-name-and-icon-rendering functions.
%
/magic-name-dict 200 dict def
/magic-icon-dict 200 dict def

% Invoke the magic band-name-rendering function for the current band.
%
/magic-icon
{ magic-icon-dict bandname1 CIknown
  { magic-icon-dict bandname1 CIget exec }
  { magic-icon-dict /default-icon-printer known
    { magic-icon-dict /default-icon-printer get exec }
    if }
  ifelse
} bdef

/magic-name  { magic-name-dict bandname1 CIget 0 get exec } bdef
/magic-name2 { magic-name-dict bandname2 CIget 0 get exec } bdef

/magic-name-width { magic-name-dict bandname1 CIget 1 get } bdef


% Decide whether this band has a magic rendering function.
%
/check-magic
{
  /magic-name-p magic-name-dict bandname1 CIknown def
  /magic-icon-p magic-icon-dict bandname1 CIknown
		magic-icon-dict /default-icon-printer known or
  def
} bdef


% Define a new magic-name printer.
/define-magic-name-printer		% arguments: bandname procedure width
{
   2 array astore
   magic-name-dict  % stack: band [proc w] dict
   3 1 roll	    % stack: dict band [proc w]
   CIput
} bdef


/dump-internal
{
  DATp { tick 2 eq {550} { tick 1 eq {300} {50} ifelse } ifelse }
       { tick 1 eq {360} {50} ifelse }
  ifelse
  -100 draw-tape-label
  tick DATp { 2 } { datap cdp or { 0 } { 1 } ifelse } ifelse eq
  { showpage } if
  /tick tick 1 add DATp { 3 } { datap cdp or { 1 } { 2 } ifelse } ifelse
     mod def
  reset
} bdef


/dump-internal-tape-side
{
  gsave
    newpath clippath pathbbox	% x1 y1 x2 y2
    /y2 exch def
    /x2 exch def
    /y1 exch def
    /x1 exch def
    /page-width  x2 x1 sub def
    /page-height y2 y1 sub def
  grestore

  page-height tick 1 add label-span mul inter-label-height sub
		page-top-margin add sub
  left-margin
   draw-tape-side-label
  /tick tick 1 add def
  tick labels-per-page eq
    { /tick 0 def
      showpage } if
  reset
} bdef



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%								%%%%%%%%
%%%%%%%			The user-level functions.		%%%%%%%%
%%%%%%%								%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

/two-albums	% arguments:  bandname album1 date1 album2 date2 songs1 songs2
{
  /songs2 exch def
  /songs1 exch def
  /date2 exch def
  /albumname2 exch def
  /date1 exch def
  /albumname1 exch def
  /bandname1 exch def
  /same-band-p true def
  /band-font-height  0.6 def
  /album-font-height 0.4 def
  check-magic
  dump-internal
} bdef


/two-bands  %args: bandname1 album1 date1 songs1 bandname2 album2 date2 songs2
{
  /songs2 exch def
  /date2 exch def
  /albumname2 exch def
  /bandname2 exch def
  /songs1 exch def
  /date1 exch def
  /albumname1 exch def
  /bandname1 exch def
  /band-font-height  0.4 def
  /album-font-height 0.4 def
  /magic-name-p false def
  /magic-icon-p false def
%  check-magic
  dump-internal
} bdef


/double-album	% arguments:  bandname album date songs1 songs2
{
  /songs2 exch def
  /songs1 exch def
  /date1 exch def
  /albumname1 exch def
  /bandname1 exch def
  /band-font-height  0.6 def
  /album-font-height 0.6 def
  /double-album-p true def
  /same-band-p true def
  check-magic
  dump-internal
} bdef


/N-albums  %args:  bandname album1.1 album1.2 date1 album2.1 album2.2 date2 songs1 songs2
{
  /songs2 exch def
  /songs1 exch def
  /date2 exch def
  /albumname4 exch def
  /albumname2 exch def
  /date1 exch def
  /albumname3 exch def
  /albumname1 exch def
  /bandname1 exch def

  /band-font-height 0.6 def
  () albumname3 eq () albumname4 eq and
  { /album-font-height 0.4 def }
  { () albumname3 eq () albumname4 eq or
    { /album-font-height 0.3125 def }
    { /album-font-height 0.21875 def }
    ifelse }
  /same-band-p band-font-height 0.6 eq def
  ifelse

  check-magic
  dump-internal
} bdef


/two-bands-N-albums  % arguments:  band1 album1.1 album1.2 date1 songs1 band2 album2.1 album2.2 date2 songs2
{
  /songs2 exch def
  /date2 exch def
  /albumname4 exch def
  /albumname2 exch def
  /bandname2 exch def
  /songs1 exch def
  /date1 exch def
  /albumname3 exch def
  /albumname1 exch def
  /bandname1 exch def

  /band-font-height 0.4 def
  () albumname3 eq () albumname4 eq and
  { /album-font-height 0.4 def }
  { () albumname3 eq () albumname4 eq or
    { /album-font-height 0.3125 def }
    { /album-font-height 0.21875 def }
    ifelse }
  ifelse
  /magic-name-p false def
  /magic-icon-p false def
  dump-internal
} bdef


%% The interfaces to the side-labels.


%% One band name on the left, one album on the right.
/one-album-tape-side	% arguments:  band album
{
  /albumname1 exch def
  /bandname1 exch def
  /band-font-height  0.6 def
  /album-font-height 0.6 def
  /double-album-p false def
  /same-band-p true def
  check-magic
  dump-internal-tape-side
} bdef

%% Band name on the left, two album names on two lines on the right
%% This can also be used if you want to indicate the side on the left, e.g.
%%
%%			Some Band
%%   1
%%		  Some Album Name
%%
%% is obtained with (1) (Some Band) (Some Album Name) two-album-tape-side.
%% This means the side indication is printed in the band font, and the
%% band and album are both printed in the album font.

/two-album-tape-side	% arguments: band album1 album2
{
  /albumname2 exch def
  /albumname1 exch def
  /bandname1 exch def
  /band-font-height  0.6 def
  /album-font-height 0.4 def
  /double-album-p true def
  /same-band-p true def
  check-magic
  dump-internal-tape-side
} bdef

/two-band-tape-side	% arguments: band1 album1 band2 album2
{
  /albumname2 exch def
  /bandname2 exch def
  /albumname1 exch def
  /bandname1 exch def
  /band-font-height  0.4 def
  /album-font-height 0.4 def
  /double-album-p true def
  /same-band-p false def
%  check-magic
  dump-internal-tape-side
} bdef

%% Two band names on two lines on the left, one album name on the right
%% This can also be used if you want to indicate the side on the right, e.g.
%%
%%  Some Band
%%   				1
%%  Some Album Name
%%
%% is obtained with
%%  (Some Band) (Some Album Name) (1) two-band-one-album-tape-side.
%% This means the side indication is printed in the album font, and the
%% band and album are both printed in the band font.

/two-band-one-album-tape-side	% arguments: band1 band2 album
{
  /albumname1 exch def
  /bandname2 exch def
  /bandname1 exch def
  /band-font-height  0.4 def
  /album-font-height 0.6 def
  /double-album-p true def
  /same-band-p false def
%  check-magic
  dump-internal-tape-side
} bdef


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%								%%%%%%%%
%%%%%%%			The Magic-Name Printers.		%%%%%%%%
%%%%%%%								%%%%%%%%
%%%%%%%	   These routines will be automatically invoked to	%%%%%%%%
%%%%%%%	   draw certain band-names, so that you can have	%%%%%%%%
%%%%%%%	   really hi-tech tape-labels.	Add more!		%%%%%%%%
%%%%%%%								%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%% Draw "Front 242" as a long, thin "front" over a long, tall "242".
%%%
(Front 242)
  {
    gsave
      0 -0.1 translate
      0.95 1 scale
      /Helvetica-Bold findfont [ 1.35 0 0 0.4 0 0 ] makefont  setfont
      0 0.58 moveto
      (FRONT) show
      /Helvetica-Bold findfont [ 2.85 0 0 0.7 0 0 ] makefont  setfont
      0 0 moveto (242) show
    grestore
  } bind
  4
define-magic-name-printer

%%% Draw "Orchestral Manoeuveres in the Dark" on two lines; use the
%%% "oe" character.
%%%
(Orchestral Manoeuveres in the Dark)
  {
    gsave
      0 -0.1 translate
      0.7 1 scale
      /Helvetica-Bold findfont [0.45 0 0 0.65 0 0] makefont setfont
      0.1 0.35 moveto
      (ORCHESTRAL MAN\352UVRES) show
      /Helvetica findfont [1 0 0 0.3 0 0] makefont setfont
      0.1 0.05 moveto
      (IN THE DARK) show
    grestore
  } bind
  4.2
define-magic-name-printer


%%% Draw "OMD" in the same way as "Orchestral Manoeuveres in the Dark".
%%%
magic-name-dict (OMD) cvn
  magic-name-dict (Orchestral Manoeuveres in the Dark) cvn CIget
CIput


%%% Draw "New Order" as a dark "New" over an outlined "Order", staggered.
%%%

(New Order)
  {
    gsave
      0 -0.1 translate
      0.02 setlinewidth
      1.5 setmiterlimit
      /Helvetica-Bold findfont setfont
      0 0.1 moveto
      (Order) true charpath stroke
      1.57 0.1 moveto
      (new) show
    grestore
  } bind
  3.2
define-magic-name-printer


%%% Draw "Siouxsie and the Banshees" with varying-height letters,
%%% like on the early albums.
%%%

(Siouxsie and the Banshees)
  {
    gsave
      0 -0.1 translate
      0.7 0.4 scale
      0.1 0.25 translate
      /big-font	  /Helvetica findfont [ 0.5 0 0 2.2 0 0 ] makefont  def
      /med-font	  /Helvetica findfont [ 0.5 0 0 1.1 0 0 ] makefont  def
      /small-font /Helvetica findfont [ 0.5 0 0 1.5 0 0 ] makefont  def
      0 -0.1 5.9 -1.8 box clip newpath
      0 0 moveto
      big-font setfont (SI) show
      0 0.8 rmoveto
      small-font setfont (o) show
      0 -0.8 rmoveto
      big-font setfont (UXSIE) show
      med-font setfont
      currentpoint /y exch def /x exch def
      .07 0.85 rmoveto
      (and) show x y moveto (THE) show
      big-font setfont (BANSHE) show
      0 0.8 rmoveto
      small-font setfont (e) show
      0 -0.8 rmoveto
      big-font setfont (S) show
    grestore
  } bind
  4
define-magic-name-printer


%%% Draw "Cabaret Voltaire" in their font.  I should probably have
%%% implemented this as a font, instead of as a set of procedures,
%%% but life's too short.
%%%

(Cabaret Voltaire)
  {
    gsave
      0 -0.1 translate
      0.5 0.5 scale
      1.8 setmiterlimit 0.1 setlinewidth
      0.2 0.3 moveto cabaret-c 0.5 0 rmoveto cabaret-a
      0.7 0 rmoveto cabaret-b  0.6 0 rmoveto cabaret-a
      0.7 0 rmoveto cabaret-R  0.6 0 rmoveto cabaret-e
      0.4 0 rmoveto cabaret-T  1.0 0 rmoveto cabaret-v
      0.6 0 rmoveto cabaret-o  0.7 0 rmoveto cabaret-L
      0.6 0 rmoveto cabaret-t  0.4 0 rmoveto cabaret-A
      0.45 0 rmoveto cabaret-I 0.45 0 rmoveto cabaret-r
      0.5 0 rmoveto cabaret-e
    grestore
  } bind
  4.1
define-magic-name-printer

%% Internal procedures to the "Cabaret Voltaire" printer.
%%
/cabaret-c { gsave currentpoint translate newpath 0.5 0.25 moveto 0.25 0 lineto
  0 0.5 lineto 0.25 1 lineto 0.5 0.75 lineto stroke grestore } bdef

/cabaret-a { gsave currentpoint translate newpath 0.25 0.75 moveto 0.5 1 lineto
   0.5 0 lineto 0 0.5 lineto 0.5 0.5 lineto stroke grestore } bdef

/cabaret-b { gsave currentpoint translate newpath 0 1 moveto 0 0 lineto
  0.5 0.5 lineto 0 0.5 lineto stroke grestore } bdef

/cabaret-R { gsave currentpoint translate newpath 0 0 moveto 0 1 lineto 0.5 0.5
  lineto 0 0.5 lineto 0.25 0.5 moveto 0.5 0 lineto stroke grestore } bdef

/cabaret-e { gsave currentpoint translate newpath 0.375 0.25 moveto
  0.25 0 lineto 0 0.5 lineto 0.25 1 lineto 0.5 0.5 lineto 0 0.5 lineto stroke
  grestore } bdef

/cabaret-T { gsave currentpoint translate newpath 0 1 moveto 0.5 1 lineto
  0.25 1 moveto 0.25 0 lineto stroke grestore } bdef

/cabaret-v { gsave currentpoint translate newpath
  0 1 moveto 0.25 0 lineto 0.5 1 lineto stroke grestore } bdef

/cabaret-o { gsave currentpoint translate newpath 0.25 1 moveto 0.5 0.5 lineto
  0.25 0 lineto 0 0.5 lineto closepath stroke grestore } bdef

/cabaret-L { gsave currentpoint translate newpath 0 1 moveto
    0 0.10 lineto 0.5 0.10 lineto stroke grestore } bdef

/cabaret-t { gsave currentpoint translate newpath 0 1 moveto
  0 0 lineto 0.275 0.25 lineto stroke 0 0.75 moveto 0.25 0.75 lineto stroke
  grestore } bdef

/cabaret-A { gsave currentpoint translate newpath 0 0 moveto 0.25 1 lineto
  0.5 0 lineto stroke 0.125 0.5 moveto 0.375 0.5 lineto stroke grestore } bdef

/cabaret-I { gsave currentpoint translate newpath 0.25 0 moveto 0.25 1 lineto
  stroke grestore } bdef

/cabaret-r { gsave currentpoint translate newpath 0 0 moveto 0 1 lineto stroke
  0 0.75 moveto 0.25 1 lineto 0.5 0.75 lineto stroke grestore } bdef


(Nine Inch Nails)
  { gsave
      0 0 moveto
      /Helvetica findfont [ 1 0 0 1 0 0] makefont
      /Helvetica findfont [-1 0 0 1 0 0] makefont
      dup setfont
      gsave
	90 rotate 0.3 -0.2 translate 0.7 0.7 scale NiNbox
      grestore
      /nw (n)stringwidth pop neg def
      0.6 0 moveto
      nw 0 rmoveto (n)show
      nw 0 rmoveto exch dup setfont (i)show
      nw 0 rmoveto exch dup setfont (n)show
      nw 0 rmoveto exch dup setfont (e i)show
      nw 0 rmoveto exch dup setfont (n)show
      nw 0 rmoveto exch dup setfont (ch )show
      nw 0 rmoveto exch dup setfont (n)show
      nw 0 rmoveto exch dup setfont (ails)show
      pop pop
    grestore } bind
  6.3
define-magic-name-printer

%% Draw "Depeche Mode" as on their "Some Great Reward"
%% "depeche" (in lower case) over a larger "MODE"
%% By Roderick Lee <agitator@ucsd.edu>
%%
(Depeche Mode)
  {
    gsave
    0 -0.1 translate
    0.95 1 scale
	/Helvetica-Bold findfont [ 0.60 0 0 0.50 0 0 ] makefont setfont
	0.05 0.51 moveto
	(depeche) show
	/Helvetica-Bold findfont [ 0.84 0 0 0.70 0 0 ] makefont setfont
	0 -0.05 moveto
	(MODE) show
    grestore
  } bind
  2
define-magic-name-printer


(Jaco Pastorius)	% by Shamim Zvonko Mohamed <sham@cs.arizona.edu>
  {
    gsave
      currentpoint translate
      0.6 1 scale
      0.1 setlinewidth 1 setlinecap
      0.8 0.9 moveto
      0.6 0.1 0.4 0.1 0.1 0.3 curveto stroke
      1.2 0.2 moveto
      0.9 0.05 1.2 0.9 1.5 0.1 curveto stroke
      2.1 0.1 moveto
      1.8 0.2 1.85 0.5 2.05 0.45 curveto stroke
      2.6 0.2 translate
      0 0 0.1 0 360 arc stroke
    grestore
  } bind
  2
define-magic-name-printer


%% Draw "ZZ Top" as on their "Recycler" just uncircled
%% By Stefan B Karlsson <sk177@lu.erisoft.se>
%%
(ZZ Top)
  {
    gsave
      0.3 0.14 scale
      2 -4.5 translate
      20 rotate
      0.04 setlinewidth
      0.5 4 TheZ
      1 2.9 TheZ
      4.8 5.1 TheT
      6.3 5.1 TheO
      7.6 5.1 TheP
    grestore
  } bind
  4
define-magic-name-printer

/TheZ
{
  newpath moveto
  8.5 0 rlineto
  1 1 rlineto
  -7 0 rlineto
  3 3 rlineto
  -4.5 0 rlineto
  -1 -1 rlineto
  3 0 rlineto
  -3 -3 rlineto
  closepath
  gsave
    0.8 setgray
    fill
  grestore
  stroke
} bdef

/TheT
{
  newpath moveto
  0.4 0 rmoveto
  0.6 0 rlineto
  1.3 1.3 rlineto
  0.4 0 rlineto
  0.5 0.5 rlineto
  -1.4 0 rlineto
  -0.5 -0.5 rlineto
  0.4 0 rlineto
  closepath
  gsave
    0.8 setgray
    fill
  grestore
  stroke
} bdef

/TheO
{
  2 copy
  newpath
  moveto
  1.2 0 rlineto
  1.8 1.8 rlineto
  -1.2 0 rlineto
  closepath
  gsave
    0.8 setgray
    fill
  grestore
  stroke
  newpath
  moveto
  .9 .5 rmoveto
  .4 0 rlineto
  .9 .9 rlineto
  -.4 0 rlineto
  closepath
  gsave
    1 setgray
    fill
  grestore
  stroke
} bdef

/TheP
{
  2 copy
  newpath
  moveto
  0.4 0 rlineto
  0.5 0.5 rlineto
  0.8 0 rlineto
  1.3 1.3 rlineto
  -1.2 0 rlineto
  closepath
  gsave
    0.8 setgray
    fill
  grestore
  stroke
  newpath
  moveto
  1.3 .9 rmoveto
  .4 0 rlineto
  .5 .5 rlineto
  -.4 0 rlineto
  closepath
  gsave
    0.6 setgray
    fill
  grestore
  stroke
} bdef

%% Cold Chisel in outline letters.
%% By Russell Sparkes <russell@cerberus.bhpese.oz.au>, 18 dec 92.
(Cold Chisel)
{
  gsave
    0 -0.1 translate
    0.05 setlinewidth
    1.5 setmiterlimit
    /Helvetica-Bold findfont setfont
    0 0.1 moveto
    (COLD CHISEL) true charpath
    gsave
      gsave fill grestore
      0.06 setlinewidth 1 setgray stroke
    grestore 0.015 setlinewidth 0 setgray stroke
  grestore
} bind
6
define-magic-name-printer

%% The Angels with the THE printed vertically upwards before ANGELS
%% horizontally. (As in Beyond Salvation but without the crinkly paper)
%% By Russell Sparkes <russell@cerberus.bhpese.oz.au>, 6 Oct 92.
(The Angels)
{
  gsave
    0 -0.1 translate
    /Helvetica-Narrow-Bold findfont setfont
    0.4 0.1 moveto
    (ANGELS) show
    0.35 0 moveto
    90 rotate
    /Helvetica-Narrow-Bold findfont [ 0.5 0 0 0.5 0 0 ] makefont setfont
    (THE) show
  grestore
} bind
3.5
define-magic-name-printer

%%% Draw "The Godfathers" with a slightly raised raised THE.
%%% By Mike Hoswell <hoswell@sage.cgd.ucar.edu>, 11 mar 93.

(The Godfathers)
{
  gsave
    0 -0.1 translate
    1.0 0.5 scale
    /big-font	  /Helvetica findfont [ 0.5 0 0 2.2 0 0 ] makefont  def
    big-font setfont
    0 -0.05 moveto	 (GODFA) show
    0.07 0.15 rmoveto	 (THE)	 show
    0.07 -0.15 rmoveto (RS)	 show
  grestore
} bind
4
define-magic-name-printer

%%% Draw "Iron Maiden" in their font.
%%% By Rob Prikanowski <rpr@oce.nl>
(Iron Maiden)
{
  gsave
    0 0.6 translate
    0.01 -0.01 scale

    gsave      % I
      11 47 moveto 23 47 lineto 23 3 lineto 11 3 lineto closepath stroke
    grestore
    gsave      % R
      26 47 moveto 39 47 lineto 39 39 lineto 54 60 lineto 63 51 lineto
      51 35 lineto 59 23 lineto 43 3 lineto 38 9 lineto 38 3 lineto
      26 3 lineto closepath
      37 26 moveto 47 26 lineto 42 20 lineto closepath stroke
    grestore
    gsave      % O
      64 47 moveto 92 47 lineto 99 35 lineto 77 3 lineto 55 35 lineto
      closepath
      67 36 moveto 87 36 lineto 77 22 lineto closepath stroke
    grestore
    gsave      % N
      100 47 moveto 113 47 lineto 113 25 lineto 120 34 lineto 120 49 lineto
      132 61 lineto 132 3 lineto 120 3 lineto 120 16 lineto 109 3 lineto
      92 3 lineto 100 12 lineto closepath stroke
    grestore
    gsave      % M
      146 47 moveto 159 47 lineto 159 24 lineto 163.5 31 lineto 168 24 lineto
      168 50 lineto 181 63 lineto 181 15 lineto 170 3 lineto 163 12 lineto
      157 3 lineto 139 3 lineto 146 12 lineto closepath stroke
    grestore
    gsave      % A
      181 37 moveto 189 47 lineto 196 39 lineto 203 47 lineto 219 47 lineto
      219 3 lineto 205 3 lineto 196 17 lineto 191 12 lineto 183 21 lineto
      188 27 lineto closepath
      201 27 moveto 208 17 lineto 208 35 lineto closepath stroke
    grestore
    gsave      % I
      211 0 translate
      11 47 moveto 23 47 lineto 23 3 lineto 11 3 lineto closepath stroke
    grestore
    gsave      % D
      236 47 moveto 263 47 lineto 272 33 lineto 252 3 lineto 236 3 lineto
      closepath
      247 36 moveto 260 36 lineto 247 14 lineto closepath stroke
    grestore
    gsave      % E
      279 47 moveto 296 47 lineto 296 35 lineto 284 35 lineto 284 29 lineto
      296 29 lineto 296 18 lineto 284 18 lineto 284 15 lineto 296 15 lineto
      296 3 lineto 272 3 lineto 272 36 lineto closepath stroke
    grestore
    gsave      % N
      205 0 translate
      100 47 moveto 113 47 lineto 113 25 lineto 120 34 lineto 120 49 lineto
      132 61 lineto 132 3 lineto 120 3 lineto 120 16 lineto 109 3 lineto
      92 3 lineto 100 12 lineto closepath stroke
    grestore
  grestore
} bind
3.5
define-magic-name-printer


%% Draw "Heart" as on their "Brigade" album.
%% By lvvo@oce.nl (Robert van Vonderen)
%%
(Heart)
{
  gsave
    0.02 0.02 scale
    0 35 translate
    newpath
    %% "h"
    20 -20 20 105 255 arc
    0 15 rlineto
    10 0 rlineto
    0 -15 rlineto
    20 -20 20 285 75 arc
    0 -15 rlineto
    -10 0 rlineto
    0 15 rlineto
    stroke

    50 -20 moveto

    %% "e"
    20 20 rlineto
    6.66 -6.66 rlineto
    -6.66 -6.66 rlineto
    6.66 -6.66 rlineto
    -6.66 -6.66 rlineto
    6.66 -6.66 rlineto
    -6.66 -6.66 rlineto
    -20 20 rlineto
    stroke

    100 -20 moveto

    %% "a"
    10 20 rlineto
    20 -40 rlineto
    -40 0 rlineto
    10 20 rlineto
    20 0 rlineto
    -10 -20 rlineto
    -10 20 rlineto
    stroke

    140 -20 moveto

    %% "r"
    160 -20 20 180 90 arcn
    10 -5 rlineto
    -10 -5 rlineto
    160 -20 10 90 180 arc
    0 -20 rlineto
    -10 0 rlineto
    0 20 rlineto
    stroke

    180 -20 moveto

    %%"t"
    0 20 rlineto
    40 0 rlineto
    0 -20 rlineto
    -20 20 rlineto
    -20 -20 rlineto
    stroke
    190 -20 moveto
    20 0 rlineto
    0 -20 rlineto
    -20 0 rlineto
    closepath
    stroke
  grestore
} bind
4
define-magic-name-printer


%% draw "Powerplay" as on their "Walk On The Wire" album.
%% By lvvo@oce.nl (Robert van Vonderen)
%%
(Powerplay)
{
  gsave
    /Helvetica-Bold findfont [1.28 0 0 0.32 0 0] makefont  setfont

    (POWERPLAY) dup stringwidth pop
    /ppstw exch def

    0.75 0.75 scale
    0 1 translate
    newpath
    0 -0.17 moveto
    ppstw 0 rlineto		% calculate & draw topline
    0.17 setlinewidth
    stroke
    0 -0.66 moveto
    show		% draw string
    0 -1 moveto
    ppstw 0 rlineto 	% calculate & draw bottomline
    0.17 setlinewidth
    stroke

  grestore
} bind
4
define-magic-name-printer


%% Draw Freur's squiggle
%% By Robert van Vonderen (lvvo@oce.nl)
%%
(Freur)
{
  % spiral-routine taken from the net.
  % sorry, whoever wrote it: I lost your name.
  % Please email-me, and I'll acknowledge credits.
  % slightly changed to have the spiral curl outwards clockwise.
  /spiral
  { translate
    /EndAng exch def /StartAng exch def
    /curl exch def /Tightness exch def  /radius exch def
    gsave
      currentlinewidth 7 div  setlinewidth
      StartAng neg rotate radius 0 moveto
      StartAng Tightness EndAng
      {
	pop 0 0  radius  0  Tightness  neg
	gsave arcn currentpoint grestore lineto
	Tightness neg rotate
	curl dup scale
      } for
      stroke
    grestore
  } def
  % call-parameters:
  % inner most size of the curl
  % finess of of the curl
  % rate of spiral (less than 1 is clockwise)
  % start angle, end angle (length of spiral)
  % position -  x, y

  gsave
    0.07 0.07 scale
    newpath
    2.3 setlinewidth
    % do the spiral
    2 2.5 1.003 180 1055 10 5 spiral
    % do the sawtooth
    5.1 2.5 moveto
    % for-procedure here'll crash the machine... Weird!!!
    2 -4 rlineto 2 4 rlineto
    2 -4 rlineto 2 4 rlineto
    2 -4 rlineto 2 4 rlineto
    2 -4 rlineto 2 4 rlineto
    1 -2 rlineto
    % back to ye old linewidth
    1 setlinewidth
    %% do the fish-hook
    2 0 rlineto
    27 0.5 2 180 270 arcn
    -3.1 5.2 rmoveto
    27 0.5 4 135 45 arcn
    -5.3 -5.3 rmoveto
    27 0.5 4 225 315 arc
    stroke
  grestore
} bind
4
define-magic-name-printer


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%								%%%%%%%%
%%%%%%%			The Magic-Icon Printers.		%%%%%%%%
%%%%%%%								%%%%%%%%
%%%%%%%	   These routines will be automatically invoked to	%%%%%%%%
%%%%%%%	   draw icons for tapes of certain band, again for	%%%%%%%%
%%%%%%%	   added whizziness.  Add more!				%%%%%%%%
%%%%%%%								%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

magic-icon-dict (Love and Rockets) cvn { L&R } CIput

/L&R	% Love and Rockets logo.
{
  gsave
   0.005 setlinewidth
   gsave
     newpath 0.5 0 moveto 0 0 0.5 0 360 arc clip newpath
     -0.5 -0.5 1 -1 box fill
     1 setgray
     -0.1875 -0.5 0.375 -1 box fill
   grestore
   newpath 0.5 0 moveto 0 0 0.5 0 360 arc stroke
   L&R-rocket
   L&R-heart
  grestore
} bdef

/L&R-rocket
{
  -0.0625 0.3125 0.125 0.625 box fill	% shaft
  -0.0625 0.3125 moveto 0.125 0 rlineto % head
   0 0.5 lineto closepath fill
  -0.0625 -0.2 moveto -0.03 -0.03 rlineto % lfin
   0 -0.25 rlineto 0 -0.3125 lineto fill
   0.0625 -0.2 moveto 0.03 -0.03 rlineto  % rfin
   0 -0.25 rlineto 0 -0.3125 lineto fill
} bdef

/L&R-heart-path
{
  newpath
  0 0.125 moveto
  -0.0625 0.125 0.0625 0 180 arc
  0 -0.125 lineto
  0.125 0.125 lineto
   0.0625 0.125 0.0625 0 180 arc
  closepath
} bdef

/L&R-heart
{
  0.5 setgray L&R-heart-path fill
  0 setgray L&R-heart-path stroke
} bdef


magic-icon-dict (Bauhaus) cvn { BEGA } CIput

/BEGA	% Beggars Banquet logo.
{
  gsave
   0.005 setlinewidth
   newpath 0.5 0 moveto 0 0 0.5 0 360 arc stroke
   newpath 0.5 0 moveto 0 0 0.5 0 360 arc clip newpath
   0	 0.3333 moveto 0.25 0 rlineto 0 -0.25 rlineto stroke  % eye
   0.083 0.3333 0.1666 0.1666 box fill
   0.3125 0.5 0.02 0.5 box fill				% nose v
   0.2125 0 moveto 0.3125 0 lineto stroke		% nose h
   0.2725 0 0.04 0.3 box fill				% mouth v
   0.2125 -0.125 0.1 0.03 box fill			% mouth h
   0.125 -0.3 0.155 0.25 box fill			% chin v
   0.0625 -0.3 moveto 0.28 -0.3 lineto stroke		% chin h
  grestore
} bdef

magic-icon-dict (Nitzer Ebb) cvn { NE-dispatch } CIput

/NE-dispatch	% draw one of three nitzer ebb logos, depending on albumname.
{
  albumname1 (That Total Age) eq
  { NE3 }
  { albumname1 (Belief) eq
    { NE-belief }
    { NE-star-and-gear }
    ifelse
  }
  ifelse
} bdef

/NE3		% Nitzer Ebb "That Total Age" logo.
{
  gsave
    -0.175 0.5 0.35 1 box fill
    0.5 setgray
    /s 0.3 def
    gsave 0 -0.3333 translate s s scale
     NE-hammer grestore
    gsave s s scale
     starpath fill grestore
    gsave 0 0.3333 translate s s scale
     NE-gear grestore
  grestore
} bdef

/NE-gear
{
  gsave
    0.1 setlinewidth
    0 0 0.375 0 360 arc stroke
    0 1 8
     { -0.075 0.5 0.15 0.1 box fill
       45 rotate
     } for
  grestore
} bdef

/NE-hammer
{
  gsave
    0.05 0 translate
    45 rotate
    -0.1 0.4 0.2 0.85 box fill
    -0.3 0.4 0.45 0.2 box fill
     0.15 0.4 moveto
     0.35 0.2 lineto
     0.15 0.2 lineto
     closepath fill
  grestore
} bdef

/starpath
{
  newpath 0 0.5 moveto
  0 1 4 { pop 144 rotate 0 0.5 lineto } for
  closepath
} bdef


/NE-star-and-gear	% Nitzer Ebb "Warsaw Ghetto" logo.
{
  gsave
   0.8 0.8 scale
   NE-split-gear
  grestore
  NE-split-star
} bdef

/NE-split-star
{
  gsave
    0.02 setlinewidth
    0 setgray starpath stroke
    starpath clip newpath
    0 setgray 0 0.5 0.5 1 box fill
    1 setgray -0.5 0.5 0.5 1 box fill
  grestore
} bdef

/NE-gear-path
{
    0 0.5 moveto
    0 1 11
      { pop
	-0.075 0.5 lineto
	-0.075 0.45 lineto
	30 rotate
	 0.075 0.45 lineto % ## make this a curveto!!
	 0.075 0.45 lineto
	 0.075 0.5 lineto
      } for
    closepath
} bdef


/NE-split-gear
{
  gsave
    % I tried doing this with eopath, but it doesn't work in Amiga Post 1.1.
    0.005 setlinewidth
    0 setgray
    NE-gear-path stroke
    NE-gear-path clip newpath
    -0.5 0.5 0.5 1 box fill
    1 setgray 0.4 0 moveto 0 0 0.4 0 360 arc fill
    0 setgray 0.4 0 moveto 0 0 0.4 0 360 arc stroke
  grestore
} bdef

%% What follows is a bitmap of the "grainy eye" image from "Belief".
%% Digitized on an Amiga, converted to PS with Jef Poskanzer's PBM toolkit.
%% I would have stored the bitmap run-length encoded, but that would have
%% taken some work, as the only rle-decoders I have expect to draw the image
%% as they decode, and not store it away for future use as we do here.
%%
/NE-belief
{
  gsave
  0.8 0.8 scale
  -0.5 -0.5 translate
  82 71 1
  [ 82 0 0 -71 0 71 ]
  %% 28 lines of bitmap data... pinhead representation (tm).
  {<000000000000000000003f000000000000000000003f000000000000000000003f00000000
   0000000000003f000000000000000000003f03ffffffffffeffff0003f03ffffffdf3fffffb
   0003f03fffff800002ff661003f03ffffe00000060ffb003f03ffff8000000001fc003f007f
   fc00000000067c003f007fe000000000001d803f001f00000000000008203f0000000000000
   00006003f000000000000000004003f0000000000001e0000003f0000000000003f8000003f
   0000000000007d0000003f000000000000390000003f000000000000000000003f000000000
   000000000003f000000000000000000003f000000000000000000003f000000002000000000
   003f0000000ff000000000003f0000001fe006000000003f0000003f8046000000003f02000
   07fc1c6000000003f0200007fb780000000403f0300007fc70800000f803f0300003ff03040
   0008883f030001ffffff800018003f0380004ffffe0001f8003f03800007fffc0003fc003f0
   380001780000053f4003f03800001c8000197f7003f03800001f80001fffe003f03800046c0
   0037ffbf003f03800007f801ffffff803f0380000ffffffffff0003f03800003fffffffffe0
   03f03800002fffffffffe003f03c00000fffffffff8003f03c00000fffffffff8003f03c000
   01fffffffff0003f03c000007ffffffff0003f03c000001ffffffff0003f03c000007ffffff
   fe0003f03c00000ffffffffe0003f03e000007fffffffe0003f03e000003fffffff40003f03
   e000001fffffff80003f03e000001ffffffd80003f03f0000003fffffe00003f03f0000001f
   ffffc00003f03f0000001fffffc00003f03f0000000fffffc00003f03f00000017ffff80000
   3f03f0000001fffffc00003f03f0000000fffff800003f03e0000000fffff800003f03e0000
   0003ffff000003f03e000000017fff000003f0300000000179fe000003f02000000001f0ae0
   00003f000000000001000000003f0000000000007f0000003f000000000000000000003f000
   000000000000000003f000000000000000000003f000000000000000000003f000000000000
   000000000000000000000000000000000000000000000000000000000000000000000000000
   000000000000000000000000000000000000000000000000000000000000000000000000000
   000000000000000000000000000000000000000000000000000000000000000000000000000
   000000000000000000000000000000000000000000000000000000000000000000000000000
   000000000000000000000000000000000000000000000000000000000000000000000000000
   000000000000000000000000000000000000000000000000000000000000000000000000000
   000000000000000000000000>}
  image
  grestore
} bdef

magic-icon-dict (Nine Inch Nails) cvn { NiNbox } CIput

/NiNbox
{
   gsave
    0.7 0.7 scale
    /Helvetica-Bold findfont [ 1 0 0 1 0 0] makefont
    /Helvetica-Bold findfont [-1 0 0 1 0 0] makefont
    dup setfont
    (NIN)stringwidth pop 2 div -0.3 translate
    0 0 moveto
    /Nw (N)stringwidth pop neg def
    Nw 0 rmoveto (N)show Nw 0 rmoveto
    exch dup setfont (IN)show exch
    0.1 setlinewidth
    -0.1 -0.15 Nw (IN)stringwidth pop add 0.2 add -1.05 box stroke
    pop pop
    grestore
} bdef

%% Kate Bush logo by Christer Lindh <clindh@abalon.se>.
%% This draws the old-style KB logo. If it goes on the outside
%% but songs go inside, it is rotates 90 degrees.
%%
/KB
{
  gsave
    .87 .87 scale
%    songs-go-inside icons-go-inside not and
%    { -0.5 0.54 translate -90 rotate }
%    { -0.5 -0.5 translate }
%    ifelse
    -0.5 -0.5 translate
    0.5 0.5 0.5 0 360 arc fill stroke
    1 setgray
    0.3 setlinewidth
    0.14 0.68 moveto
    0.14 0 lineto stroke

    0.08 setlinewidth
    0 0.80 moveto
    1 0.80 lineto
    0.45 0.80 moveto
    0.45 0 lineto stroke

    0.06 setlinewidth
    0.45 0.45 moveto
    1 0.875 lineto
    0.60 0.55 moveto
    0.9 0.1 lineto stroke
  grestore
} bdef
magic-icon-dict (Kate Bush) cvn { KB } CIput


%% Draw "ZZ Top" as on their "Recycler"
%% By Stefan B Karlsson <sk177@lu.erisoft.se>
%%
/ZZTop
{
  gsave
    0.1 0.1 scale
    -3.5 -6.5 translate
    20 rotate
    0.04 setlinewidth
    5.5 5 4.5 0 360 arc
    gsave
      0.6 setgray
      fill
    grestore
    stroke
    5.5 5 3.5 0 360 arc
    gsave
      1 setgray
      fill
    grestore
    stroke
    0.5 4 TheZ
    1 2.9 TheZ
    4.8 5.1 TheT
    6.3 5.1 TheO
    7.6 5.1 TheP
  grestore
} bdef

magic-icon-dict (ZZ Top) cvn { ZZTop } CIput

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%EndProlog
END_OF_PROLOG
}

1;
