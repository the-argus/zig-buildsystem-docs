#include <raylib.h>
#include <math.h>

#define SCREEN_WIDTH 600
#define SCREEN_HEIGHT 600

int main() {
  SetConfigFlags(FLAG_MSAA_4X_HINT);
  InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT,
             "Zig buildsystem example with raylib");
  SetTargetFPS(60);

  while (!WindowShouldClose()) {
    BeginDrawing();
    ClearBackground(BLACK);
    DrawRectanglePro((Rectangle){.width = 100,
                                 .height = 100,
                                 .x = (int)(GetTime() * 200) % SCREEN_WIDTH,
                                 .y = SCREEN_HEIGHT / 2.0},
                     (Vector2){0, 0}, sin(GetTime()) * RAD2DEG, RED);
    EndDrawing();
  }

  CloseWindow();
}
