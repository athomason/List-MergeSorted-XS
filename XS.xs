#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "const-c.inc"

MODULE = List::MergeSorted::XS      PACKAGE = List::MergeSorted::XS

INCLUDE: const-xs.inc

SV*
_l_ms_xs_merge_linear(p_lists, limit)
    SV* p_lists
    I32 limit
CODE:
    AV* lists = (AV*) SvRV(p_lists);
    AV* results = (AV*) sv_2mortal((SV*) newAV());
    AV* heads = newAV();
    int n;

    for (n = 0; n < av_len(lists); n++) {
        AV* list = (AV*) SvRV(*av_fetch(lists, n, 0));
        SV** first_el = av_fetch(list, 0, 0);
        //av_push(results, );
    }
    RETVAL = newRV((SV*) results);
OUTPUT:
    RETVAL
