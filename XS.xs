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

SV*
l_ms_xs_merge_fib_flat(p_lists, limit)
    SV* p_lists
    IV limit
CODE:
    AV* lists = (AV*) SvRV(p_lists);
    AV* results = (AV*) sv_2mortal((SV*) newAV());
    IV numlists = av_len(lists) + 1;
    int n;

    struct fibheap* heap = fh_makekeyheap();

    for (n = 0; n < numlists; n++) {
        AV* list = (AV*) SvRV(*av_fetch(lists, n, 0));
        if (av_len(list) < 0)
            continue;

        SV* el = *av_fetch(list, 0, 0);
        IV key = key_from_iv(el);

        lmsxs_prio_ent* ent = lmsxs_make_ent(el, n, 0);
        fh_insertkey(heap, key, ent);
    }

    for (n = 0; !fh_empty(heap) && (!limit || n < limit); n++) {
        AV* list;
        lmsxs_prio_ent* ent = (lmsxs_prio_ent*) fh_extractmin(heap);
        av_push(results, newSVsv(ent->sv));

        list = (AV*) SvRV(*av_fetch(lists, ent->list_num, 0));
        if (++ent->list_idx <= av_len(list)) {
            SV* el = *av_fetch(list, ent->list_idx, 0);
            IV key = key_from_iv(el);
            ent->sv = el;
            
            fh_insertkey(heap, key, ent);
        }
        else {
            lmsxs_free_ent(ent);
        }
    }

    while (!fh_empty(heap))
        lmsxs_free_ent((lmsxs_prio_ent*) fh_extractmin(heap));
    fh_deleteheap(heap);

    RETVAL = newRV((SV*) results);
OUTPUT:
    RETVAL

SV*
l_ms_xs_merge_fib_keyed(p_lists, limit, keyer)
    SV* p_lists
    IV limit
    SV* keyer
CODE:
    AV* lists = (AV*) SvRV(p_lists);
    AV* results = (AV*) sv_2mortal((SV*) newAV());
    IV numlists = av_len(lists) + 1;
    int n;

    struct fibheap* heap = fh_makekeyheap();

    for (n = 0; n < numlists; n++) {
        AV* list = (AV*) SvRV(*av_fetch(lists, n, 0));
        if (av_len(list) < 0)
            continue;

        SV* el = *av_fetch(list, 0, 0);
        IV key = key_from_cv(el, keyer);

        lmsxs_prio_ent* ent = lmsxs_make_ent(el, n, 0);
        fh_insertkey(heap, key, ent);
    }

    for (n = 0; !fh_empty(heap) && (!limit || n < limit); n++) {
        AV* list;
        lmsxs_prio_ent* ent = (lmsxs_prio_ent*) fh_extractmin(heap);
        av_push(results, newSVsv(ent->sv));

        list = (AV*) SvRV(*av_fetch(lists, ent->list_num, 0));
        if (++ent->list_idx <= av_len(list)) {
            SV* el = *av_fetch(list, ent->list_idx, 0);
            IV key = key_from_cv(el, keyer);
            ent->sv = el;
            
            fh_insertkey(heap, key, ent);
        }
        else {
            lmsxs_free_ent(ent);
        }
    }

    while (!fh_empty(heap))
        lmsxs_free_ent((lmsxs_prio_ent*) fh_extractmin(heap));
    fh_deleteheap(heap);

    RETVAL = newRV((SV*) results);
OUTPUT:
    RETVAL

SV*
l_ms_xs_merge_linear_flat(p_lists, limit)
    SV* p_lists
    IV limit
CODE:
    AV* lists = (AV*) SvRV(p_lists);
    AV* results = (AV*) sv_2mortal((SV*) newAV());
    IV numlists = av_len(lists) + 1;
    int n;

    lmsxs_ll_ent* heads = NULL;

    for (n = 0; n < numlists; n++) {
        AV* list = (AV*) SvRV(*av_fetch(lists, n, 0));
        if (av_len(list) < 0)
            continue;

        SV* el = *av_fetch(list, 0, 0);
        IV key = key_from_iv(el);

        lmsxs_ll_ent* ent = lmsxs_ll_make_ent(key, el, n, 0);
        lmsxs_ll_insert_ent(&heads, ent);
    }

    for (n = 0; heads && (!limit || n < limit); n++) {
        AV* list;
        lmsxs_ll_ent* ent = lmsxs_ll_pop_ent(&heads);
        av_push(results, newSVsv(ent->sv));

        list = (AV*) SvRV(*av_fetch(lists, ent->list_num, 0));
        if (++ent->list_idx <= av_len(list)) {
            SV* el = *av_fetch(list, ent->list_idx, 0);
            IV key = key_from_iv(el);
            ent->sv = el;
            ent->key = key;
            lmsxs_ll_insert_ent(&heads, ent);
        }
        else {
            lmsxs_ll_free_ent(ent);
        }
    }

    while (heads)
        lmsxs_ll_free_ent(lmsxs_ll_pop_ent(&heads));

    RETVAL = newRV((SV*) results);
OUTPUT:
    RETVAL

SV*
l_ms_xs_merge_linear_keyed(p_lists, limit, keyer)
    SV* p_lists
    IV limit
    SV* keyer
CODE:
    AV* lists = (AV*) SvRV(p_lists);
    AV* results = (AV*) sv_2mortal((SV*) newAV());
    IV numlists = av_len(lists) + 1;
    int n;

    lmsxs_ll_ent* heads = NULL;

    for (n = 0; n < numlists; n++) {
        AV* list = (AV*) SvRV(*av_fetch(lists, n, 0));
        if (av_len(list) < 0)
            continue;

        SV* el = *av_fetch(list, 0, 0);
        IV key = key_from_cv(el, keyer);

        lmsxs_ll_ent* ent = lmsxs_ll_make_ent(key, el, n, 0);
        lmsxs_ll_insert_ent(&heads, ent);
    }

    for (n = 0; heads && (!limit || n < limit); n++) {
        AV* list;
        lmsxs_ll_ent* ent = lmsxs_ll_pop_ent(&heads);
        av_push(results, newSVsv(ent->sv));

        list = (AV*) SvRV(*av_fetch(lists, ent->list_num, 0));
        if (++ent->list_idx <= av_len(list)) {
            SV* el = *av_fetch(list, ent->list_idx, 0);
            IV key = key_from_cv(el, keyer);
            ent->sv = el;
            ent->key = key;
            lmsxs_ll_insert_ent(&heads, ent);
        }
        else {
            lmsxs_ll_free_ent(ent);
        }
    }

    while (heads)
        lmsxs_ll_free_ent(lmsxs_ll_pop_ent(&heads));

    RETVAL = newRV((SV*) results);
OUTPUT:
    RETVAL
