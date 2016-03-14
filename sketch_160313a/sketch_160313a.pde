  /*
 * Oscilloscope
 * Gives a visual rendering of analog pin 0 in realtime.
 * 
 * This project is part of Accrochages
 * See http://accrochages.drone.ws
 * 
 * (c) 2008 Sofian Audry (info@sofianaudry.com)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */ 
import processing.serial.*;

Serial port;  // Create object from Serial class
int val;      // Data received from the serial port
int[] values;
float zoom;
PImage bg;    // Background image 
PImage bg2;  // 2nd background image
int count = 0;



// Variables for the button to zoom in the oscilloscope
int circleX, circleY;  // Position of circle button
int circleSize = 15;   // Diameter of circle
color circleColor, baseColor;
color circleHighlight;
color currentColor;
boolean circleOver = false;
int bg_counter = 0;



void setup() 
{
  // Set the window size to a width of 1280 pixels and length of 480 pixels
  size(1280, 480);
  
  // Load an image for the background  (picture of an oscilloscope)
  bg = loadImage("oscilloscope_2.png");
  bg2 = loadImage("oscilloscope_3.png");
 
  // Open the port that the board is connected to and use the same speed (9600 bps)
  port = new Serial(this, Serial.list()[0], 4800);
  
  // Declare an array of the values with the width of the display window (size of 1280)
  values = new int[width];
 
  // Set the zoom in to 1.0
  zoom = 10.0f;
  
  // Run the smooth function so all lines drawn are anti-aliased 
  smooth(8);
  
  // Set up the button to zoom-in
  circleColor = color(255);
  circleHighlight = color(204);
  baseColor = color(102);
  currentColor = baseColor;
  circleX = 1000;
  circleY = 430;
  ellipseMode(CENTER);
}

int getY(int val) {
  
  // Returns a value for the y-axis (voltage) by a formula computation
  // val / 1023.0f = conversion from analog value of 0 - 1023.0 into a voltage from 0 - 1
  // the multiplier (height - 1) will convert the voltage from 0 to (height - 1)
  // When subtracted from height, the range on the y-axis maps from 1 to the height of the screen
  
  //return (int)(height/2 - val / 1023.0f * (height - 1));
  
    // For background-2
    return (int)(height/2.2 - val / 1023.0f * 1000);
}


// This function retrieves the value from the serial port

int getValue() {
  
  
  int value = -1;
  while (port.available() >= 3) {
   if (port.read() == 0xff) {
     value = (port.read() << 8) | (port.read());
   }
  }
  return value;
  
  //int value = -1;
  // // get the ASCII string:
  //String inString = port.readStringUntil('\n');

  //if (inString != null) {
  //  // trim off any whitespace:
  //  inString = trim(inString);
  //  // convert to an int and map to the screen height:
  //  value = int(inString);
  //}
  //return value;
  
  
}

void pushValue(int value) {
  for (int i=0; i<width-1; i++)
    values[i] = values[i+1];
    values[width-1] = value;
  
  
}

void drawLines() {
 
  if(bg_counter == 0){
    stroke(255);
    fill(255);
  }
  if(bg_counter == 1){
    stroke(0);
    fill(0);
  }
  
  int displayWidth = (int) (width / zoom);
  
  int k = values.length - displayWidth;
  int x0 = 0;
  int y0 = getY(values[k]);
  for (int i=1; i<displayWidth; i++) {
    k++;
                                    // horizontal positioning of the screen
    int x1 = (int) (i * (width-1) / (displayWidth-1));
    int y1 = getY(values[k]);
    line(x0, y0, x1, y1);
    x0 = x1;
    y0 = y1;
    
    // Increment the counter for the display
    count++;
    if(count == 1000){
      displayVoltage(y1);
      count = 0;
    }
    
  }
  
    String s = "Current voltage value:"; 
    textSize(19);
    text(s,100,400);
    
    String d = "Press this button to change the background";
    textSize(15);
    text(d, 935, 460);
    
    String y = "+ key zooms in";
    text(y, 5, 440);
    
    String x = "- key zooms out";
    text(x, 5, 460);
    
}

void drawGrid() {
  stroke(255, 0, 0);
  line(0, height/2, width, height/2);

}

void keyReleased() {
  switch (key) {
    case '+':
      zoom *= 2.0f;
      println(zoom);
      if ( (int) (width / zoom) <= 1 )
        zoom /= 2.0f;
      break;
    case '-':
      zoom /= 2.0f;
      if (zoom < 1.0f)
        zoom *= 2.0f;
      break;
  }
  

}


void draw()
{
  // Set the background to the image
  if(bg_counter == 0)
  background(bg);
  else if(bg_counter ==1)
  background(bg2);
  
  
  //drawGrid();
  val = getValue();
  if (val != -1) {
    pushValue(val);
  }
  drawLines();
  
  
  // BUTTON STUFF
  update(mouseX, mouseY);
 
  if (circleOver) {
    fill(circleHighlight);
  } else {
    fill(circleColor);
  }
  stroke(0);
  ellipse(circleX, circleY, circleSize, circleSize);
  

  
}

void displayVoltage(int voltage){
 
    String s = "Current voltage value:"+voltage*5; 
    textSize(19);
    text(s,100,400);

}


void update(int x, int y) {
  if ( overCircle(circleX, circleY, circleSize) ) {
    circleOver = true;

  } else {
    circleOver = false;
  }
}



// This function checks to see if the button is pressed

void mousePressed() {
  if (circleOver && bg_counter == 0) {
    bg_counter++;
  }
  
  else if(circleOver && bg_counter == 1){
    bg_counter = 0;
  }
}

boolean overCircle(int x, int y, int diameter) {
  float disX = x - mouseX;
  float disY = y - mouseY;
  if (sqrt(sq(disX) + sq(disY)) < diameter/2 ) {
    return true;
  } else {
    return false;
  }
}