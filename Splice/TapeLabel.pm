package Splice::TapeLabel;

use strict;
use warnings;
use base qw( Splice::Label );

sub new
{
    my $package  = shift;
    my $dataRef  = shift;

    my $obj = bless { 
    	filler => shift || 0
    }, $package;

    $obj->parseData($dataRef) if $dataRef;
    
    return $obj;
}

1;

