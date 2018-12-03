#include "display.h"
#include "keyboard.h"
#include "softmath.h"
#include <assert.h>
#include <stdint.h>
#include <stdlib.h>

#define BITPACKED_WHITE 0xffffff
#define BITPACKED_GRAY 0x808080
#define MAX_SHOTS 5
#define MAX_ASTEROIDS 8
#define ASTEROID_WIDTH 10

typedef struct {
  char r;
  char g;
  char b;
} pixel;

typedef struct {
  fp16_t x;
  fp16_t y;
  fp16_t vx;
  fp16_t vy;
  int32_t timeout;
} point;

typedef struct {
  fp16_t x;
  fp16_t y;
  fp16_t degrees;
  fp16_t vx;
  fp16_t vy;
  fp16_t vd;
  int32_t size;
} object;

enum color { BLACK = 0, WHITE = 1, GRAY = 2, ORANGE = 3 };

// BLACK, WHITE, GRAY, ORANGE
static pixel palette[4] = {
    {0, 0, 0}, {255, 255, 255}, {128, 128, 128}, {255, 165, 0}};
static point shots[MAX_SHOTS];
static object asteroids[MAX_ASTEROIDS];

int32_t sound_period = 0;
int32_t sound_timeout = 0;

// uses 3 bits of randomness to return nonzero -96 to 96
// (in fp16_t, this corresponds to -1.5 to 1.5)
int32_t rng() {
  int32_t ret = 0;
  while (ret == 0) {
    int32_t randval = rand();
    int32_t sign = (1 - 2 * (randval & 0x1));
    ret = sign * (randval & 0x6) << 4;
  }
  return ret;
}

void swap(fp16_t *a, fp16_t *b) {
  *a ^= *b;
  *b ^= *a;
  *a ^= *b;
}

// draws (x1, y1) -> (x2, y2) on the framebuffer with color c
// returns whether or not it drew over color check_collision (if not BLACK)
int32_t draw_line(fp16_t x1, fp16_t y1, fp16_t x2, fp16_t y2,
                  enum color check_collision, enum color c) {
  char r = palette[c].r;
  char g = palette[c].g;
  char b = palette[c].b;

  int32_t collision_occurred = 0;

  // naively avoid division by zero
  if (x2 == x1)
    x2++;
  if (y2 == y1)
    y2++;

  // determine direction to iterate based on which dimension
  // requires more pixels to be drawn (avoids "skipped pixels")
  if (abs(x2 - x1) >= abs(y2 - y1)) {
    if (x1 > x2) {
      // ensure iteration proceeds as x1 -> x2
      swap(&x1, &x2);
      swap(&y1, &y2);
    }

    fp16_t x = x1;
    fp16_t y = y1;
    fp16_t slope = fpdiv(y2 - y1, x2 - x1);

    for (x = x1; x <= x2; x += INT_TO_FP(1)) {
      int32_t draw_x = round_fp_to_int(x);
      int32_t draw_y = round_fp_to_int(y);
      mod(&draw_x, XRES);
      mod(&draw_y, YRES);

      // collisions are calculated on the framebuffer itself
      if (check_collision && read_pixel(draw_x, draw_y) == check_collision)
        collision_occurred = 1;

      write_pixel(draw_x, draw_y, r, g, b);
      y += slope;
    }
  } else {
    if (y1 > y2) {
      // ensure iteration proceeds as y1 -> y2
      swap(&x1, &x2);
      swap(&y1, &y2);
    }

    fp16_t x = x1;
    fp16_t y = y1;
    fp16_t slope = fpdiv(x2 - x1, y2 - y1);

    for (y = y1; y <= y2; y += INT_TO_FP(1)) {
      int32_t draw_x = round_fp_to_int(x);
      int32_t draw_y = round_fp_to_int(y);
      mod(&draw_x, XRES);
      mod(&draw_y, YRES);

      // collisions are calculated on the framebuffer itself
      if (check_collision && read_pixel(draw_x, draw_y) == check_collision)
        collision_occurred = 1;

      write_pixel(draw_x, draw_y, r, g, b);
      x += slope;
    }
  }

  return collision_occurred;
}

// rotates (x, y) about (0, 0) by a rotation of degrees degrees (in fp16_t)
// returns rotated (x', y') in outparameters
void rotate(fp16_t x, fp16_t y, fp16_t degrees, fp16_t *rx, fp16_t *ry) {
  fp16_t cos_d = fpcos(degrees);
  fp16_t sin_d = fpsin(degrees);
  *rx = fpmult(cos_d, x) + fpmult(-sin_d, y);
  *ry = fpmult(sin_d, x) + fpmult(cos_d, y);
}

