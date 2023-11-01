#include "foo.h"

void foo(uint8_t *buf, size_t len) {
  for (int i = 0; i < len; ++i) {
    if (i % 2 == 1)
      buf[i] += 10;
  }
}
