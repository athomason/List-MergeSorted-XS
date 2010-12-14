#!/usr/bin/perl

# XS code generator for priority-queue implementations

use strict;
use warnings;

use Template;

print <DATA>;

my %impls = (
    linear => {
        type    => 'lmsxs_ll_ent',
        insert  => 'lmsxs_ll_insert_ent(&heads, ent);',
        pop     => 'lmsxs_ll_pop_ent(&heads)',
        alloc   => 'lmsxs_ll_make_ent(key, el, n, 0)',
        free    => 'lmsxs_ll_free_ent',
        more    => 'heads',
    },
    fib => {
        type    => 'lmsxs_prio_ent',
        insert  => 'fh_insertkey(heads, key, ent);',
        pop     => '(lmsxs_prio_ent*) fh_extractmin(heads)',
        alloc   => 'lmsxs_make_ent(el, n, 0)',
        free    => 'lmsxs_free_ent',
        more    => '!fh_empty(heads)',
    },
);

for my $impl (sort keys %impls) {
    for my $keyed (0, 1) {
        for my $dedupe (0, 1) {
            my %vars = (
                %{ $impls{$impl} },
                impl   => $impl,
                keyed  => $keyed,
                dedupe => $dedupe,
            );

            $vars{name} = "l_ms_xs_merge_";
            $vars{name} .= $impl;
            $vars{name} .= $keyed ? '_keyed' : '_flat';
            $vars{name} .= $dedupe ? '_dedupe' : '_dupeok';

            my @params = qw( p_lists limit );
            push @params, 'keyer' if $keyed;
            push @params, 'uniquer' if $dedupe;
            $vars{params} = join ', ', @params;

            $vars{key} = $keyed ? 'callback_value(el, keyer)' : 'key_from_iv(el)';

            my $template_text = <<END_XS;

SV*
[% name %]([% params %])
  SV* p_lists
  IV limit
  [% IF keyed %]SV* keyer[% END %]
  [% IF dedupe %]SV* uniquer[% END %]
CODE:
    AV* lists = (AV*) SvRV(p_lists);
    AV* results = (AV*) sv_2mortal((SV*) newAV());
    IV numlists = av_len(lists) + 1;
    int n;

    [% IF impl == "linear" %]
    lmsxs_ll_ent* heads = NULL;
    [% ELSIF impl == "fib" %]
    struct fibheap* heads = fh_makekeyheap();
    [% END %]

    for (n = 0; n < numlists; n++) {
        AV* list = (AV*) SvRV(*av_fetch(lists, n, 0));
        if (av_len(list) < 0)
            continue;

        SV* el = *av_fetch(list, 0, 0);
        IV key = [% key %];

        [% type %]* ent = [% alloc %];
        [% insert %];
    }

    [% IF dedupe %]IV last_unique;[% END %]
    for (n = 0; [% more %] && (!limit || n < limit); ) {
        AV* list;
        [% type %]* ent = [% pop %];

        [% IF dedupe %]
        IV unique = callback_value(ent->sv, uniquer);
        if (!n || unique != last_unique) {
            av_push(results, newSVsv(ent->sv));
            n++;
            last_unique = unique;
        }
        [% ELSE %]
        av_push(results, newSVsv(ent->sv));
        n++;
        [% END %]

        list = (AV*) SvRV(*av_fetch(lists, ent->list_num, 0));
        if (++ent->list_idx <= av_len(list)) {
            SV* el = *av_fetch(list, ent->list_idx, 0);
            IV key = [% key %];
            ent->sv = el;
            [% IF impl == 'linear' %]ent->key = key;[% END %]
            [% insert %]
        }
        else {
            [% free %](ent);
        }
    }

    while ([% more %])
        [% free %]([% pop %]);
    [% IF impl == "fib" %]fh_deleteheap(heads);[% END %]

    RETVAL = newRV((SV*) results);
OUTPUT:
    RETVAL
END_XS

            my Template $tt = Template->new or die "Couldn't instantiate template: $Template::ERROR";
            my $output;
            $tt->process(\$template_text, \%vars, \$output) or die $tt->error();

            $output =~ s/\n^ +$//mg; # strip whitespace-only lines introduced by TT

            print $output;
        }
    }
}

__DATA__
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "const-c.inc"

#include "fib.h"
#include "list.h"
#include "prio.h"

static
inline
IV key_from_iv(SV* el) {
    if (SvIOK(el))
        return SvIV(el);
    else
        croak("non-integer data encountered");
    return 0;
}

static
inline
IV callback_value(SV* el, SV* callback)
{
    int ret;

    dSP;
    PUSHMARK(SP);
    XPUSHs(el);
    PUTBACK;

    ret = call_sv(callback, G_SCALAR);
    SPAGAIN;

    if (!ret)
        croak("callback did not return a value");

    IV value = POPi;
    PUTBACK;

    return value;
}

MODULE = List::MergeSorted::XS  PACKAGE = List::MergeSorted::XS  PREFIX = l_ms_xs

PROTOTYPES: ENABLE

INCLUDE: const-xs.inc
