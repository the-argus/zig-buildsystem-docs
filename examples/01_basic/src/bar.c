#include "bar.h"

void bar(uint8_t *buf, size_t len) {
  for (int i = 0; i < len; ++i) {
    if (i % 2 == 0)
      ++buf[i];
  }
}
