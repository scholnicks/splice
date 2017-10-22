package Splice::ITunesEngine;

use strict;
use warnings;

use Cwd;
use Carp;

use Splice::Label;
use Splice::LabelFactory;
use Splice::Parameters;
use Splice::Utilities;
use Splice::SongFactory;

use base qw(Splice::Engine);

sub new {
    my $package = shift;
    my %prefs   = @_;

    my $obj = bless( {}, $package );

    $obj->checkForModules();

    $obj->initialize(%prefs);

    $obj;
}

sub checkForModules {
	my $self = shift;

	foreach my $module ('Mac::iTunes::Library::XML', 'Mac::iTunes::Library::Item', 'Mac::iTunes::Library::Playlist') {
		eval "use $module";
		croak "$module must be installed to process an iTunes library\n" if $@;
	}
}

sub readFile {
    my $self  = shift;

	my $isMix = Splice::Parameters::getInstance()->isUseTimes();

    my $factory = new Splice::LabelFactory( Splice::Parameters::getInstance()->getType() );

    my $playlist = $self->getPlayList();

    croak "No songs found in " . $playlist->name() . "\n" if (scalar($playlist->items()) == 0);

    my $label = $factory->createEmptyLabel();

    if ($isMix) {
		$label->setArtist( $playlist->name() );
		$label->setVenue( "" );
    }
    else {
    	my $firstTrack = ($playlist->items())[0];
		$label->setArtist( $firstTrack->artist() );
		$label->setVenue( $playlist->name() );
    }

    $label->setNumberOfLabels(1);
    $label->loadNumberOfLabels();

    my $songFactory = Splice::SongFactory::getInstance();

	my $filler = Splice::Parameters::getInstance()->isFillerTitle();
    my $album = $playlist->name();

    $filler = 0 if $isMix;     # turn off filler for mix discs

    foreach my $iTunesSong ($playlist->items()) {
    	if ($filler && $album ne $iTunesSong->album()) {
    		$album = $iTunesSong->album();
    		$label->addSong( $songFactory->createEmptySong() );

    		my $fillerTitle = ($label->getArtist() ne $iTunesSong->artist()) ? $iTunesSong->artist() . ' - ' . $album : $album;
    		$fillerTitle =~ s/\s*-\s*EP//;
    		$label->addSong( $songFactory->createItalicsSong($fillerTitle) );

    		$label->addSong( $songFactory->createEmptySong() );
    	}

    	my $songTitle = $iTunesSong->name();
    	$songTitle =~ s/(\(|\[)Live(\)|\])//i;
    	my $song = $songFactory->createSong($songTitle);
    	$song->setTimeLength( $songFactory->clean($iTunesSong->artist()) ) if $isMix;

    	$label->addSong( $song );
    }

    push(@{$self->{labels}}, $label);
}

sub getPlayList {
	my $self = shift;

	my $playlistName = Splice::Parameters::getInstance()->getItunesPlaylist();
	my $library      = $self->getItunesLibrary();
	my %playlists    = $library->playlists();

	my $foundId;

	PLAYLISTS:
	foreach my $id ( keys %playlists ) {
		if ($playlists{$id}->name() && $playlistName eq $playlists{$id}->name()) {
			$foundId = $id;
			last PLAYLISTS;
		}
	}

	croak "Cannot find iTunes playlist with name $playlistName\n" if ! $foundId;

	$playlists{$foundId};
}

sub getItunesLibrary
{
	my $self = shift;
	my $path = $self->getITunesXMLPath();

	return Mac::iTunes::Library::XML->parse($path);
}

sub getITunesXMLPath
{
	my $self = shift;

	# MacOSX
	return "$ENV{HOME}/Music/iTunes/iTunes Music Library.xml";
}

1;

__END__

=head1 AUTHOR INFORMATION

Copyright 2000-, Steven Scholnick <scholnicks@gmail.com>

splice is published under MIT.  See license.html for details
