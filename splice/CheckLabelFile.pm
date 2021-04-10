package Splice::CheckLabelFile;

use strict;
use warnings;

use Carp;

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw( checkSpliceOutput );

# checkSpliceOutput
#   checks the splice output for matching number #   or parens etc.
#
#   the error message can be formatted as HTML (if arg #   2 is true)
sub checkSpliceOutput {
    my $labelText = shift;
    my $useHTML   = shift || 0;

	my @text     = split('\n',$labelText);

	my $lcnt       = 0;
	my $start      = 0;
	my $sides      = 0;
	my $val        = "";
	my $c          = "";
	my @parens     = ();
	my @bracks     = ();
	my @temp       = ();
	my $sidesCheck = 0;

	for (my $i=0; $i < $#text; $i++) {
	  $_ = $text[$i];

	  $lcnt++;

	  next if /^$/;
	  next if /font/;
	  next if /sizes/;
	  next if /DAT/;
	  next if /^Dolby/;	    # skip by all this stuff
	  next if /print/;

	  /^( |\()/ && /\) *\(\)$/  && ($start = 1, next);  # a title line

	  if (/^double-|^two-|additional-info-[1-2]/) { # end of a label
	     $start = 0;
	     if (! $sidesCheck && ! /additional-info-2/ && $sides != 2) { # check for correct number of sides
		    return "\n\nsplice : Too many (or too few) sides at line $lcnt\n";
	     }

	     if (@parens != 0 || @bracks != 0)  { # do a final check of the stacks
	        return "Missing Delimiter<br />" if $useHTML;
	        return "\n\nsplice : Missing symbol before line $lcnt\n";
	     }

	     $sides      = 0;
	     $sidesCheck = 1;
	     @parens     = ();
	     @bracks     = ();
	  }

	  if ($start) {
	     for (my $j=0; $j <= length($_); $j++) {
			$c = substr($_, $j,1);

			$sides++ if( $j == 0 && $c eq "]");

			push(@parens,$c) if ($c eq '(');   # opening parens
			push(@bracks,$c) if ($c eq '[');   # opening bracket

	        if ($c eq ')') {
			    $val = pop(@parens);		       # check it
			    if ($val ne '(') {
        	       return "Missing parenthesis<br />" if $useHTML;
			       return "\n\nsplice : Missing paren at line $lcnt\n";
			    }
			}
			elsif ($c eq ']') {
			    $val = pop(@bracks);

			    if ($val ne '[') {
      	           return "Missing bracket<br />" if $useHTML;
			       return "\n\nMsplice : issing bracket at line $lcnt\n";
			    }
			}

	     }

	  }

	}

	undef;  			# return a good status
}

1;

__END__

=head1 AUTHOR INFORMATION

Copyright 2000-, Steven Scholnick <scholnicks@gmail.com>

splice is published under MIT.  See license.txt for details
