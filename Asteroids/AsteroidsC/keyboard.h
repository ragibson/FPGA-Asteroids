#include <stdio.h>
#include <stdlib.h>
#include <sys/ioctl.h>
#include <termios.h>
#include <unistd.h>

struct termios original_attr;

void cleanup_keyboard() { tcsetattr(0, TCSADRAIN, &original_attr); }

void setup_keyboard() {
  struct termios term;
  tcgetattr(0, &original_attr);
  term = original_attr;

  cfmakeraw(&term);
  tcsetattr(0, TCSANOW, &term);
  atexit(cleanup_keyboard);
}

int kbhit() {
  struct timeval tv = {0L, 0L};
  fd_set fds;
  FD_ZERO(&fds);
  FD_SET(0, &fds);
  return select(1, &fds, NULL, NULL, &tv);
}

char read_keyboard() {
  if (!kbhit()) {
    return 0;
  } else {
    char c;
    if (read(0, &c, 1) == -1) {
      fprintf(stderr, "Error reading from keyboard.\n");
      exit(1);
    }
    return c;
  }
}
