package Splice::Utilities;

use strict;
use warnings;

require Exporter;

use Cwd 'abs_path';

use Digest::MD5;

use base qw(Exporter);

our @EXPORT = qw(stripFile trim getPath getSeparator getResourceFilePath
                 printFile normalizeText getFileAsArray dieMessage warnMessage
                 createDirectory absolutePath expandPath
			  );

#	returns the RC file path
sub getResourceFilePath
{
	my $unixStyle  = shift;						# unix rc file naming, eg .splicerc
	my $otherStyle = shift; 					# win rc file, eg splice.rc
	my $homeDir    = shift || $ENV{"HOME"};		# home directory

  	# first try unix style
  	my $initPath = getPath($homeDir,$unixStyle);

  	# if not there, try others style
  	$initPath = getPath($homeDir,$otherStyle) if (! -e $initPath);

 	if (-e $initPath)
  	{
  		return $initPath;
    }
    else
    {
     	return undef;
    }
}

#  stripFile
#   strips the splice input file of unwanted characters
sub stripFile
{
   my $file = shift;
   my $temp = "$file.$$";

   open(my $INP,'>',$file) or die "stripFile : Cannot open input file $file\n";
   open(my $OUT,'>',$temp) or die "stripFile : Cannot open temp file\n";

   while (<$INP>)
   {
      chomp;

      tr/\015//d;		# eliminate ^M

      s#/ #/#g;			# elim space after /
      s/\| /\|/g;		# elim space after |
      s/> />/g;			# elim space after >

      s/ *$//;			# elim trailing spaces

      tr/\(/\[/;		# convert ( -> [
      tr/\)/\]/;		# convert ) -> ]

      print $OUT "$_\n";
   }

   close($OUT);
   close($INP);

   rename($temp,$file);		# put the transformation back on the original

}

sub normalizeText			# removes all the "bad" stuff from the text
{
   	my $text      = shift;
    my $lowerCase = shift;

    $lowerCase = 1 if (! defined $lowerCase);

    $text = trim($text);
    $text =~ tr/[., $'"!#&+%<>()\-\/\\]//d;
    $text =~ tr/-//d;

    $text = lc( $text ) if $lowerCase;

    $text;
}

sub getFileAsArray			# returns a whole file as an array text lines
{
	my $file = shift;

	my @lines;

	open(my $IN,"<",$file) || return @lines;
	while (<$IN>)
	{
		chomp;
		next if /^$/;
		push(@lines,$_);
	}
	close $	IN;

	@lines;
}

sub trim  # trims whitespace
{
    local $_ = shift;

	return '' if( ! defined $_ );

    s/^\s+//;
    s/\s+$//;
    $_;
}

sub printFile    # prints a file verbatim to the specified file handle
{
   my $file = shift || return;
   my $FH   = shift || return;

   open(my $INP,"<",$file) || return;
   print $FH $_ while (<$INP>);
   close $INP;
}

sub getPath   # returns a full path
{
   my $dir      = shift;
   my $filename = shift;

   if( $filename =~ m!^/! )     # check for a fully-qualified path
   {
       return $filename;
   }

   return "$dir/$filename";
}

sub absolutePath				# returns the complete absolute path
{
	my $path = shift;

	return $path if ($path =~ m!^/!);

	return abs_path($path);
}

sub expandPath
{
	my $path = shift;

	return undef if ! $path;
	return $path if $path !~ /^~/;

	my $home = $ENV{"HOME"};

	warnMessage("HOME is not set") if ! $home;

	$path =~ s/~/$home/;

	$path;
}

sub createDirectory				# creates directory if one does not exists
{
	my $directory  = shift;
	my $permission = shift;

	if (! -e $directory)
	{
		my $success = system( qq{mkdir "$directory"} );
		return $success if $success != 0;

		chmod($permission,$directory) if $permission;
	}

	return 0;
}

sub cleanArguments
{
	my @args = @_;

	foreach (@args)
	{
		chomp;
		$_ = '' if (! $_);
	}

	return @_;
}

sub warnMessage
{
	print STDERR 'splice : ' . join(' ',cleanArguments(@_)) . "\n";
}

sub dieMessage
{
	print STDERR 'splice : ' . join(' ',cleanArguments(@_)) . "\n";
	exit -1;
}

1;

