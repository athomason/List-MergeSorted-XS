#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "list.h"

lmsxs_head_ent*
lmsxs_make_ent(I32 value, I32 list_num, I32 list_idx)
{
    lmsxs_head_ent* new_head;
    Newxz(new_head, 1, lmsxs_head_ent);
    new_head->value = value;
    new_head->list_num = list_num;
    new_head->list_idx = list_idx;
    new_head->next = NULL;
    return new_head;
}

void
lmsxs_free_ent(lmsxs_head_ent* ent)
{
    Safefree(ent);
}

void
lmsxs_insert_ent(lmsxs_head_ent** list, lmsxs_head_ent* new_ent)
{
    lmsxs_head_ent* cur;
    lmsxs_head_ent** ptr_to_cur;

    if (!*list) {
        /* list is empty */
        *list = new_ent;
        return;
    }

    for (
        ptr_to_cur = list, cur = *list;
        cur;
        ptr_to_cur = &((*ptr_to_cur)->next), cur = cur->next
    ) {
        if (new_ent->value < cur->value) {
            new_ent->next = cur;
            *ptr_to_cur = new_ent;
            return;
        }
    }

    /* insert at end */
    *ptr_to_cur = new_ent;
}

lmsxs_head_ent*
lmsxs_pop_ent(lmsxs_head_ent** list)
{
    lmsxs_head_ent* first = *list;
    if (!first)
        return NULL;
    *list = first->next;
    first->next = NULL;
    return first;
}
