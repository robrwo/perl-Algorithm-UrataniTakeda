# SPDX-FileCopyrightText: 2026 Robert Rothenberg <perl@rhizomnic.com>
# SPDX-License-Identifier: Artistic-2.0

use v5.26;
use Object::Pad;

# ABSTRACT: an implementation of the Uratani-Takeda string searching algorithm

package Algorithm::UrataniTakeda;

our $VERSION = 'v0.1.1'; # Dist::Zilla cannot handle versions on the package line.

=head1 SYNOPSIS

    my $m = Algorithm::UrataniTakeda->new( patterns => \@patterns );

    my $match = $m->first($text);

    my @all = $m->matches($text);

    sub callback( $pos, $phrase ) {
        ...
        return 1;
    }

    while (<STDIN>) {
        $m->search( $_, \&callback );
    }

=head1 STATUS

This is an experimental implementation.
It may not be correct.

=head1 DESCRIPTION

This is an implementation of the Uratani-Takeda algorithm for searching for multiple strings.

It combines the Aho-Corasick algorithm with the Boyer-Moore algorithm, and is similar to the Commentz-Walter algorithm.

=cut

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

=method search

    sub callback( $pos, $phrase ) {
        ...
    }

    $m->search( $text, \&callback );

This searches the text and calls the callback function for every match.

If the callback returns a false value, it stops looking for additional matches.

=cut

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

=method matches

    my @matches = $m->matches( $text );

This returns an array of all matches.

If there are no matches, then it will return an empty array.

=cut

    method matches( $text ) {

        my @matches;

        $self->search( $text, sub( $, $phrase ) { push @matches, $phrase; return 1; } );

        return @matches;
    }

=method first

    my $match = $m->first( $text );

This returns the first match, or C<undef> if there are none.

=cut

    method first( $text ) {

        my $match;

        $self->search( $text, sub( $, $phrase ) { $match = $phrase; return 0; } );

        return $match;
    }


    ADJUST :params ( :$patterns ) {

        $self->enter($_) for $patterns->@*;

        $self->build_phi;
        $self->build_shift1;
        $self->build_shift2;

    }

}

=head1 SEE ALSO

This implementation was based on "A Fast String-Searching Algorithm for Multiple Patterns", B<Information, Processing & Management 29 (6)>, pp. 775-791, 1993.
L<doi:10.1016/0306-4573(93)90106-N>.

=head1 prepend:SUPPORT

Only the latest release of this module will be supported.

This module requires Perl v5.26 or later.

=head2 Reporting Bugs and Submitting Feature Requests

=head1 append:SUPPORT

If the bug you are reporting has security implications which make it inappropriate to send to a public issue tracker,
then see F<SECURITY.md> for instructions how to report security vulnerabilities.

=begin :prelude

=for Pod::Coverage DOES META new

=for Pod::Coverage build_phi build_shift1 build_shift2 enter

=for stopwords Aho Commentz Corasick Takeda Uratani

=end :prelude

=cut
