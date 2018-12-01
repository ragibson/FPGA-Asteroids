#include <assert.h>
#include <fcntl.h>
#include <linux/fb.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <sys/mman.h>
#include <sys/types.h>
#include <time.h>
#include <unistd.h>

#define XRES 640
#define YRES 480
#define MAX_FPS 60

int fb_fd;
long int fb_size;
char *fbp;
struct fb_var_screeninfo vinfo;
struct fb_fix_screeninfo finfo;
clock_t frame_start;

void cleanup_display() {
  munmap(fbp, fb_size);
  close(fb_fd);
}

void setup_display() {
  int fb_fd = open("/dev/fb0", O_RDWR);
  if (fb_fd == -1) {
    fprintf(stderr, "Error: can't open framebuffer");
    exit(1);
  }

  if (ioctl(fb_fd, FBIOGET_FSCREENINFO, &finfo) == -1 ||
      ioctl(fb_fd, FBIOGET_VSCREENINFO, &vinfo) == -1) {
    fprintf(stderr, "Error reading framebuffer information.\n");
    exit(1);
  }
  fb_size = vinfo.xres * vinfo.yres * vinfo.bits_per_pixel / 8;

  fbp =
      (char *)mmap(NULL, fb_size, PROT_READ | PROT_WRITE, MAP_SHARED, fb_fd, 0);
  if (fbp == MAP_FAILED) {
    fprintf(stderr, "Error: failed to mmap framebuffer");
    exit(1);
  }
  printf("Successfully initialized framebuffer with %dx%dx%d\n", vinfo.xres,
         vinfo.yres, vinfo.bits_per_pixel);

  if (vinfo.bits_per_pixel != 32) {
    fprintf(stderr, "Bit depth %d not supported.\n", vinfo.bits_per_pixel);
    exit(1);
  }

  // initially color entire screen grey
  memset(fbp, 0x77, fb_size);
  frame_start = clock();
  atexit(cleanup_display);
}

void write_pixel(int x, int y, char r, char g, char b) {
  assert(x >= 0 && x < XRES);
  assert(y >= 0 && y < YRES);

  // center 640x480 in framebuffer
  x += (vinfo.xres - XRES) / 2;
  y += (vinfo.yres - YRES) / 2;
  char *addr = fbp + (x + vinfo.xoffset) * (vinfo.bits_per_pixel / 8) +
               (y + vinfo.yoffset) * finfo.line_length;
  // BGRA
  *(addr++) = b;
  *(addr++) = g;
  *(addr++) = r;
  *(addr++) = 0;
}

int32_t read_pixel(int x, int y) {
  assert(x >= 0 && x < XRES);
  assert(y >= 0 && y < YRES);

  // center 640x480 in framebuffer
  x += (vinfo.xres - XRES) / 2;
  y += (vinfo.yres - YRES) / 2;
  char *addr = fbp + (x + vinfo.xoffset) * (vinfo.bits_per_pixel / 8) +
               (y + vinfo.yoffset) * finfo.line_length;

  unsigned char b = *(addr++);
  unsigned char g = *(addr++);
  unsigned char r = *(addr++);
  unsigned char a = *(addr++);
  return (r << 16) | (g << 8) | b;
}

void clear_screen() {
  for (int32_t x = 0; x < XRES; x++)
    for (int32_t y = 0; y < YRES; y++)
      write_pixel(x, y, 0, 0, 0);
}

void wait_for_vsync() {
  // msync(fbp, fb_size, MS_SYNC);
  double unlocked_fps = (double)CLOCKS_PER_SEC / (clock() - frame_start);
  while (clock() - frame_start < CLOCKS_PER_SEC / MAX_FPS) {
  }
  double locked_fps = (double)CLOCKS_PER_SEC / (clock() - frame_start);

  printf("\r%.2f fps (locked to %.2f)", unlocked_fps, locked_fps);
  fflush(stdout);

  frame_start = clock();
}

void demo() {
  clock_t start = clock();
  long int iteration = 0;
  while (clock() - start < 10 * CLOCKS_PER_SEC) {
    for (int y = 0; y < YRES; y++) {
      for (int x = 0; x < XRES; x++) {
        char b = (iteration - x * x / 256) % 256;
        char g = (iteration - x * y / 256) % 256;
        char r = (iteration - y * y / 256) % 256;
        write_pixel(x, y, r, g, b);
      }
    }
    wait_for_vsync();
    iteration++;
  }
}
