typedef struct _head_ent {
    NV value; /* numeric value to sort on */
    I32 list_num; /* index of the list that this value came from */
    I32 list_idx; /* index into that list of the element this value came from */
    struct _head_ent* next;
} head_ent;

head_ent*
make_ent(NV value, I32 list_num, I32 list_idx)
{
    head_ent* new_head;
    Newxz(new_head, 1, head_ent);
    new_head->value = value;
    new_head->list_num = list_num;
    new_head->list_idx = list_idx;
    new_head->next = NULL;
    return new_head;
}

void
free_ent(head_ent* ent)
{
    Safefree(ent);
}

void
insert_ent(head_ent** list, head_ent* new_ent)
{
    head_ent* cur;
    head_ent** ptr_to_cur;

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

head_ent*
pop_ent(head_ent** list)
{
    head_ent* first = *list;
    if (!first)
        return NULL;
    *list = first->next;
    first->next = NULL;
    return first;
}
