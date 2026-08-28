#!perl

use v5.26;

use Test2::V0 -no_srand => 1;

use Algorithm::UrataniTakeda;

use experimental qw( signatures );

my @patterns = qw( hers heraldry her );

my $m = Algorithm::UrataniTakeda->new( patterns => \@patterns );

subtest 'search all' => sub {

    my @output;

    $m->search(
        "hers is here heraldry",
        sub( $pos, $phrase ) {
            push @output, [ $pos, $phrase ];    # implicitly returns true
        }
    );

    is \@output, [

        [ 0, "her" ],
        [ 0, "hers" ],
        [ 8, "her" ],
        [ 13, "her" ],
        [ 13, "heraldry" ],

      ],
      "expected output";

};

done_testing;
