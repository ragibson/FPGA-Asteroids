# FPGA-Asteroids

![Asteroids screenshot](Asteroids/screenshot.png?raw=true "Asteroids")

This repository contains a CPU design for use on FPGAs and a clone of the
Asteroids arcade game (written in assembly by hand) that runs on the CPU.

## CPU Design

In short, the CPU is a 32-bit single cycle processor and supports
  * A subset of the MIPS instruction set
  * Accelerometer input
  * Keyboard input
  * VGA display output (640x480 @ 60 Hz)
  * Mono audio output
  * LED lights output
  * 7-segment display output
  
More information can be found in the [CPU README](CPU/README.md).

## Asteroids

The assembly version runs on the CPU clocked at 100 MHz (with support for
on-the-fly underclocking to 25 or 50 MHz to demonstrate VBLANK).

A prototype written in C that writes directly to the Linux framebuffer is also
available.

More information can be found in the [Asteroids README](Asteroids/README.md).
