# Experimental implementation of the Uratani-Takeda string searching algorithm,
# "A Fast String-Searching Algorithm for Multiple Patterns"
# Information, Processing & Management 29 (6), pp. 775-791, 1993.
# doi:10.1016/0306-4573(93)90106-N.

# SPDX-FileCopyrightText: 2026 Robert Rothenberg <perl@rhizomnic.com>
# SPDX-License-Identifier: Artistic-2.0

use v5.26;
use Object::Pad;

package Algorithm::UrataniTakeda v0.0.3;

class Algorithm::UrataniTakeda {

    field $states = [];
    field $ends   = [];
    field $left   = [];
    field $depth  = [];
    field $phi    = [];
    field $min    = -1;
    field $shift1 = [];
    field $shift2 = [];

    method enter($pattern) {

        use integer;

        my @string = unpack( "U*", $pattern );
        my $i = $#string;

        $min = $i if $min < 0 || $min > $i;

        my $n = 0;

        while ($i >= 0) {

            $states->[$n] //= {};

            if ( exists $states->[$n]{ $string[$i] } ) {
                $n = $states->[$n]{ $string[$i] };
            }
            else {
                $n = $states->[$n]{ $string[$i] } = 1 + $#$states;
                $depth->[$n] = $#string - $i + 1;
            }

            $i--;
        }

        $states->[$n] = {};
        $ends->[$n] = $pattern;
        push $left->@*, $n;
    }

    method build_phi {

        use integer;

        my @q = values $states->[0]->%*;
        $phi =  [ (0) x (1 + $#$states) ];

        while (@q) {
            my $r = shift @q;
            for my $c ( keys $states->[$r]->%* ) {
                push @q, my $s = $states->[$r]{$c};
                my $z = $phi->[$r];
                $phi->[$s] = $states->[$z]{$c} // 0;
            }
        }
    }

    method build_shift1 {

        use integer;

        $shift1 = [ map { {} } 0.. $#$states ];

        my @q = grep { $_ > 0 } values $states->[0]->%*;

        while (@q) {
            my $r = shift @q;

            for my $c ( keys $states->[$r]->%* ) {
                push @q, my $s = $states->[$r]{$c};
                my $z = $phi->[$r];

                while ( !exists $states->[$z]{$c}) {

                    my $a = $shift1->[$z]{$c};
                    my $b = $depth->[$r];
                    $shift1->[$z]{$c} = $b unless $a && $a < $b;

                    $z = $phi->[$z] or last;
                }

                if ( ! exists $states->[$z]{$c} ) {

                    my $a = $shift1->[$z]{$c};
                    my $b = $depth->[$r];
                    $shift1->[$z]{$c} = $b unless $a && $a < $b;
                }
            }
        }

    }

    method build_shift2 {

        use integer;

        foreach my $end ( $left->@* ) {

            my $z = $phi->[$end];
            while ( $z > 0 ) {

                my $a = $shift2->[$z];
                my $b = $depth->[$end];
                $shift2->[$z] = $b unless $a && $a < $b;

                $z = $phi->[$z];
            }
            $shift2->[0] = $min;
            my @q = (0);

            while (@q) {
                my $r = shift @q;
                for my $c ( keys $states->[$r]->%* ) {
                    push @q, my $s = $states->[$r]{$c};

                    my $a = $shift2->[$s];
                    my $b = $shift2->[$r] + 1;
                    $shift2->[$s] = $b unless $a && $a < $b;
                }
            }

        }

    }

    method search( $text, $callback ) {

        use integer;

        my @string = unpack( "U*", $text );
        my $n      = $#string;

        my $q = $min;

      TEXT: while ( $q <= $n ) {

            my $z = 0;
            while ( $states->[$z]{ $string[$q] } ) {
                $z = $states->[$z]{ $string[$q] };
                if ( $ends->[$z] ) {
                    $callback->( $q, $ends->[$z] ) or last TEXT;
                }
                $q--;
            }

            # calculate minimum failure shift
            my $a = $shift1->[$z]{ $string[$q] };
            my $b = $shift2->[$z];
            $b = $a if $a && $a < $b;

            $q += $b;

            last if $q > $n;

        }

    }

    method matches( $text ) {

        my @matches;

        $self->search( $text, sub( $, $phrase ) { push @matches, $phrase; return 1; } );

        return @matches;
    }


    ADJUST :params ( :$patterns ) {

        $self->enter($_) for $patterns->@*;

        $self->build_phi;
        $self->build_shift1;
        $self->build_shift2;

    }

}