// draws ship at (x, y) rotated by degrees degrees (in fp16_t) with color c
void draw_ship(fp16_t x, fp16_t y, fp16_t degrees, enum color c) {
  /*
   *  (-7, 10) -- (0, -10) -- (7, 10)
   *  (-5, 6) -- (5, 6)
   */

  fp16_t ax, ay, bx, by, cx, cy, dx, dy, ex, ey;
  int32_t collision = 0;

  rotate(INT_TO_FP(0), INT_TO_FP(-10), degrees, &ax, &ay);
  rotate(INT_TO_FP(7), INT_TO_FP(10), degrees, &bx, &by);
  rotate(INT_TO_FP(-7), INT_TO_FP(10), degrees, &cx, &cy);

  if (draw_line(x + ax, y + ay, x + bx, y + by, BITPACKED_GRAY, c) ||
      draw_line(x + ax, y + ay, x + cx, y + cy, BITPACKED_GRAY, c))
    exit(0); // collision occurred

  rotate(INT_TO_FP(-5), INT_TO_FP(6), degrees, &dx, &dy);
  rotate(INT_TO_FP(5), INT_TO_FP(6), degrees, &ex, &ey);
  if (draw_line(x + dx, y + dy, x + ex, y + ey, BITPACKED_GRAY, c))
    exit(0); // collision occurred
}

// draws flame on ship (at (x, y) rotated by degrees degrees) with color c
void draw_flame(fp16_t x, fp16_t y, fp16_t degrees, enum color c) {
  // (-4, 6) -- (0, 12) -- (4, 6)

  fp16_t ax, ay, bx, by, cx, cy;
  rotate(INT_TO_FP(-4), INT_TO_FP(6), degrees, &ax, &ay);
  rotate(INT_TO_FP(0), INT_TO_FP(12), degrees, &bx, &by);
  rotate(INT_TO_FP(4), INT_TO_FP(6), degrees, &cx, &cy);

  draw_line(x + ax, y + ay, x + bx, y + by, 0, c);
  draw_line(x + bx, y + by, x + cx, y + cy, 0, c);
}

// draws shots that have positive timeout with color c
void draw_shots(enum color c) {
  for (int32_t i = 0; i < MAX_SHOTS; i++) {
    if (shots[i].timeout > 0) {
      if (draw_line(shots[i].x, shots[i].y - INT_TO_FP(2), shots[i].x,
                    shots[i].y + INT_TO_FP(2), BITPACKED_GRAY, c) ||
          draw_line(shots[i].x - INT_TO_FP(2), shots[i].y,
                    shots[i].x + INT_TO_FP(2), shots[i].y, BITPACKED_GRAY, c)) {
        shots[i].timeout = 1; // shot will disappear next frame
      }
    }
  }
}

// draws asteroids that have positive size with color c
void draw_asteroids(enum color c) {
  // (-10, 10) -- (10, 10) -- (10, -10) -- (-10, -10)

  for (int32_t i = 0; i < MAX_ASTEROIDS; i++) {
    if (asteroids[i].size) {
      int32_t collision = 0;
      int32_t degrees = asteroids[i].degrees;
      int32_t width = asteroids[i].size * ASTEROID_WIDTH;

      fp16_t x = asteroids[i].x;
      fp16_t y = asteroids[i].y;

      fp16_t rx, ry;

      rotate(INT_TO_FP(width), INT_TO_FP(-width), degrees, &rx, &ry);

      // Exploit symmetry of the square to only compute one rotation
      collision |=
          draw_line(x + rx, y + ry, x - ry, y + rx, BITPACKED_WHITE, c);
      collision |=
          draw_line(x + rx, y + ry, x + ry, y - rx, BITPACKED_WHITE, c);
      collision |=
          draw_line(x - rx, y - ry, x - ry, y + rx, BITPACKED_WHITE, c);
      collision |=
          draw_line(x - rx, y - ry, x + ry, y - rx, BITPACKED_WHITE, c);

      if (collision) {
        // make current asteroid smaller
        asteroids[i].size--;
        if (asteroids[i].size) {
          // split asteroid into two with random velocities
          asteroids[i].vx = rng();
          asteroids[i].vy = rng();
          asteroids[i].vd = rng();
          asteroids[i + 4] = (object){
              asteroids[i].x, asteroids[i].y, rng(), rng(), rng(), rng(), 1};
        }

        // for six frames, play 220 Hz (~455K * 10 ns period)
        sound_period = 454545;
        sound_timeout = 6;
      }
    }
  }
}

