#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "const-c.inc"

#include "fib.c"
#include "list.c"

NV get_value(SV* el) {
    if (SvNOK(el))
        return SvNV(el);
    else if (SvIOK(el))
        return SvIV(el);
    else
        croak("non-numeric data encountered");
    return 0;
}

MODULE = List::MergeSorted::XS  PACKAGE = List::MergeSorted::XS  PREFIX = l_ms_xs

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

    head_ent* heads = NULL;

    for (n = 0; n < numlists; n++) {
        AV* list = (AV*) SvRV(*av_fetch(lists, n, 0));
        if (av_len(list) < 0)
            continue;

        SV** first_el = av_fetch(list, 0, 0);

        head_ent* ent = make_ent(get_value(*first_el), n, 0);
        insert_ent(&heads, ent);
    }

    for (n = 0; heads && (!limit || n < limit); n++) {
        head_ent* ent = pop_ent(&heads);
        av_push(results, newSVnv(ent->value));

        AV* list = (AV*) SvRV(*av_fetch(lists, ent->list_num, 0));
        if (++ent->list_idx <= av_len(list)) {
            ent->value = get_value(*av_fetch(list, ent->list_idx, 0));
            insert_ent(&heads, ent);
        }
        else {
            free_ent(ent);
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

    struct fibheap* heap = fh_makeheap(min_keyed);

    for (n = 0; n < numlists; n++) {
        AV* list = (AV*) SvRV(*av_fetch(lists, n, 0));
        SV** first_el = av_fetch(list, 0, 0);

        head_ent* ent = make_ent(get_value(*first_el), n, 0);

        fh_insertkey(heap, ent->value, ent);
    }

    for (n = 0; heap->fh_n && (!limit || n < limit); n++) {
		head_ent* ent = (head_ent*) fh_extractmin(heap);

        av_push(results, newSVnv(ent->value));

        AV* list = (AV*) SvRV(*av_fetch(lists, ent->list_num, 0));
        if (++ent->list_idx <= av_len(list)) {
            ent->value = get_value(*av_fetch(list, ent->list_idx, 0));
            fh_insertkey(heap, ent->value, ent);
        }
        else {
            free_ent(ent);
        }
    }

    fh_emptyheap(heap);
    fh_destroyheap(heap);

    RETVAL = newRV((SV*) results);
OUTPUT:
    RETVAL
