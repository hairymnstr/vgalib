#include <vgalib.h>
VGAOutput screen;

#define COUNTDOWN 1
#define IN_GAME 2
#define GAME_OVER 3

// game over screen QR code and game over words as bit maps
extern const char qr[];
extern int qrheight;
extern int qrwidth;
extern const char im[];
extern int imwidth;
extern int imheight;

// global variables
int bat1;		// position of player 1's bat in scanlines
int bat2;		// position of player 2's bat in scanlines
int batHeight;
int LED;
int ball;		// vertical position of the bat in  scanlines
int ball_x;	// horizontal position of the ball
int ball_x_dir;	// direction and speed of the ball in X axis
int ball_y_dir;	// direction and speed of the ball in Y axis
int player1_score;	// player 1 score
int player2_score;	// player 2 score
int p;		// keep track of which player's score is displayed
int state;              // game state (countdown, playing or over)
int count;              // used to count down for the start

void setup() {
  batHeight = 5;        // length of the player's bat
  screen.begin();       // initialise the VGA driver
  ball = 300;		// start in centre like a serve

  ball_x = 400;         // somewhere near the middle of the screen
  ball_x_dir = 3;	// start with a straight serve
  ball_y_dir = 0;

  // digital pins 11 and 12 are the enable lines for the two
  // 7seg displays any lines are fine but don't use PWM pins!
  pinMode(11, OUTPUT);
  digitalWrite(11, HIGH);
  pinMode(12, OUTPUT);
  digitalWrite(12, LOW);
  
  // digital pins 34-40 are the bits for the 7seg
  pinMode(34, OUTPUT);
  pinMode(35, OUTPUT);
  pinMode(36, OUTPUT);
  pinMode(37, OUTPUT);
  pinMode(38, OUTPUT);
  pinMode(39, OUTPUT);
  pinMode(40, OUTPUT);

  p = 0;                // player who's score is being refreshed
  state = COUNTDOWN;    // start with a countdown
  count = 1000;         // count 1000 frames before playing
}

void sevenseg(int score) {
  // base 10 seven segment driver with arduino abstraction
  score = score % 10;	// make sure the number is between 0 and 9
  
  // switch based on the score
  switch(score) {
    case 0:
      // all segments except the centre
      digitalWrite(34, LOW);
      digitalWrite(35, HIGH);
      digitalWrite(36, HIGH);
      digitalWrite(37, HIGH);
      digitalWrite(38, HIGH);
      digitalWrite(39, HIGH);
      digitalWrite(40, HIGH);
      return;
    case 1:
      digitalWrite(34, LOW);
      digitalWrite(35, HIGH);
      digitalWrite(36, HIGH);
      digitalWrite(37, LOW);
      digitalWrite(38, LOW);
      digitalWrite(39, LOW);
      digitalWrite(40, LOW);
      return;
    case 2:
      digitalWrite(34, HIGH);
      digitalWrite(35, HIGH);
      digitalWrite(36, LOW);
      digitalWrite(37, HIGH);
      digitalWrite(38, HIGH);
      digitalWrite(39, LOW);
      digitalWrite(40, HIGH);
      return;
    case 3:
      digitalWrite(34, HIGH);
      digitalWrite(35, HIGH);
      digitalWrite(36, HIGH);
      digitalWrite(37, HIGH);
      digitalWrite(38, LOW);
      digitalWrite(39, LOW);
      digitalWrite(40, HIGH);
      return;
    case 4:
      digitalWrite(34, HIGH);
      digitalWrite(35, HIGH);
      digitalWrite(36, HIGH);
      digitalWrite(37, LOW);
      digitalWrite(38, LOW);
      digitalWrite(39, HIGH);
      digitalWrite(40, LOW);
      return;
    case 5:
      digitalWrite(34, HIGH);
      digitalWrite(35, LOW);
      digitalWrite(36, HIGH);
      digitalWrite(37, HIGH);
      digitalWrite(38, LOW);
      digitalWrite(39, HIGH);
      digitalWrite(40, HIGH);
      return;
    case 6:
      digitalWrite(34, HIGH);
      digitalWrite(35, LOW);
      digitalWrite(36, HIGH);
      digitalWrite(37, HIGH);
      digitalWrite(38, HIGH);
      digitalWrite(39, HIGH);
      digitalWrite(40, HIGH);
      return;
    case 7:
      digitalWrite(34, LOW);
      digitalWrite(35, HIGH);
      digitalWrite(36, HIGH);
      digitalWrite(37, LOW);
      digitalWrite(38, LOW);
      digitalWrite(39, LOW);
      digitalWrite(40, HIGH);
      return;
    case 8:
      digitalWrite(34, HIGH);
      digitalWrite(35, HIGH);
      digitalWrite(36, HIGH);
      digitalWrite(37, HIGH);
      digitalWrite(38, HIGH);
      digitalWrite(39, HIGH);
      digitalWrite(40, HIGH);
      return;
    case 9:
      digitalWrite(34, HIGH);
      digitalWrite(35, HIGH);
      digitalWrite(36, HIGH);
      digitalWrite(37, HIGH);
      digitalWrite(38, LOW);
      digitalWrite(39, HIGH);
      digitalWrite(40, HIGH);
      return;
    default:
      // in case of an error just draw a dash.
      // should never get here
      digitalWrite(34, LOW);
      digitalWrite(35, HIGH);
      digitalWrite(36, LOW);
      digitalWrite(37, LOW);
      digitalWrite(38, LOW);
      digitalWrite(39, LOW);
      digitalWrite(40, LOW);
      return;
  }
}
      
