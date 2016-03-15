
// * ------------------ HOT KEYS ------------------
final char T_UP       = 'w'; // Translate waveform up
final char T_DOWN     = 's'; //                    down
final char T_LEFT     = 'a'; //                    left
final char T_RIGHT    = 'd'; //                    right
final char Z_IN       = 'c'; // Horizontal zoom in
final char Z_OUT      = 'z'; //                 out
final char S_IN       = 'e'; // Vertical scale in
final char S_OUT      = 'q'; //                out
final char MGL_UP     = 'r'; // Minor grid lines increase
final char MGL_DOWN   = 'f'; //                  decrease
final char TOG_PAUSE  = 'p'; // Toggle pause (unpause resets waveform)
final char RESET_AXIS = ' '; // Reset axis settings
final char MEAS_TIME  = 'x'; // Adds and/or highlights vertical bars (time measurement)
final char BAR_LEFT   = ','; // Move highlighted vertical bar left (can also mouse click)
final char BAR_RIGHT  = '.'; //                               right
// * ----------------------------------------------

// * --------------- STARTING STATE ---------------
float zoom    = 6.0;
float scale   = 1.5;
int centerV   = 545;
int centerH   = 0;
int gridLines = 0;
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
  return (int)(height/2 -(val-512+centerV)*scale / 1023.0f * (height - 1));
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
    stroke(255);
    fill(255);
  }
  if(bg_counter == 1){
    stroke(0);
    fill(0);
  }
  int x0 = 0, x1 = 0, y0 = 0, y1 = 0;
  stroke(255,255,0);
  for (int i=0; i<width; i++) {
    x1 = round(width - ((width-i) * zoom) + centerH);
    y1 = getY(values[i]);
    if(i > 1)
      line(x0, y0, x1, y1);
    x0 = x1;
    y0 = y1;
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

// Draw gridlines (bounds, minor)
void drawGrid() {
  // Get scaled values for bounds
  int pFive = getY(1023);
  int zero  = getY(0);

  // Draw voltage bounds
  stroke(255, 0, 0);
  line(0, pFive-1, width, pFive-1);
  line(0, zero+1, width, zero+1);

  // Add voltage bound text
  textFont(f, 10);
  fill(255, 0, 0);
  text("+5V", 5, pFive+12);
  text(" 0V", 5, zero-4);

  // Draw minor grid lines
  int gridVal = 0;
  stroke(75, 75, 75);
  for (int i = 0; i < gridLines; i++) {
    gridVal = getY(round((i+1.0)*(1023.0 / (gridLines+1.0))));
    line(0, gridVal, width, gridVal);
  }

  // Add minor grid line text
  if (gridLines > 0) {
    textFont(f, 16);
    fill(204, 102, 0);
    float scaleVal = truncate(5.0f / (gridLines+1), 3);
    text("Grid: " + scaleVal + "V", 1170, height-12);
  }
  
  // Print difference between vertical 'time' bars
  if (timeMode > 0) {
    textFont(f, 16);
    fill(204, 102, 0);
    
    int idx0 = round(width + (timeBars[0] - width - centerH)/zoom);
    int idx1 = round(width + (timeBars[1] - width - centerH)/zoom);
    
    // Ensure time bars are over a recorded portion of the waveform
    if(idx1 < 0 || idx0 < 0 || idx1 > (width-1) || idx0 > (width-1) || times[idx1] == 0 || times[idx0] == 0)
      text("Time: N/A", 30, height-12);
    else{
      float timeDiff = truncate((times[idx1] - times[idx0])/2000000.0,2);
      text("Time: " + timeDiff + "ms", 30, height-12);
    }
  }
}

// Draw vertical 'time bars' (seperate from above for better layering)
void drawVertLines(){
  stroke(75, 75, 75);
  if (timeMode == 1) {
    line(timeBars[1], 0, timeBars[1], height);
    stroke(100, 100, 255);
    line(timeBars[0], 0, timeBars[0], height);
  }
  else if (timeMode == 2) {
    line(timeBars[0], 0, timeBars[0], height);
    stroke(100, 255, 100);
    line(timeBars[1], 0, timeBars[1], height);
  }
}

// Truncate a floating point number
float truncate(float x, int digits) {
  float temp = pow(10.0, digits);
  return round( x * temp ) / temp;
}

// When a key is pressed down or held...
void keyPressed() {
  switch (key) {
  case T_UP: centerV += 10/scale; break;                     // Move waveform up
  case T_DOWN: centerV -= 10/scale; break;                   // Move waveform down
  case T_RIGHT: centerH += 10/scale; break;                  // Move waveform right
  case T_LEFT: centerH -= 10/scale; break;                   // Move waveform left
  case MGL_UP:                                               // Increase minor grid lines
    if (gridLines < 49)
      gridLines += 1;
    break;
  case MGL_DOWN:                                             // Decrease minor grid lines
    if (gridLines > 0)
      gridLines -= 1;
    break;
  case BAR_LEFT:                                             // Move the time bar left (also mouse click)
    if (timeMode == 1 && timeBars[0] > 0)
      timeBars[0] -= 1;
    else if (timeMode == 2 && timeBars[1] > 0)
      timeBars[1] -= 1; 
    break;
  case BAR_RIGHT:                                            // Move the time bar right (also mouse click)
    if (timeMode == 1 && timeBars[0] < width-1)
      timeBars[0] += 1;
    else if (timeMode == 2 && timeBars[1] < width-1)
      timeBars[1] += 1; 
    break;
  }
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
  case S_IN: scale*=2; break;                                // Scale vertical
  case S_OUT: scale /= 2; break;                             // Scale vertical
  case RESET_AXIS:                                           // Reset all scaling
    centerV = 0; centerH = 0;
    scale = 0.5; zoom  = 1; gridLines = 0;
    break;
  case MEAS_TIME: timeMode = (timeMode + 1) % 3; break;      // Change the vertical bars (off, left bar, right bar)
  case TOG_PAUSE:                                            // Toggle waveform pausing
    if (pause) {
      centerH = 0;
      for (int i=0; i<width; i++){
        values[i] = 0;                                       // Clear data on resume
        times[i] = 0;
      }
    }
    pause = !pause;
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
  drawGrid();
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
    text("Voltage: " + voltage + "V", 1170, 30);
  }
  drawLines();
  drawVertLines();
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