# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl List-MergeSorted-XS.t'

#########################

use Test::More tests => 5;
use_ok('List::MergeSorted::XS');

#########################

use List::MergeSorted::XS qw/merge/;

my @lists = ([4, 7, 9], [1, 3, 5], [2, 6, 8]);

use Data::Dumper;

my $merged = merge(\@lists);
#print Dumper($merged);
is_deeply($merged, [1..9], 'simple merge'); # $sorted = [1..9]

$merged = merge(\@lists, limit => 4);
#print Dumper($merged);
is_deeply($merged, [1..4], 'limited merge');

@lists = ([[1, 'x'], [3, {t => 1}]], [[2, bless {}, 'C'], [4, 5]]);
$merged = merge(\@lists, key => sub { $_[0][0] });
#print Dumper($merged);
is_deeply($merged, [$lists[0][0], $lists[1][0], $lists[0][1], $lists[1][1]], 'complex');

$merged = merge(\@lists, limit => 3, key => sub { $_[0][0] });
#print Dumper($merged);
is_deeply($merged, [$lists[0][0], $lists[1][0], $lists[0][1]], 'limited complex');
