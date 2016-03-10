import processing.serial.*;
import java.util.*;

Serial arduinoPort;
int xPos = 1;
float voltage = 20;

void setup(){
  
  size(800, 600);
  background(0);
  
  

  
  arduinoPort = new Serial(this, Serial.list()[0], 9600);
  arduinoPort.bufferUntil('\n');
}
void draw(){
  stroke(255, 0, 0);
  line(xPos, height - voltage, xPos, 0);
  
  if (xPos >= width) {    // Perform wrap arround once xPos reaches end of screen
    xPos = 0;
    background(0);
  } else {                // Increment horizontal position otherwise
    xPos++;
  }
}

void serialEvent(Serial arduinoPort) {
  // Get ASCII string output by the arduino
  String dataString = arduinoPort.readStringUntil('\n');
  
  if (dataString == null) return;    // Stop if the data string is null
  
  dataString = trim(dataString);     // Trim whitespaces

  // dataString might not be formatted correctly
  // Handle incorrect formatting in this try-catch block
  try {
    
    voltage       = int(dataString);  // Get humidity reading, convert from string to float
    
    // Map (i.e. scale) the measurements to fit the screen better
    voltage       = map(voltage,       0, 1024,   0, height);

  } catch (Exception e) {
    // Stop if the string is formatted incorrectly
    return;
  }
  
}