
// * ------------------ HOT KEYS ------------------

final char Z_IN       = 'c'; // Horizontal zoom in
final char Z_OUT      = 'z'; //                 out

// * ----------------------------------------------

// * --------------- STARTING STATE ---------------
float zoom    = 6.0;
float scale   = 1.5;
int com_port  = 2;   // Index number in Serial.list
// * ----------------------------------------------

// Global vars
import processing.serial.*;
Serial port;                    // Create object from Serial class
int val;                        // Data received from the serial port
long valTime;                   // Time data was received
int[] values;
long[] times;
float voltage;
float measTime = 0;
int   timeMode = 0;
int[] timeBars = {0, 0};
PFont f;
PImage bg;    // Background image 
PImage bg2;  // 2nd background imag
boolean pause;
int circleX, circleY;  // Position of circle button
int circleSize = 15;   // Diameter of circle
color circleColor, baseColor;
color circleHighlight;
color currentColor;
boolean circleOver = false;
int bg_counter = 0;
int count = 0;

// Setup
void setup() {
  size(1280, 480);
  port = new Serial(this, Serial.list()[com_port], 9600);    // Com port specified here
  values = new int[width];
  times = new long[width];
  timeBars[0] = width/3;
  timeBars[1] = 2*width/3;
  pause = false;
  smooth();
  f = createFont("Arial", 16, true);
    // Load an image for the background  (picture of an oscilloscope)
  bg = loadImage("oscilloscope_2.png");
  bg2 = loadImage("oscilloscope_3.png");
  
  circleColor = color(255);
  circleHighlight = color(204);
  baseColor = color(102);
  currentColor = baseColor;
  circleX = 1000;
  circleY = 430;
  ellipseMode(CENTER);
}

// Read value from serial stream
int getValue() {
  int value = -1;
  while (port.available () >= 3) {
    if (port.read() == 0xff) {
      value = (port.read() << 8) | (port.read());
    }
  }
  return value;
}

// Get a y-value for the datapoint, varies based on axis settings
int getY(int val) {
  return (int)(height/2 -(val+33)*scale / 1023.0f * (height - 1));
}

// Push the values in the data array
void pushValue(int value) {
  for (int i=0; i<width-1; i++)
    values[i] = values[i+1];
  values[width-1] = value;
}

// Push the timestamps in the time array
void pushTime(long time) {
  for (int i=0; i<width-1; i++)
    times[i] = times[i+1];
  times[width-1] = time;
}

// Draw waveform
void drawLines() {
  if(bg_counter == 0){
    stroke(0,255,255);
    fill(255);
  }
  if(bg_counter == 1){
    stroke(41,4,251);
    fill(0);
  }
  int x0 = 0, x1 = 0, y0 = 0, y1 = 0;
  
  
  //stroke(255,255,0);
  for (int i=0; i<width; i++) {
    x1 = round(width - ((width-i) * zoom));
    y1 = getY(values[i]);
    if(i > 1)
      line(x0, y0, x1, y1);
    x0 = x1;
    y0 = y1;
  }
  String s = "Current voltage value:"; 
    textSize(19);
    text(s,100,400);
    
    String d = "Press this button to change the background";
    textSize(15);
    text(d, 935, 460);
    
    String y = "c key zooms in";
    text(y, 5, 440);
    
    String x = "z key zooms out";
    text(x, 5, 460);

}

// Truncate a floating point number
float truncate(float x, int digits) {
  float temp = pow(10.0, digits);
  return round( x * temp ) / temp;
}

// When a key is released...
void keyReleased() {
  println(key+": "+(int)key);
  switch (key) {
  case Z_IN:                                                 // Zoom horizontal
    zoom *= 2.0f;
    if ( (int) (width / zoom) <= 1 )
      zoom /= 2.0f;
    break;
  case Z_OUT:                                                // Zoom horizontal
    zoom /= 2.0f;
    if (zoom < 1.0f)
      zoom *= 2.0f;
    break;
  }
}

// Use mouse clicks to quickly move vertical bars (if highlighted)

// Primary drawing function
void draw()
{
  if(bg_counter == 0)
  background(bg);
  else if(bg_counter ==1)
  background(bg2);
  // Get current voltage, time of reading
  val = getValue();
  valTime = System.nanoTime();
  
  // If not paused
  if (!pause && val != -1) {
    // Push value/time onto array
    pushValue(val);
    pushTime(valTime);
    
    // Print current voltage reading
    textFont(f, 16);
    fill(204, 102, 0);
    voltage = truncate(5.0*val / 1023, 1);
    displayVoltage(voltage);
   

  }
  drawLines();
  
   update(mouseX, mouseY);
 
  if (circleOver) {
    fill(circleHighlight);
  } else {
    fill(circleColor);
  }
  stroke(0);
  ellipse(circleX, circleY, circleSize, circleSize);
}
void displayVoltage(float voltage){
 
    String s = "Current voltage value:"+voltage; 
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