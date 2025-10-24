#include <stdarg.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>

char *tantivy_last_error(void);

void tantivy_free_str(char *s);

int tantivy_init(const char *dir_path);

int tantivy_add_doc(const char *text_ptr);

char *tantivy_search(const char *query_ptr, int top_k);
