#!/usr/bin/perl

use strict;
use warnings;

use Benchmark;
use Getopt::Long;

use List::MergeSorted::XS 'merge';
use List::Util qw( min max );

GetOptions(
    'iters=i'       => \(my $time_count = -5),
    'elements=i'    => \(my $elements   = 10),
    'fixed-total!'  => \(my $const_total_elems = 0), # otherwise, constant elems per list
);

my $quit = 0;
$SIG{INT} = sub { exit if $quit++; print "Interrupting; CTRL-C again to quit\n" };

my @num_lists = (1, 2, 3, 5, 10, 50, 100, 500, 1000, 5000, 10000);
my @limits = (1, 5, 10, 25, 50, 75, 100);
my %overall_timings;

srand 999;

for my $keyed (0, 1) {
    for my $limit_percent (@limits) {
        for my $num_lists (@num_lists) {
            my $list_size = $const_total_elems ? max(int($elements / $num_lists), 1) : $elements;

            my %opts;
            $opts{key} = sub { $_[0][0] } if $keyed;
            $opts{limit} = max(1, int($limit_percent / 100 * $num_lists * $list_size)) if $limit_percent;

            warn sprintf "keyed = %s; # lists = %d; list size = %d; limit = %s\n",
                $keyed ? 'on' : 'off', $num_lists, $list_size, defined $opts{limit} ? $opts{limit} : 'none';

            my @lists;
            for (1 .. $num_lists) {
                my @list = sort { $a <=> $b } map { int rand 1000000 } 1 .. $list_size;
                @list = map { [$_ => $_] } @list if $keyed;
                push @lists, \@list;
            }

            my %methods = (
                auto    => undef,
                linear  => List::MergeSorted::XS::PRIO_LINEAR,
                fib     => List::MergeSorted::XS::PRIO_FIB,
                sort    => List::MergeSorted::XS::SORT,
            );
            for my $method (sort keys %methods) {
                local $List::MergeSorted::XS::MERGE_METHOD = $methods{$method};
                my $bench = timethis($time_count, sub { merge(\@lists, %opts) }, $method);
                $overall_timings{$keyed}{$limit_percent}{$method}{$num_lists} = $bench->[5] / $bench->[1]; # iterations over user time
                last if $quit;
            }
            last if $quit;
        }
    }
}

#use Data::Dumper; print Data::Dumper->Dump(\%overall_timings);

printf "%7s %5s %12s", 'keyed', 'limit', 'method';
printf " %9d", $_ for @num_lists;
print "\n";

for my $keyed (0, 1) {
    for my $limit_percent (@limits) {
        for my $method (sort keys %{ $overall_timings{$keyed}{$limit_percent} }) {
            printf "%7s %5s %12s", $keyed, $limit_percent ? $limit_percent . '%' : 'none', $method;
            printf " %9.1f", $overall_timings{$keyed}{$limit_percent}{$method}{$_} || 0 for @num_lists;
            print "\n";
        }
    }
}
