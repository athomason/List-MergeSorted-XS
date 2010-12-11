#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "const-c.inc"

#include "fib.h"
#include "list.h"

static
inline
NV get_value(SV* el) {
    if (SvIOK(el))
        return SvIV(el);
    else
        croak("non-integer data encountered");
    return 0;
}

MODULE = List::MergeSorted::XS  PACKAGE = List::MergeSorted::XS  PREFIX = l_ms_xs

PROTOTYPES: ENABLE

INCLUDE: const-xs.inc

SV*
l_ms_xs_merge_linear(p_lists, limit)
    SV* p_lists
    I32 limit
CODE:
    AV* lists = (AV*) SvRV(p_lists);
    AV* results = (AV*) sv_2mortal((SV*) newAV());
    I32 numlists = av_len(lists) + 1;
    int n;

    lmsxs_head_ent* heads = NULL;

    for (n = 0; n < numlists; n++) {
        AV* list = (AV*) SvRV(*av_fetch(lists, n, 0));
        if (av_len(list) < 0)
            continue;

        SV** first_el = av_fetch(list, 0, 0);

        lmsxs_head_ent* ent = lmsxs_make_ent(get_value(*first_el), n, 0);
        lmsxs_insert_ent(&heads, ent);
    }

    for (n = 0; heads && (!limit || n < limit); n++) {
        lmsxs_head_ent* ent = lmsxs_pop_ent(&heads);
        av_push(results, newSVnv(ent->value));

        AV* list = (AV*) SvRV(*av_fetch(lists, ent->list_num, 0));
        if (++ent->list_idx <= av_len(list)) {
            ent->value = get_value(*av_fetch(list, ent->list_idx, 0));
            lmsxs_insert_ent(&heads, ent);
        }
        else {
            lmsxs_free_ent(ent);
        }
    }

    RETVAL = newRV((SV*) results);
OUTPUT:
    RETVAL

SV*
l_ms_xs_merge_fib(p_lists, limit)
    SV* p_lists
    I32 limit
CODE:
    AV* lists = (AV*) SvRV(p_lists);
    AV* results = (AV*) sv_2mortal((SV*) newAV());
    I32 numlists = av_len(lists) + 1;
    int n;

    struct fibheap* heap = fh_makekeyheap();

    for (n = 0; n < numlists; n++) {
        AV* list = (AV*) SvRV(*av_fetch(lists, n, 0));
        if (av_len(list) < 0)
            continue;

        SV** first_el = av_fetch(list, 0, 0);

        lmsxs_head_ent* ent = lmsxs_make_ent(get_value(*first_el), n, 0);
        fh_insertkey(heap, ent->value, ent);
    }

    for (n = 0; !fh_empty(heap) && (!limit || n < limit); n++) {
		lmsxs_head_ent* ent = (lmsxs_head_ent*) fh_extractmin(heap);
        av_push(results, newSVnv(ent->value));

        AV* list = (AV*) SvRV(*av_fetch(lists, ent->list_num, 0));
        if (++ent->list_idx <= av_len(list)) {
            ent->value = get_value(*av_fetch(list, ent->list_idx, 0));
            fh_insertkey(heap, ent->value, ent);
        }
        else {
            lmsxs_free_ent(ent);
        }
    }

    fh_deleteheap(heap);

    RETVAL = newRV((SV*) results);
OUTPUT:
    RETVAL
