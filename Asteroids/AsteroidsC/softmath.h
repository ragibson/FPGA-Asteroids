/*
 *  Implements fixed-point arithmetic with 6 bits for the decimal part and 10
 *  bits for the integer part (referred to as fp16_t).
 *
 *  This effectively lets the game perform calculations on each pixel at the
 *  level of 64x64 subpixels.
 *
 *  Integer and fixed-point multiplication/division are implemented in software.
 *
 *  A lookup table for cosine is used to compute sine and cosine for fp16_t.
 */

#include <assert.h>
#include <stdint.h>
#include <stdio.h>

typedef int32_t fp16_t;
#define FP_SHIFT_AMOUNT 6
#define FP_ROUND_MASK 1 << (FP_SHIFT_AMOUNT - 1)
#define FP_FRAC_MASK (1 << FP_SHIFT_AMOUNT) - 1

#define INT_TO_FP(x) (x << FP_SHIFT_AMOUNT)
#define FP_IPART(x) (x >> FP_SHIFT_AMOUNT)
#define FP_FPART(x) (x & FP_FRAC_MASK)

// lookup table for cos(d), 0 <= d < 360 (values in fp16_t)
fp16_t fpcos_table[360] = {
    64,  64,  64,  64,  64,  64,  64,  64,  63,  63,  63,  63,  63,  62,  62,
    62,  62,  61,  61,  61,  60,  60,  59,  59,  58,  58,  58,  57,  57,  56,
    55,  55,  54,  54,  53,  52,  52,  51,  50,  50,  49,  48,  48,  47,  46,
    45,  44,  44,  43,  42,  41,  40,  39,  39,  38,  37,  36,  35,  34,  33,
    32,  31,  30,  29,  28,  27,  26,  25,  24,  23,  22,  21,  20,  19,  18,
    17,  15,  14,  13,  12,  11,  10,  9,   8,   7,   6,   4,   3,   2,   1,
    0,   -1,  -2,  -3,  -4,  -6,  -7,  -8,  -9,  -10, -11, -12, -13, -14, -15,
    -17, -18, -19, -20, -21, -22, -23, -24, -25, -26, -27, -28, -29, -30, -31,
    -32, -33, -34, -35, -36, -37, -38, -39, -39, -40, -41, -42, -43, -44, -44,
    -45, -46, -47, -48, -48, -49, -50, -50, -51, -52, -52, -53, -54, -54, -55,
    -55, -56, -57, -57, -58, -58, -58, -59, -59, -60, -60, -61, -61, -61, -62,
    -62, -62, -62, -63, -63, -63, -63, -63, -64, -64, -64, -64, -64, -64, -64,
    -64, -64, -64, -64, -64, -64, -64, -64, -63, -63, -63, -63, -63, -62, -62,
    -62, -62, -61, -61, -61, -60, -60, -59, -59, -58, -58, -58, -57, -57, -56,
    -55, -55, -54, -54, -53, -52, -52, -51, -50, -50, -49, -48, -48, -47, -46,
    -45, -44, -44, -43, -42, -41, -40, -39, -39, -38, -37, -36, -35, -34, -33,
    -32, -31, -30, -29, -28, -27, -26, -25, -24, -23, -22, -21, -20, -19, -18,
    -17, -15, -14, -13, -12, -11, -10, -9,  -8,  -7,  -6,  -4,  -3,  -2,  -1,
    0,   1,   2,   3,   4,   6,   7,   8,   9,   10,  11,  12,  13,  14,  15,
    17,  18,  19,  20,  21,  22,  23,  24,  25,  26,  27,  28,  29,  30,  31,
    32,  33,  34,  35,  36,  37,  38,  39,  39,  40,  41,  42,  43,  44,  44,
    45,  46,  47,  48,  48,  49,  50,  50,  51,  52,  52,  53,  54,  54,  55,
    55,  56,  57,  57,  58,  58,  58,  59,  59,  60,  60,  61,  61,  61,  62,
    62,  62,  62,  63,  63,  63,  63,  63,  64,  64,  64,  64,  64,  64,  64};

int32_t imult(int32_t a, int32_t b) {
  int32_t neg_result = (a < 0) ^ (b < 0);
  if (a < 0)
    a = -a;
  if (b < 0)
    b = -b;

  int32_t res = 0;
  while (b > 0) {
    if (b & 1) {
      res += a;
    }
    a <<= 1;
    b >>= 1;
  }

  if (neg_result)
    res = -res;
  return res;
}

int32_t idiv(int32_t a, int32_t b) {
  assert(b > 0);
  int32_t neg_result = a < 0;
  if (neg_result)
    a = -a;

  int32_t place = 1;
  int32_t res = 0;
  while (a >= b) {
    place <<= 1;
    b <<= 1;
  }
  while (place > 0) {
    if (a >= b) {
      a -= b;
      res += place;
    }
    place >>= 1;
    b >>= 1;
  }

  if (neg_result)
    res = -res;
  return res;
}

int32_t round_fp_to_int(fp16_t a) {
  int32_t res = a >> FP_SHIFT_AMOUNT;
  if (a & FP_ROUND_MASK) {
    res++;
  }
  return res;
}

int32_t abs(int32_t a) {
  if (a < 0)
    a = -a;
  return a;
}

fp16_t fpmult(fp16_t a, fp16_t b) { return imult(a, b) >> FP_SHIFT_AMOUNT; }

fp16_t fpdiv(fp16_t a, fp16_t b) { return idiv(a << FP_SHIFT_AMOUNT, b); }

void mod(fp16_t *x, fp16_t m) {
  if (*x >= m)
    *x -= m;
  else if (*x < 0)
    *x += m;
}

fp16_t fpcos(fp16_t degrees) {
  int32_t ideg = round_fp_to_int(degrees);
  mod(&ideg, 360);
  return fpcos_table[ideg];
}

fp16_t fpsin(fp16_t degrees) { return fpcos(degrees - INT_TO_FP(90)); }
