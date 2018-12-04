# Asteroids

## Buttons/Switches

On the Nexys 4, the Asteroids game maps the inputs as follows:
  * Button E16 (the center one) resets the game
  * Switch U9 (the rightmost one) resets the game (for stability, the game
    should be continually reset while the clock rate is switching)
  * Switches R6, R7, U8 (left-to-right order, all directly left of U9) set the
    clock rate to 100, 50, and 25 MHz, respectively. The highest clock rate
    currently enabled is the one sent to the CPU and synchronous memories

## CPU Tweaks

The Asteroids game requires the following tweaks to the CPU (see CPU.patch).
  * The 16x16 pixel sprite-based (terminal) display is replaced with one that
    allows direct pixel manipulation
  * The dual-ported RAM module used for the framebuffer becomes synchronous read
    so that it can be mapped to the larger block RAMs on the Nexys 4
  * Screen memory (framebuffer) is moved to 0x20000000 to accomodate its larger
    size
  * A vsync signal is mapped to address 0x10020000
  * A global cycle counter (used for RNG) is mapped to address 0x10020004

## C prototype

The C prototype differs from the assembly version in a few key ways.
  * It draws directly to the Linux framebuffer (/dev/fb0). The user must have
    permission to write to the framebuffer and if /dev/fb0 is larger than
    640x480, it will draw to a centered 640x480 "window"
  * It does not support sound, though the code still sets sound periods and
    timeouts
  * It can only read input characters at the keyboard's repeat rate -- the user
    must manually increase the repeat rate and decrease the repeat delay in
    order to accurately mimic the behavior of the FPGA CPU's keyboard behavior
  * It does not correctly implement vsync (since this does not appear to be
    available in all Linux framebuffer implementations). The rendering will be
    locked to 60 fps, but will likely flicker.
  * The code itself breaks some standard programming practices in order to make
    the program easier to assemble (by hand)

