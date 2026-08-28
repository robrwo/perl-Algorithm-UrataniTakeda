#!perl

use v5.26;

use Test2::V0 -no_srand => 1;;

use Algorithm::UrataniTakeda;

use experimental qw( signatures );

my @patterns = qw( trace artist smart great test );

my @output;

my $m = Algorithm::UrataniTakeda->new( patterns => \@patterns );

$m->search(
    "the-greatest-artist-has-the-smartest-traces",
    sub( $pos, $phrase ) {
        push @output, [ $pos, $phrase ];
    }
);

is \@output, [

    [ 4,  "great" ],
    [ 8,  "test" ],
    [ 13, "artist" ],
    [ 28, "smart" ],
    [ 32, "test" ],
    [ 37, "trace" ]

  ],
  "expected output";

done_testing;
