#include "bar.h"
#include "foo.h"

static uint8_t bytes[1000];

int main() {
  for (int i = 0; i < sizeof(bytes); ++i) {
    bytes[i] = i;
  }

  foo(bytes, sizeof(bytes));
  bar(bytes, sizeof(bytes));
}
