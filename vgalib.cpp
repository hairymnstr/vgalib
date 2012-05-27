//     VGAlib
//     For ChipKIT UNO32
//     Copyright Nathan Dumont 2012
//
//     This program is free software: you can redistribute it and/or modify
//     it under the terms of the GNU General Public License as published by
//     the Free Software Foundation, either version 3 of the License, or
//     (at your option) any later version.
// 
//     This program is distributed in the hope that it will be useful,
//     but WITHOUT ANY WARRANTY; without even the implied warranty of
//     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//     GNU General Public License for more details.
// 
//     You should have received a copy of the GNU General Public License
//     along with this program.  If not, see <http://www.gnu.org/licenses/>.

#include <plib.h>
#include "vgalib.h"
#include "WProgram.h"

#define HSYNC_MASK 0x01
#define VSYNC_MASK 0x02

#define HFRONTP 12
#define HBACKP 33
#define VBACKP 4

#define ROWS 60
#define COLS 80

static char screen[2][60][80];
static char df;
volatile char rf;
static int scanline;

void VGAOutput::begin() {
  TRISECLR = 0xff;
  TRISDCLR = HSYNC_MASK | VSYNC_MASK;
  df = 0;
  rf = 0;
  OC1CON = 0x0000;
  OC1R = 0x083a;
  OC1RS = 0x083a;
  OC1CON = 0x0006;
  PR2 = 0x08A6;
  LATDSET = HSYNC_MASK | VSYNC_MASK;
  IFS0CLR = _IFS0_T2IF_MASK | _IFS0_T3IF_MASK | _IFS0_T4IF_MASK | _IFS0_T5IF_MASK;

  // enable the timers and output compare
  T2CONSET = 0x8000;
  OC1CONSET = 0x8000;

  ConfigIntTimer2((T2_INT_ON | T2_INT_PRIOR_3));
  delay(3000);
  mConfigIntCoreTimer((CT_INT_OFF));
}

void VGAOutput::fill(char val) {
  memset(screen[df^1], val, ROWS * COLS);
}

//Bersenham's Line Algorithm, from Wikipedia
void VGAOutput::line(int x1, int y1, int x2, int y2, char colour) {
  int sx, sy;
  int dx = abs(x2-x1);
  int dy = abs(y2-y1);
  if(x1 < x2)
    sx = 1;
  else
    sx = -1;
  if(y1 < y2)
    sy = 1;
  else
    sy = -1;
  int err = dx - dy;
  while(1) {
    setPixel(x1, y1, colour);
    if((x1 == x2) && (y1 == y2)) {
      break;
    }
    int e2 = err * 2;
    if(e2 > -dy) {
      err -= dy;
      x1 += sx;
    }
    if(e2 < dx) {
      err += dx;
      y1 += sy;
    }
  }
}

void VGAOutput::setPixel(int x, int y, char colour) {
  screen[df^1][y][x] = colour;
}

void VGAOutput::flip() {
  volatile char *dfl = &df;
  rf ^= 1;
  while(rf != (*dfl)) {;}
}

void VGAOutput::blit(int x, int y, int width, int height, const char *data) {
  for(int i=0;i<height;i++) {
    memcpy(&screen[df^1][i+y][x],&data[i*width],width);
  }
}

// interrupt functions have to be C functions
#ifdef __cplusplus
extern "C" {
#endif

void __ISR(_TIMER_2_VECTOR, IPL3AUTO) scanline_handler(void) {
  int i=0;
  // keep track of how far down the screen we've got
  scanline++;
  if(scanline < 480) {
    // front porch
    for(int i=0;i<HFRONTP;i++) {
      __asm__("nop\n\t");
    }

    // main display
    for(int i=0;i<80;i++) {
      LATE = screen[df][scanline/8][i];
      __asm__("nop\n\t");
      __asm__("nop\n\t");
      __asm__("nop\n\t");
      __asm__("nop\n\t");
      __asm__("nop\n\t");
      __asm__("nop\n\t");
      __asm__("nop\n\t");
      __asm__("nop\n\t");
      __asm__("nop\n\t");
      __asm__("nop\n\t");
      __asm__("nop\n\t");
      __asm__("nop\n\t");
      __asm__("nop\n\t");
      __asm__("nop\n\t");
      __asm__("nop\n\t");
    }
  
    // back porch
    LATE = 0;
  } else if(scanline == (480 + VBACKP)) {
    LATDCLR = VSYNC_MASK;
  } else if(scanline == (482 + VBACKP)) {
    LATDSET = VSYNC_MASK;
  } else if(scanline == 526) {
    scanline = -1;
    if(df != rf) {
      df = rf;
    }
  }
  
  // make sure all the timer interrupt flags are clear and ready to trigger
  // again
  IFS0CLR = _IFS0_T2IF_MASK;
}


#ifdef __cplusplus
}
#endif