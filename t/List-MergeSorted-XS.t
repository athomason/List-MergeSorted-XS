# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl List-MergeSorted-XS.t'

#########################

use Test::More tests => 56;
use_ok('List::MergeSorted::XS');

#########################

use List::MergeSorted::XS qw/merge/;

# test that bad data is rejected
eval { merge() };
ok($@, 'empty list rejected');

eval { merge(undef) };
ok($@, 'undef rejected');

eval { merge(1); };
ok($@, 'non-list rejected');

eval { merge([1]) };
ok($@, 'list of non-lists rejected');

eval { merge([[1], [undef]]) };
like($@, qr/integer/, 'undef element rejected');

eval { merge([[1.2]]) };
like($@, qr/integer/, 'float element rejected');

eval { merge([['a']]) };
like($@, qr/integer/, 'string element rejected');

eval { merge([['1']]) };
like($@, qr/integer/, 'stringified number element rejected');

{
    local $SIG{__WARN__} = sub { die @_ };
    eval { merge([[1]], key => sub { 'x' }) };
    like($@, qr/isn't numeric/, 'non-numeric key warns');

    eval { merge([[1]], key => sub { undef }) };
    like($@, qr/uninitialized value in subroutine entry/, 'undef key warns');
}

# test that unusual but acceptable data is accepted
is_deeply(merge([]), [], 'no lists');

is_deeply(merge([[]]), [], 'empty list alone');

is_deeply(merge([[], [1]]), [1], 'empty list with others');

srand(999); # use random but reproducible data sets

# make sure to exercise all the codepaths
my %methods = (
    fib     => List::MergeSorted::XS::PRIO_FIB,
    linear  => List::MergeSorted::XS::PRIO_LINEAR,
    sort    => List::MergeSorted::XS::SORT,
);

for my $method (sort keys %methods) {
    local $List::MergeSorted::XS::MERGE_METHOD = $methods{$method};

    # test that simple use cases are handled correctly
    my @lists = ([4, 7, 9], [1, 3, 5], [2, 6, 8]);

    my $merged = merge(\@lists);
    use YAML::Syck;
    is_deeply($merged, [1..9], "$method: unlimited flat") || # $sorted = [1..9]
    print Dump(\@lists, $merged);

    $merged = merge(\@lists, limit => 4);
    is_deeply($merged, [1..4], "$method: limited flat");

    @lists = ([[1, 'x'], [3, {t => 1}]], [[2, bless {}, 'C'], [4, 5]]);
    $merged = merge(\@lists, key => sub { $_[0][0] });
    is_deeply($merged, [$lists[0][0], $lists[1][0], $lists[0][1], $lists[1][1]], "$method: unlimited keyed");

    $merged = merge(\@lists, limit => 3, key => sub { $_[0][0] });
    is_deeply($merged, [$lists[0][0], $lists[1][0], $lists[0][1]], "$method: limited keyed");

    # test that larger lists are handled correctly
    for my $test (1 .. 10) {
        @lists = ();
        for (1 .. 1 + int rand 10) {
            push @lists, [sort {$a <=> $b} map { int rand 1000 } 1 .. int rand 100];
        }
        my %opts;
        $opts{limit} = 1 + int rand 100 if rand() > .5;
        $merged = merge(\@lists, %opts);
        my @expected = sort {$a <=> $b} map {@$_} @lists;
        splice @expected, $opts{limit} if defined $opts{limit} && @expected > $opts{limit};
        is_deeply($merged, \@expected, "$method: random $test");
    }
}
