# Palette colors
.eqv BLACK          0
.eqv WHITE          1
.eqv GRAY           2
.eqv ORANGE         3

# reset signal sets PC to TEXT_START
.eqv TEXT_START     0x00400000

.eqv DATA_START     0x10010000
.eqv DATA_END       0x100107fc

# fpcos lookup table starts immediately after data
.eqv TABLE_START    0x10010800

# Memory-mapped IO addresses
.eqv keyboard_addr  0x10030000
.eqv accel_addr     0x10030004
.eqv sound_addr     0x10030008
.eqv lights_addr    0x1003000c
.eqv vsync_addr     0x10020000
.eqv counter_addr   0x10020004
.eqv screen_base    0x20000000

# Scancodes
.eqv W_PRESSED      0x1d
.eqv A_PRESSED      0x1c
.eqv S_PRESSED      0x1b
.eqv D_PRESSED      0x23

# 800000 * 10 ns -> 125 Hz for 1 frame
.eqv W_SOUND        800000
.eqv W_SOUNDLEN     1

# 227273 * 10 ns -> 440 Hz for 6 frames
.eqv S_SOUND        227273
.eqv S_SOUNDLEN     6

# 454545 * 10 ns -> 220 Hz for 6 frames
.eqv DEST_SOUND     454545
.eqv DEST_SOUNDLEN  6

# Ship speed and deceleration
.eqv W_SPEED        16
.eqv SLOWDOWN       65

# Shot speed (added to ship speed)
.eqv SHOT_SPEED     192

# Shots disappear after 120 frames
.eqv TWO_SECONDS    120

.eqv MAX_SHOTS      5
.eqv MAX_ASTEROIDS  4

.eqv ASTEROID_WIDTH 10
.eqv FP_AST_WIDTH   640
.eqv FP_NAST_WIDTH  -640

# Size of point struct
.eqv POINT_BYTES    20

# point struct offsets
.eqv POINT_X        0
.eqv POINT_Y        4
.eqv POINT_VX       8
.eqv POINT_VY       12
.eqv POINT_TIMEOUT  16

# Each shot struct uses 5 words -> 100 bytes
.eqv SHOT_BYTES     100

# Size of object struct
.eqv OBJECT_BYTES   28

# object struct offsets
.eqv OBJECT_X       0
.eqv OBJECT_Y       4
.eqv OBJECT_DEGREES 8
.eqv OBJECT_VX      12
.eqv OBJECT_VY      16
.eqv OBJECT_VD      20
.eqv OBJECT_SIZE    24

# Each object struct uses 7 words -> 224 bytes
.eqv ASTEROID_BYTES 224

# 640x480 words -> 1228800 bytes
.eqv SCREEN_BYTES   1228800

# Screen resolution
.eqv XRES           640
.eqv YRES           480
.eqv FP_XRES        40960
.eqv FP_YRES        30720
.eqv FP_HALF_XRES   20480
.eqv FP_HALF_YRES   15360

# Fixed-point representation constants
.eqv FP_SHIFT_AMOUNT 6     # 6 bits of decimal
.eqv FP_ROUND_MASK   0x20  # 0x20 = 0b100000 = 0.5
.eqv FP_FRAC_MASK    0x3f  # 0x3f = 0b111111

# Fixed-point arithmetic constants
.eqv FP_N12         -768
.eqv FP_N10         -640
.eqv FP_N7          -448
.eqv FP_N6          -384
.eqv FP_N5          -320
.eqv FP_N4          -256
.eqv FP_N1          -64
.eqv FP_0           0
.eqv FP_1           64
.eqv FP_2           128
.eqv FP_3           192
.eqv FP_4           256
.eqv FP_5           320
.eqv FP_6           384
.eqv FP_7           448
.eqv FP_10          640
.eqv FP_12          768
.eqv FP_50          3200
.eqv FP_90_DEG      5760
.eqv FP_100         6400
.eqv FP_200         12800
.eqv FP_300         19200
.eqv FP_360         23040
.eqv FP_400         25600
.eqv FP_600         38400
