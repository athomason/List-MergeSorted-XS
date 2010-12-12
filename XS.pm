package List::MergeSorted::XS;

use 5.008;
use strict;
use warnings;
use Carp;

require Exporter;
use AutoLoader;

our @ISA = qw(Exporter);

our @EXPORT_OK = qw/merge/;
our @EXPORT = qw();

our $VERSION = '1.00';

require XSLoader;
XSLoader::load('List::MergeSorted::XS', $VERSION);

use List::Util 'sum';

our $MERGE_METHOD;
use constant {
    SORT        => 0,
    PRIO_LINEAR => 1,
    PRIO_FIB    => 2,
};

sub merge {
    my $lists = shift;
    my %opts = @_;

    # make sure input is sane
    unless ($lists && ref $lists && ref $lists eq 'ARRAY') {
        die "merge requires an array reference";
    }
    for my $list (@$lists) {
        unless ($list && ref $list && ref $list eq 'ARRAY') {
            die "lists to merge must be arrayrefs";
        }
    }

    my $count = sum(map { scalar @$_ } @$lists);

    my $limit = $opts{limit} || 0;
    die "limit must be positive" if defined $limit && $limit < 0;

    return [] unless @$lists;

    if (my $keyer = $opts{key}) {
        die "key option must be a callback" unless ref $keyer eq 'CODE';

        if (!defined $MERGE_METHOD) {
            # TODO choose best implementation based on number of lists, total
            # elements, and requested limit

            return _merge_fib_keyed($lists, $limit, $keyer);
        }
        elsif ($MERGE_METHOD == PRIO_LINEAR) {
            return _merge_linear_keyed($lists, $limit, $keyer);
        }
        elsif ($MERGE_METHOD == PRIO_FIB) {
            return _merge_fib_keyed($lists, $limit, $keyer);
        }
        elsif ($MERGE_METHOD == SORT) {
            return _merge_sort_keyed($lists, $limit, $keyer);
        }
        else {
            die "unknown sort method $MERGE_METHOD requested\n";
        }
    }
    else {
        if (!defined $MERGE_METHOD) {
            # TODO choose best implementation based on number of lists, total
            # elements, and requested limit

            return _merge_fib_flat($lists, $limit);
        }
        elsif ($MERGE_METHOD == PRIO_LINEAR) {
            return _merge_linear_flat($lists, $limit);
        }
        elsif ($MERGE_METHOD == PRIO_FIB) {
            return _merge_fib_flat($lists, $limit);
        }
        elsif ($MERGE_METHOD == SORT) {
            return _merge_sort_flat($lists, $limit);
        }
        else {
            die "unknown sort method $MERGE_METHOD requested\n";
        }
    }
}

# concatenate all lists and sort the whole thing. works well when no limit is
# given.

sub _merge_sort_flat {
    my $lists = shift;
    my $limit = shift;

    my @output = sort {$a <=> $b} map {@$_} @$lists;
    splice @output, $limit if $limit && @output > $limit;
    return \@output;
}

sub _merge_sort_keyed {
    my ($lists, $limit, $keyer) = @_;

    my @output =
        map  { $_->[1] }
        sort { $a->[0] <=> $b->[0] }
        map  { [$keyer->($_), $_] }
        map  { @$_ }
        @$lists;

    splice @output, $limit if $limit && @output > $limit;
    return \@output;
}

1;
__END__

=head1 NAME

List::MergeSorted::XS - Fast merger of sorted lists

=head1 SYNOPSIS

  use List::MergeSorted::XS 'merge';

  @lists = ([1, 3, 5], [2, 6, 8], [4, 7, 9]);

  # merge plain integer lists
  $sorted = merge(\@lists); # $sorted = [1..9]

  # return only some
  $first = merge(\@lists, limit => 4); # $first = [1..4]

  # merge complicated objects based on accompanying integer keys
  @lists = ([[1, 'x'], [3, {t => 1}]], [[2, bless {}, 'C'], [4, 5]]);
  $sorted = merge(\@lists, key => sub { $_[0][0] });

=head1 DESCRIPTION

This module takes a set of presorted lists and returns the sorted union of
those lists.

=head1 FUNCTIONS

=over 4

=item merge(\@list_of_lists, %opts)

Computes the sorted union of a set of lists. The first parameter must be an
array reference which itself contains a number of array references.

merge's behavior may be modified by additional options passed after the list:

=over 4

=item * limit

Specifies a maximum number of items to return. By default all items are
returned.

=item * key

Specifies a callback routine which will be passed an element of an inner list
in @_. The routine must return the integer value by which the element will be
sorted. In effect, the default callback is C<sub {$_[0]}>. This allows more
complicated structures to be used.

=back

=back

=head1 EXPORT

None by default, C<merge> at request.

=head1 ALGORITHMS

The algorithm used to merge the lists is chosen based on the number of lists
(N), the total number of elements in the lists (M), and the requested limit
(L).

When the limit is on the order of the total element count (L ~ M), perl's
built-in sort is used on the concatenated lists. The time complexity is
O(M log M).

Otherwise, a priority queue is used to track the list heads. For small N, this
is implemented as a linked list kept in sorted order, yielding time complexity
of O(L N). For large L, a Fibonacci heap is used, for a time complexity of
O(L log N).

To force a particular implementation, set the package variable $MERGE_METHOD to
one of these constant:

=over 4

=item * List::MergeSorted::XS::SORT

=item * List::MergeSorted::XS::PRIO_LINEAR

=item * List::MergeSorted::XS::PRIO_FIB

=back

=head1 AUTHOR

Adam Thomason, E<lt>athomason@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Say Media Inc <cpan@saymedia.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
