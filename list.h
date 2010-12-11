typedef struct lmsxs__head_ent {
    I32 value; /* numeric value to sort on */
    I32 list_num; /* index of the list that this value came from */
    I32 list_idx; /* index into that list of the element this value came from */
    struct lmsxs__head_ent* next;
} lmsxs_head_ent;

lmsxs_head_ent* lmsxs_make_ent(I32 value, I32 list_num, I32 list_idx);
void lmsxs_free_ent(lmsxs_head_ent* ent);
void lmsxs_insert_ent(lmsxs_head_ent** list, lmsxs_head_ent* new_ent);
lmsxs_head_ent* lmsxs_pop_ent(lmsxs_head_ent** list);
