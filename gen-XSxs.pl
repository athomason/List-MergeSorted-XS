#!/usr/bin/perl

# XS code generator for priority-queue implementations

use strict;
use warnings;

my %impls = (
    linear => {
        init    => 'lmsxs_ll_ent* heads = NULL;',
        insert  => 'lmsxs_ll_insert_ent(&heads, ent);',
        update  => 'ent->key = key;',
        pop     => 'lmsxs_ll_pop_ent(&heads)',
        more    => 'heads',
        destroy => '',
        alloc   => 'lmsxs_ll_make_ent(key, el, n, 0)',
        free    => 'lmsxs_ll_free_ent',
        type    => 'lmsxs_ll_ent',
    },
    fib => {
        init    => 'struct fibheap* heap = fh_makekeyheap();',
        insert  => 'fh_insertkey(heap, key, ent);',
        update  => '',
        pop     => '(lmsxs_prio_ent*) fh_extractmin(heap)',
        more    => '!fh_empty(heap)',
        destroy => "\n    fh_deleteheap(heap);",
        alloc   => 'lmsxs_make_ent(el, n, 0)',
        free    => 'lmsxs_free_ent',
        type    => 'lmsxs_prio_ent',
    },
);

print <DATA>;

for my $impl (sort keys %impls) {
    my $i = $impls{$impl};

    for my $keyed (0, 1) {
        my $suffix = $keyed ? '_keyed'                 : '_flat';
        my $key    = $keyed ? 'key_from_cv(el, keyer)' : 'key_from_iv(el)';
        my $k1     = $keyed ? ', keyer'                : '';
        my $k2     = $keyed ? "\n    SV* keyer"        : '';

        print <<END_XS;

SV*
l_ms_xs_merge_$impl$suffix(p_lists, limit$k1)
    SV* p_lists
    IV limit$k2
CODE:
    AV* lists = (AV*) SvRV(p_lists);
    AV* results = (AV*) sv_2mortal((SV*) newAV());
    IV numlists = av_len(lists) + 1;
    int n;

    $i->{init}

    for (n = 0; n < numlists; n++) {
        AV* list = (AV*) SvRV(*av_fetch(lists, n, 0));
        if (av_len(list) < 0)
            continue;

        SV* el = *av_fetch(list, 0, 0);
        IV key = $key;

        $i->{type}* ent = $i->{alloc};
        $i->{insert}
    }

    for (n = 0; $i->{more} && (!limit || n < limit); n++) {
        AV* list;
        $i->{type}* ent = $i->{pop};
        av_push(results, newSVsv(ent->sv));

        list = (AV*) SvRV(*av_fetch(lists, ent->list_num, 0));
        if (++ent->list_idx <= av_len(list)) {
            SV* el = *av_fetch(list, ent->list_idx, 0);
            IV key = $key;
            ent->sv = el;
            $i->{update}
            $i->{insert}
        }
        else {
            $i->{free}(ent);
        }
    }

    while ($i->{more})
        $i->{free}($i->{pop});$i->{destroy}

    RETVAL = newRV((SV*) results);
OUTPUT:
    RETVAL
END_XS
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
IV key_from_cv(SV* el, SV* keyer)
{
    int ret;

    dSP;
    PUSHMARK(SP);
    XPUSHs(el);
    PUTBACK;

    ret = call_sv(keyer, G_SCALAR);
    SPAGAIN;

    if (!ret)
        croak("callback did not return a value");

    IV value = POPi;
    PUTBACK;
}

MODULE = List::MergeSorted::XS  PACKAGE = List::MergeSorted::XS  PREFIX = l_ms_xs

PROTOTYPES: ENABLE

INCLUDE: const-xs.inc