void loop() {
  if(state == COUNTDOWN) {
    // draw the bats so players can get an idea how the controls work
    bat1 = analogRead(0) * (60 - batHeight) / 1024;
    bat2 = analogRead(1) * (60 - batHeight) / 1024;
    
    // fill with green background
    screen.fill(0x04);
    screen.line(2, bat1, 2, bat1+batHeight-1, 0x1f);
    screen.line(77, bat2, 77, bat2+batHeight-1, 0x3f);
    // draw a number
    if(count-- < 300) {
      drawOne();
    } else if(count-- < 600) {
      drawTwo();
    } else if(count-- < 900) {
      drawThree();
    }
    // switch frame buffers
    screen.flip();
    // start the game
    if(count == 0) {
      state= IN_GAME;
    }
  } else if(state == IN_GAME) {
    // read user input
    bat1 = analogRead(0) * (60 - batHeight) / 1024;
    bat2 = analogRead(1) * (60 - batHeight) / 1024;
    
    // vertical motion of the ball, just invert the vertical component if
    // it gets to the top or bottom of the screen.
    ball += ball_y_dir;
    if(ball >= 590) {
      ball_y_dir *= -1;
    } else if (ball <= 0) {
      ball_y_dir *= -1;
    }

    // horizontal motion of the ball.  Need to decide if it hit a bat or not
    ball_x += ball_x_dir;
    if(ball_x >= 770) {
      if((((ball+5)/10) >= bat2) && (((ball+5)/10) < (bat2 + batHeight))) {
        // ball hit bat2
        ball_x_dir *=-1;          // just reflect it for now
        // this makes it bounce off up or down the screen depending on
        // where you hit it
        ball_y_dir = (((ball+5)/10) - bat2 - (batHeight / 2));
      } else {
        // player 2 missed the ball, increment player 1's score
        player1_score++;
        // reset the ball to the centre of the screen player 1 serves
        ball_x_dir = 3;
        ball_y_dir = 0;
        ball_x = 400;
        ball = 300;
      }
    } else if(ball_x <= 30) {
      if((((ball+5)/10) >= bat1) && (((ball+5)/10) < (bat1 + batHeight))) {
        // ball hit bat1
        ball_x_dir *=-1;
        ball_y_dir = (((ball+5)/10) - bat1 - (batHeight / 2));
      } else {
        // player 1 missed the ball, give player 2 the points and serve
        player2_score++;
        ball_x_dir = -3;
        ball_y_dir = 0;
        ball_x = 400;
        ball = 300;
      }
    }
    
    // wipe out whatever is in the frame buffer
    screen.fill(0x04);
    // draw the bats
    screen.line(2, bat1, 2, bat1+batHeight-1, 0x1f);
    screen.line(77, bat2, 77, bat2+batHeight-1, 0x3f);
    // draw the ball
    screen.setPixel((ball_x+5)/10, (ball+5)/10, 0xf0);
    // switch frame buffers
    screen.flip();
    // end the game if one of the players has reached the score limit
    if((player1_score == 3) || (player2_score == 3)) {
      state = GAME_OVER;
    }
  } else if(state == GAME_OVER) {
    // just draw the game over screen over whatever was there before
    drawGameOver();
    // swap buffers
    screen.flip();
  }
  // see which of the players score to show this time
  if(p % 2) {
    // enable player 1's 7seg display and disable player 2's
    digitalWrite(11, HIGH);
    digitalWrite(12, LOW);
    // drive the score onto player 1's display
    sevenseg(player1_score);
  } else {
    // enable player 2's 7seg display and disable player 2's
    digitalWrite(11, LOW);
    digitalWrite(12, HIGH);
    // drive the score onto player 2's display
    sevenseg(player2_score);
  }
  // toggle the lsb of p to alternate who gets the score next time
  p^=1;
//   for(int i=0; i< 30000;i++) {__asm__("nop\n\t");}
}

void drawOne() {
  screen.line(40,10, 40, 50, 0xe0);
}

void drawTwo() {
  screen.line(20,10,60,10,0xe0);
  screen.line(60,10,60,30,0xe0);
  screen.line(20,30,60,30,0xe0);
  screen.line(20,30,20,50,0xe0);
  screen.line(20,50,60,50,0xe0);
}

void drawThree() {
  screen.line(20,10,60,10,0xe0);
  screen.line(60,10,60,30,0xe0);
  screen.line(20,30,60,30,0xe0);
  screen.line(60,30,60,50,0xe0);
  screen.line(20,50,60,50,0xe0);
}

void drawGameOver() {
  screen.blit(24,0,qrwidth,qrheight,qr);
  screen.blit(20,35,imwidth,imheight,im);
}
