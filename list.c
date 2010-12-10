typedef struct _head_ent {
    NV value;
    I32 list_num;
    I32 list_idx;
    struct _head_ent* next;
} head_ent;

void dump_ent(head_ent* list) {
    int m;
    head_ent* cur;
    printf("dumping 0x%x:\n", list);
    for (m = 0, cur = list; cur; cur = cur->next, m++) {
        printf("  %d 0x%x: %f,%d,%d,0x%x\n", m, cur, cur->value, cur->list_num, cur->list_idx, cur->next);
    }
}

head_ent*
make_ent(NV value, I32 list_num, I32 list_idx)
{
    head_ent* new_head;
    Newxz(new_head, 1, head_ent);
    //new_head = calloc(1, sizeof(head_ent));
    new_head->value = value;
    new_head->list_num = list_num;
    new_head->list_idx = list_idx;
    new_head->next = NULL;
//printf("made 0x%x: %f,%d,%d,0x%x\n", new_head, new_head->value, new_head->list_num, new_head->list_idx, new_head->next);
    return new_head;
}

void
free_ent(head_ent* ent)
{
    Safefree(ent);
    //free(ent);
//printf("freed 0x%x\n", ent);
}

void
insert_ent(head_ent** list, head_ent* new_ent)
{
    head_ent* cur;
    head_ent** ptr_to_cur;

    if (!*list) {
        /* list is empty */
        *list = new_ent;
//printf("was empty, adding 0x%x <-- 0x%x\n", new_ent, list);
//printf("inserted 0x%x at start: %f,%d,%d,0x%x\n", new_ent, new_ent->value, new_ent->list_num, new_ent->list_idx, new_ent->next);
//dump_ent(*list);
        return;
    }

    for (
        ptr_to_cur = list, cur = *list;
        cur;
        ptr_to_cur = &((*ptr_to_cur)->next), cur = cur->next
    ) {
//printf("comparing 0x%x to 0x%x: %f vs %f\n", new_ent, cur, new_ent->value, cur->value);
        if (new_ent->value < cur->value) {
//printf("%f < %f\n", new_ent->value, cur->value);
            new_ent->next = cur;
            *ptr_to_cur = new_ent;
//printf("inserted 0x%x in middle: %f,%d,%d,0x%x\n", new_ent, new_ent->value, new_ent->list_num, new_ent->list_idx, new_ent->next);
//dump_ent(*list);
            return;
        }
//printf("next\n");
    }

//printf("adding at end 0x%x <-- 0x%x\n", new_ent, ptr_to_cur);
    *ptr_to_cur = new_ent;
//printf("inserted 0x%x at end: %f,%d,%d,0x%x\n", new_ent, new_ent->value, new_ent->list_num, new_ent->list_idx, new_ent->next);
//dump_ent(*list);
}

head_ent*
pop_ent(head_ent** list)
{
    head_ent* first = *list;
    if (!first)
        return NULL;
    *list = first->next;
    first->next = NULL;
//printf("popped 0x%x: %f,%d,%d,0x%x\n", first, first->value, first->list_num, first->list_idx, first->next);
//dump_ent(*list);
    return first;
}