// update shot and asteroid positions
void update_objects() {
  for (int32_t i = 0; i < MAX_SHOTS; i++) {
    if (shots[i].timeout > 0) {
      shots[i].x += shots[i].vx;
      shots[i].y += shots[i].vy;

      mod(&shots[i].x, INT_TO_FP(XRES));
      mod(&shots[i].y, INT_TO_FP(YRES));
      shots[i].timeout--;
    }
  }

  for (int32_t i = 0; i < MAX_ASTEROIDS; i++) {
    if (asteroids[i].size) {
      asteroids[i].x += asteroids[i].vx;
      asteroids[i].y += asteroids[i].vy;
      asteroids[i].degrees += asteroids[i].vd;

      mod(&asteroids[i].x, INT_TO_FP(XRES));
      mod(&asteroids[i].y, INT_TO_FP(YRES));
      mod(&asteroids[i].degrees, INT_TO_FP(360));
    }
  }
}

void game_loop() {
  fp16_t vx = 0;
  fp16_t vy = 0;
  fp16_t degrees = INT_TO_FP(0);
  fp16_t x = INT_TO_FP(XRES / 2);
  fp16_t y = INT_TO_FP(YRES / 2);

  asteroids[0] =
      (object){INT_TO_FP(100), INT_TO_FP(100), rng(), rng(), rng(), rng(), 2};
  asteroids[1] =
      (object){INT_TO_FP(400), INT_TO_FP(300), rng(), rng(), rng(), rng(), 2};
  asteroids[2] =
      (object){INT_TO_FP(600), INT_TO_FP(200), rng(), rng(), rng(), rng(), 2};
  asteroids[3] =
      (object){INT_TO_FP(300), INT_TO_FP(50), rng(), rng(), rng(), rng(), 2};
  asteroids[4] = (object){0, 0, 0, 0, 0, 0, 0};
  asteroids[5] = (object){0, 0, 0, 0, 0, 0, 0};
  asteroids[6] = (object){0, 0, 0, 0, 0, 0, 0};
  asteroids[7] = (object){0, 0, 0, 0, 0, 0, 0};

  int32_t w_press = 0;
  int32_t s_held = 0;

  clear_screen();
  while (1) {
    draw_asteroids(GRAY);
    draw_ship(x, y, degrees, WHITE);
    draw_shots(WHITE);
    if (w_press) {
      draw_flame(x, y, degrees, ORANGE);
    }

    wait_for_vsync();

    // redraw objects in black to "clear" the screen
    draw_asteroids(BLACK);
    draw_ship(x, y, degrees, BLACK);
    draw_shots(BLACK);
    if (w_press) {
      draw_flame(x, y, degrees, BLACK);
      w_press = 0;
    }

    if (sound_timeout) {
      sound_timeout--;
    } else {
      sound_period = 0;
    }

    update_objects();

    char c = read_keyboard();

    if (c != 's')
      s_held = 0;

    if (c == 'w') {
      vx += fpmult(16, fpsin(degrees));
      vy -= fpmult(16, fpcos(degrees));
      w_press = 1;

      // for one frame, play 125 Hz (800K * 10 ns period)
      sound_period = 800000;
      sound_timeout = 1;
    } else if (c == 'a') {
      degrees -= INT_TO_FP(5);
    } else if (c == 'd') {
      degrees += INT_TO_FP(5);
    } else if (!s_held && c == 's') {
      s_held = 1;
      fp16_t front_x, front_y;
      rotate(INT_TO_FP(0), INT_TO_FP(-10), degrees, &front_x, &front_y);
      front_x += x;
      front_y += y;

      int32_t first_free = 0;
      for (first_free = 0; first_free < MAX_SHOTS; first_free++) {
        if (shots[first_free].timeout == 0)
          break;
      }
      if (first_free < MAX_SHOTS) {
        shots[first_free].x = front_x;
        shots[first_free].y = front_y;
        shots[first_free].vx = vx + fpmult(INT_TO_FP(3), fpsin(degrees));
        shots[first_free].vy = vy - fpmult(INT_TO_FP(3), fpcos(degrees));
        shots[first_free].timeout = 120;

        // for six frames, play 440 Hz (~227K * 10 ns period)
        sound_period = 227273;
        sound_timeout = 6;
      }
    } else if (c == 'q') {
      break;
    }

    mod(&degrees, INT_TO_FP(360));
    mod(&x, INT_TO_FP(XRES));
    mod(&y, INT_TO_FP(YRES));

    x += vx;
    y += vy;

    // slow ship velocity slightly every frame
    // in fp16_t, 65 is ~1.02
    vx = fpdiv(vx, 65);
    vy = fpdiv(vy, 65);
  }
}

int main() {
  srand(time(NULL));
  setup_display();
  setup_keyboard();
  game_loop();
  return 0;
}
