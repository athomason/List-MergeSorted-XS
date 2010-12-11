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

sub merge {
    my $lists = shift;
    my %opts = @_;

    # make sure input is sane
    unless ($lists && ref $lists && ref $lists eq 'ARRAY') {
        die "merge requires an array reference";
    }
    for my $list (@$lists) {
        unless ($list && ref $list && ref $list eq 'ARRAY') {
            die "lists to sort must be arrayrefs";
        }
    }

    my $limit = $opts{limit} || 0;
    die "limit must be positive" if defined $limit && $limit < 0;

    if (my $keyer = $opts{key}) {
        die "key option must be a callback" unless ref $keyer eq 'CODE';

        # construct a integer-only list-of-lists which will be sorted quickly,
        # then reassociated with values. because the values are kept in a hash,
        # the merged elements are not kept in stable order.

        my %values;
        my @list_of_keys;
        for my $list (@$lists) {
            my @keys;
            for my $el (@$list) {
                my $key = $keyer->($el);
                next unless defined $key;
                push @keys, $key;
                push @{ $values{$key} }, $el;
            }
            push @list_of_keys, \@keys;
        }
        my $sorted_keys = _merge_lists_of_numbers(\@list_of_keys, $limit);
        my @results;
        for my $key (@$sorted_keys) {
            push @results, pop @{ $values{$key} };
        }
        return \@results;
    }
    else {
        return _merge_lists_of_numbers($lists, $limit);
    }
}

sub _merge_lists_of_numbers {
    # XXX choose implementation based on list size
    my $lists = $_[0];
    if (scalar @$lists == 0) {
        return [];
    }

    if (!$ENV{LMSXS_METHOD}) {
        &_merge_fib;
    }
    elsif ($ENV{LMSXS_METHOD} eq 'linear') {
        &_merge_linear;
    }
    elsif ($ENV{LMSXS_METHOD} eq 'fib') {
        &_merge_fib;
    }
    elsif ($ENV{LMSXS_METHOD} eq 'sort') {
        &_merge_perl_sort;
    }
    else {
        die "unknown sort method $ENV{LMSXS_METHOD} requested\n";
    }
}

# concatenate all lists and sort the whole thing
sub _merge_perl_sort {
    my $lists = shift;
    my $limit = shift;

    my @output = sort {$a <=> $b} map {@$_} @$lists;
    splice @output, $limit if $limit;
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
  $sorted = merge(\@lists, key => sub { $_->[0] });

=head1 DESCRIPTION

This module takes a set of presorted lists and returns the sorted union of
those lists.

=head1 FUNCTIONS

=over 4

=item merge(\@list_of_lists, %opts)

Computes the sorted union of a set of lists. The first parameter must be an
array reference which itself contains a number of array references.

Its behavior may be modified by additional options passed after the list:

=over 4

=item * limit

Specifies a maximum number of items to return. By default all items are
returned.

=item * key

Specifies a callback routine which will be passed an element of an inner list
in @_. The routine must return the integer value by which the element will be
sorted. In effect, the default callback is C<sub {$_[0]}>. This allows more
complicated structures to be sorted.

=back

=back

=head1 EXPORT

None by default, C<merge> at request.

=head1 COMPLEXITY

Different algorithms are chosen depending on the number of lists.

* For two lists, the complexity is O(m)

* For <XXX lists, the complexity is O(m n)

* For >XXX lists, the complexity is O(m log2 n)

=head1 AUTHOR

Adam Thomason, E<lt>athomason@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Say Media Inc <cpan@saymedia.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
