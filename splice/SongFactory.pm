package Splice::SongFactory;

use strict;
use warnings;

use Splice::Parameters;
use Splice::Song;

our $instance = undef;

sub _new {
    my $that   = shift;
    my $class  = ref($that) || $that;
    my $self   = {};

    bless( $self, $class );

    # each of the aliases will be saved
    # in the main hashtable that makes up the
    # class instance variables

    $self->_readAliasFile();
    $self;
}

sub getInstance		# singleton method
{
    $instance = _new Splice::SongFactory() if ! defined $instance;
    return $instance;
}

sub _readAliasFile	# reads in the alias file
{					# the aliases are stored in the main hashtable for this class

	my $self      = shift;
    my $aliasFile = Splice::Parameters::getInstance()->getAliasFile();

    return if (! $aliasFile || ! -e $aliasFile);

    open(my $ALIAS,'<',$aliasFile) or return;
    while (<$ALIAS>)
    {
    	chomp;
    	s/#.*//;
    	s/^\s+//;
    	s/\s+$//;
    	next unless length;

    	my($var,$value) = split(/\s*=\s*/,$_,2);
    	$self->{$var}   = $value;
    }
    close $ALIAS;
}

sub clean
{
	my $self	= shift;
	local $_	= shift;				# song text, save in $_ for ease of use

	return '' if ! defined $_;

    s/^\s+//;
    s/\s+$//;
    s/  */ /g;
    s/^{//;
	s! ?&slash; ?!/!g;   # replace &slash; with a real slash
	s! ?&gt; ?!> !g;     # replace &gt; with the real greater than symbol

	return $_;
}

sub createSong {					# returns a standard song
	my $self      = shift;
	my $textIn    = shift;
	my $separator = shift || '/';

	$textIn = $self->clean( $textIn );

	# create the song and specify its attributes

	my $song = new Splice::Song();
	$song->setEndOfSide(1) if ($separator eq '|'    );
	$song->setItalics(1)   if ($separator eq '}'    );
	$song->setMedley(1)    if ($separator =~ /-?>$/ );

	# look for the alias if one exists
	# if one does not exist, $text will be empty
	# in that case, just use the text passed in
	my $text = $self->{$textIn};

	$song->setText( $text ? $text : $textIn );

	return $song;
}

sub createItalicsSong {   # returns an italicized song
	my $self = shift;
	my $text = shift;

	return new Splice::Song( $self->clean($text), 1 );
}

sub createEmptySong	 {  # returns an empty song
	my $self = shift;
	return new Splice::Song();
}

1;

__END__

=head1 AUTHOR INFORMATION

Copyright 2000-, Steven Scholnick <scholnicks@gmail.com>

splice is published under MIT.  See license.html for details

