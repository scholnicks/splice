package Splice::WebUtilities;

use strict;
use warnings;
use CGI qw(:standard);
use Digest::MD5;

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT = qw(missingInputHTML getBadInputHTML showRequiredFieldPage
			 		showInvalidCharPage getHTMLPageFooter
			 		getHTMLPageHeader showMissingInputPage
			 		getTimeStamp sendMail calculateMD5forFile
			   );

our $VERSION  = '1.00';

sub sendMail
{
   my ($rec,$from,$subject,$text) = @_;

   open(MAIL,"|/usr/sbin/sendmail -t") || return;
   print MAIL "To: $rec\n";
   print MAIL "From: $from\n";
   print MAIL "Subject: $subject\n";
   print MAIL "\n\n";
   print MAIL "$text\n";
   close MAIL;
}

# calculates the MD5 checksum for a file
# this can be used to check to see if a file has changed
sub calculateMD5forFile
{
    my $file = shift  or return "";
    open(FILE, $file) or return "";
    binmode(FILE);

    my $result = new Digest::MD5->addfile(*FILE)->hexdigest();

    close FILE;

    $result;
}

sub getHTMLPageHeader
{
    my $title = shift;
    my $s = header();
    $s   .= "<html>\n";
    $s   .= "<head>\n";
    $s   .= "   <title>$title</title>\n";
    $s   .= "</head>\n";
    $s   .= qq(<body bgcolor="white">\n);

    $s;
}

sub getHTMLPageFooter
{
    my $s = "";             # add address block here
    $s   .= "</body>\n</html>\n";
    $s;
}

sub showInvalidCharPage
{
    print getHTMLPageHeader("Invalid Email Address");
    print "<h1>Your email address had one or more invalids characters.</h1>\n";
    print "Please re-enter it.<br>\n";
    print qq(<form><input type="button" name="Back" Value="Go Back and Edit Label" );
    print qq(onClick="history.back()"></form>);
    print getHTMLPageFooter();
}

sub showRequiredFieldPage
{
    print getHTMLPageHeader("Submission Email Address Error");
    print "<h1>You have not filled in the Email Address field.</h1>\n";
    print "This is required to make files for label generation.<br>\n";
    print qq(<form><input type="button" name="Back" Value="Go Back and Edit Label" );
    print qq(onClick="history.back()"></form>);
    print getHTMLPageFooter();
}

sub getBadInputHTML
{
   my $errorText=<<'EOE';
<p>a Bad Side Break or SetList Info.</p>
<p><b>Common Causes of this Error:</b></p>
<ol>
<li>You entered nothing (or only a few words) for a set list.</li>
<li>You forgot a side break delimiter ( | ).</li>
<li>You used a | delimiter at the end of a set list when it is not needed.</li>
<li>You forgot the underscore ( _ ) character to separate the set list from the tape info.</li>
<li>You used a dash ( - ) instead of an underscore ( _ ) to separate the set list info.</li>
<li>The number of tapes does not work out correctly!</li>
</ol>
EOE
   $errorText;
}

sub showMissingInputPage
{
    print getHTMLPageHeader("Missing Input");
    print missingInputHTML();
    print getHTMLPageFooter();
}

sub missingInputHTML
{
   my $errorText=<<'EOE';
<p>a Missing Input File.</p>
<p><b>Common Causes of this Error:</b></p>
<ol>
<li>You did not follow the correct label format.</li>
<li>You forgot to denote the number of tapes in the recording.</li>
<li>You entered blank lines in your input file or set list.</li>
<li>Your email address is too long for the program. This is a problem we are working to correct.
Please try entering just your userid without the @... part and see if this corrects the problem.</li>
</ol>
<p>
If you still have problems, send us a
<a href="https://scholnick.net/splice/bugreport">bug report</a>.
</p>

EOE
   $errorText;
}

sub getTimeStamp
{
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime(time);

	# create the time stamp
	my $date = join("_",$mon+1,$mday,$year+1900);
	my $time = join(":",$hour,$min,$sec);
	my $stamp = $date . "_" . $time;

	$stamp;
}

1;

__END__

=head1 AUTHOR INFORMATION

Copyright 2000-, Steven Scholnick <scholnicks@gmail.com>

splice is published under MIT.  See license.html for details
