#include "bar.h"

void add_one_to_ints(int32_t *ints, size_t nmemb) {
  for (size_t i = 0; i < nmemb; ++i) {
    ints[i]++;
  }
}
