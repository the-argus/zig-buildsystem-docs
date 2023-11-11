#include "bar.h"
#include <foo.h>

void mylib_add_number_to_ints(int32_t *ints, size_t nmemb,
                              uint32_t number_to_add) {
  for (size_t i = 0; i < number_to_add; ++i) {
    add_one_to_ints(ints, nmemb);
  }
}
