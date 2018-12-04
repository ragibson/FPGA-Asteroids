# CPU Design

This CPU was designed for the Nexys 4 (Xilinx part number XC7A100T-1CSG324C,
Vivado part number xc7a100tcsg324-1), but should work on any FPGA with
sufficient resources.

# Table of Contents
  * [FPGA Requirements](#FPGARequirements)
  * [Instruction Set](#InstructionSet)
  * [Memory Map](#MemoryMap)
  * [Differences with the Asteroids CPU](#AsteroidsDifferences)

<a name = "FPGARequirements"></a>
## FPGA Requirements

For the Asteroids game in particular, the FPGA needs enough logic blocks for
  * The hardware to implement the CPU and I/O
  * 5 KiB of instruction memory
  * ~3.5 KiB of data memory
  * 75 KiB of VGA framebuffer (2bpp palette)

On the Nexys 4, this amounts to ~2500 Lookup tables, ~500 flip-flops, and 20
Block RAMs.

Buttons/switches for resetting the game and switching the CPU clock rate are
optional, but recommended. The Asteroids game uses one button and four switches.

See the [Asteroids README](../Asteroids/README.md) for more information.

<a name = "InstructionSet"></a>
## Instruction Set

The CPU supports the following 28 instructions from the MIPS instruction set.

  |Instruction|Description                         |Instruction|Description                          |
  |-----------|------------------------------------|-----------|-------------------------------------|
  |add        |Add (with overflow)                 |or         |Bitwise OR                           |
  |addi       |Add immediate (with overflow)       |ori        |Bitwise OR immediate                 |
  |addiu      |Add immediate unsigned (no overflow)|sll        |Shift left logical                   |
  |addu       |Add unsigned (no overflow)          |sllv       |Shift left logical variable          |
  |and        |Bitwise AND                         |slt        |Set on less than (signed)            |
  |andi       |Bitwise AND immediate               |slti       |Set on less than immediate (signed)  |
  |beq        |Branch on equal                     |sltiu      |Set on less than immediate (unsigned)|
  |bne        |Branch on not equal                 |sltu       |Set on less than (unsigned)          |
  |j          |Jump (unconditionally)              |sra        |Shift right arithmetic               |
  |jal        |Jump and link                       |srl        |Shift right logical                  |
  |jr         |Jump register                       |sub        |Subtract                             |
  |lui        |Load upper immediate                |sw         |Store word                           |
  |lw         |Load word                           |xor        |Bitwise XOR                          |
  |nor        |Bitwise NOR                         |xori       |Bitwise XOR immediate                |

<a name = "MemoryMap"></a>
## Memory Map

The CPU uses the following memory mapping for its memories and I/O devices.

  |Memory or I/O device  |Address   |
  |----------------------|----------|
  |instruction memory    |0x00400000|
  |data memory           |0x10010000|
  |screen memory         |0x10020000|
  |keyboard              |0x10030000|
  |accelerometer         |0x10030004|
  |sound                 |0x10030008|
  |LED lights            |0x1003000c|

<a name = "AsteroidsDifferences"></a>
## Differences with the Asteroids CPU

The Asteroids game requires a few tweaks to the CPU. Namely, it
  * Replaces the 16x16 pixel sprite-based (terminal) display with one that
    allows direct pixel manipulation
  * Tweaks the memory map (adds in vsync signal, global cycle count, and moves
    screen memory)

See the [Asteroids README](../Asteroids/README.md) for more information.

