/* Import necessary libraries */
import twitter4j.conf.*;
import twitter4j.*;
import twitter4j.auth.*;
import twitter4j.api.*;
import processing.serial.*;
import java.util.*;

/* Twitter object */
Twitter twitter;

/* Serial object for to enable reading from serial port */
Serial arduinoPort;

/* Objects and variables used for measurement and the GUI */
PFont f;      // Font used for the GUI
PFont fb1;    // Font used for the GUI
PFont fb2;    // Font used for the GUI

float distanceArray[] = {0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,
                         0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0};
float distanceReading = 0.0;
float mappedDistanceReading = 0.0;
float threshold = 50.0;

int shortDistances = 0;
int middleDistances = 0;
int longDistances = 0;
int numberOfTweets = 0;
int graphXPos = 0;
int updateFlag = 0;
int thresholdFlag = 0;

String mostRecentTweet = "tweet";

void setup() {
  /* Set up the twitter object */
  ConfigurationBuilder cb = new ConfigurationBuilder();
  cb.setOAuthConsumerKey("4VGNCl4MiuhKT5sMyrEpN6HDC");                              // Set consumer key
  cb.setOAuthConsumerSecret("oJFfRjzKVbf16JBc8bcKNSpJ0dowvtJVwvm0TBqOEgts5eCiNX");  // Set consumer secret
  cb.setOAuthAccessToken("4859741185-h0WzWGaT3zmKaqELUDagG4ABqGzC94UQIlG9k5c");     // Set access token
  cb.setOAuthAccessTokenSecret("7t8YMp75B2ecdTAQKBBVxf3HuYESXpAgCMmPZSW6YewUH");    // Set access token secret
  TwitterFactory tf = new TwitterFactory(cb.build());
  twitter = tf.getInstance();
  
  /* Set up the GUI */
  f = createFont("Arial", 16, true);          // Define font f   (f for font)
  fb1 = createFont("Arial Bold", 24, true);   // Define font fb  (b for bold)
  fb2 = createFont("Arial Bold", 20, true);   // Define font fb2 (b for bold)
  
  size(800, 460);                             // Set up GUI screen
  background(225, 225, 255);                  // Set GUI background colour

  // The following items do not need to be updated after every measurement, so they are set up here
  textFont(fb1);                              // Set font to fb1
  fill(45, 45, 45);                           // Set the font colour
  textAlign(LEFT);                            // Left-align the following text
  text("Distances Measured:",10,30);          // Display label
  text("Most Recent Tweet:", 270, 180);       // Display label
  text("Distance Graph:", 270, 340);          // Display label
  
  fill(45, 45, 45);                           // Set the ractangle colour
  rect(270, 350, 520, 100);                   // Box for distance graph
  
  textFont(createFont("Arial", 12, true));
  textAlign(RIGHT);
  fill(225, 225, 225);
  text("500.0", 310, 370);
  text("0.0", 310, 440);
  
  updateGUI();
  
  /* Set up serial port */
  arduinoPort = new Serial(this, Serial.list()[0], 9600);
  arduinoPort.bufferUntil('\n');
}

void draw() {
  if (updateFlag == 1) {
    updateGUI();
    updateFlag = 0;
  }
  
  /* Code below is used for testing the GUI */
  /*
  if (numberOfTweets % 30 == 0) {
    mostRecentTweet += "1";
    insertInArray(distanceArray, 250.0);
  } else if (numberOfTweets % 10 == 0) {
    mostRecentTweet += "!";
    insertInArray(distanceArray, 500.0);
  }
  
  delay(500);
  */
}


void tweet() {
  /*
  try {
    Status status = twitter.updateStatus("This is a tweet sent from Processing");
    System.out.println("Status updated to [" + status.getText() + "].");
  } catch (TwitterException te) {
    System.out.println("Error: "+ te.getMessage());
  }
  */
  mostRecentTweet = "Some other tweet";
  numberOfTweets++;
}


void keyPressed() {
  //tweet();
}

void serialEvent(Serial arduinoPort) {
  // Get ASCII string output by the arduino
  String dataString = arduinoPort.readStringUntil('\n');
  if (dataString == null) return;           // Stop if the data string is null
  
  dataString = trim(dataString);            // Trim any whitespaces
  
  try {                                     // Try reading data
    distanceReading = float(dataString);    // Try converting the data into a float
    
    if (distanceReading < threshold && thresholdFlag == 1) {
      thresholdFlag = 0;
      tweet();
    } else if (distanceReading >= threshold && thresholdFlag == 0) {
      thresholdFlag = 1;
      tweet();
    }
  } catch (Exception e) {                   // If conversion fails
    return;                                 // Stop
  }
  
  if (distanceReading <= 1.99) {            // If reading is below 2cm (allowed error of 0.01)
                                            // Do nothing
  } else if (distanceReading <= 20.0) {     // If reading is below 20cm (and above 2cm, allowed error of 0.01)
    shortDistances++;                       // Increment number of short-range distances measured
  } else if (distanceReading <= 100.0) {    // If reading is below 100cm (and above 20cm, allowed error of 0.01)
    middleDistances++;                      // Increment number of mid-range distances measured
  } else if (distanceReading <= 500.01) {   // If reading is below 500cm (and above 100cm, allowed error of 0.01)
    longDistances++;                        // Increment number of long-range distances measured
  } else {                                  // Otherwise (if measurement is above 500cm)
                                            // Do nothing
  }
  
  insertInArray(distanceArray, distanceReading);  // Insert this reading into distancArray
  updateFlag = 1;
}

// --------------------------------------------------
// Functions for the GUI
// --------------------------------------------------

/*
 * This function generates the initial background for the GUI. These elements
 * are used to overwrite old values for the counters, distances and tweets.
 */
void guiInitialize() {
  fill(200, 200, 230);                      // Set the rectangle colour
  rect(10, 40, 240, 410, 7);                // Box for distance measured
  rect(270, 10, 160, 60, 7);                // Box for short distance counter
  rect(450, 10, 160, 60, 7);                // Box for middle distance counter
  rect(630, 10, 160, 60, 7);                // Box for long distance counter
  rect(270, 90, 520, 50, 7);                // Box for tweet counter
  rect(270, 190, 520, 100, 7);              // Box for most recent tweet

  textFont(fb1);                            // Set font to fb1
  fill(45, 45, 45);                         // Set the font colour
  textAlign(LEFT);                          // Left-align the following text
  text("Number of Tweets Sent:", 280, 125); // Display label
  
  textFont(fb2);                            // Set font to tb2
  textAlign(CENTER);                        // Center-align the following text
  text("2cm - 20cm", 350, 30);              // Display label
  text("20cm - 100cm", 530, 30);            // Display label
  text("100cm - 500cm", 710, 30);           // Display label
  
 }
 
 /*
  * This function updates the GUI by updating the values for the number of tweets,
  * number of short range finds by the ultrasonic sensor, number of mid-range finds,
  * number of long range finds, as well as various other data
  */
void updateGUI() {
  guiInitialize();                            // Initialize GUI (this is to overwrite old values)
  
  textFont(f);                                // Set font to f
  fill(45, 45, 45);                           // Set the font colour
  textAlign(CENTER);                          // Center-align the following text
  text(str(shortDistances), 350, 60);         // Display number of short-range distances measured
  text(str(middleDistances), 530, 60);        // Display number of mid-range distances measured
  text(str(longDistances), 710, 60);          // Display number of long-range distances measured
  
  textAlign(CENTER, CENTER);                  // Align the following text to be in the middle of the "most recent tweet" box
  text(mostRecentTweet, 280, 200, 500, 80);  // Display the most recent tweet
  
  textAlign(RIGHT);                           // Right-align the text
  text(str(numberOfTweets), 760, 122);        // Display the number of tweets
  
  // Display the 20 most recent distance measurements  
  for (int i = 0; i < 20; i++) {
    float value = distanceArray[i];        // Get measurement stored in distanceArray[i] (0 is most recent)
    
    if (value <= 0.0 || value > 500.0) {   // This limitation was gotten from the lecture - Farshid stated the range was between 2cm and 500cm
      text("--", 240, 60 + 20*i);          // Display "--" is the measurement is invalid (out of range of the sensor, i.e. 0 < measurement <= 500)
    } else {
      text(str(value), 240, 60 + 20 * i);  // Display actual value if it is valid
    }
  }
  
  // Update the graph
  if (distanceArray[0] <= 0.0 || distanceArray[0] > 500.0) {
    stroke(45, 45, 45);
    line(320 + graphXPos, 440, 320 + graphXPos, 360);
  } else {
    mappedDistanceReading = map(distanceArray[0], 0, 500, 0, 80);
  
    stroke(45, 45, 45);
    line(320 + graphXPos, 440, 320 + graphXPos, 360);
  
    stroke(85, 172, 238);
    line(320 + graphXPos, 440, 320 + graphXPos, 440 - mappedDistanceReading);
  }
  
  stroke(45, 45, 45);    // This ensures that the borders of the boxes remain the same colour
  
  if (graphXPos >= 450) {
    graphXPos = 0;

    // Reset the graph background - optional, depending on how you want your graph to look
    fill(45, 45, 45);                           // Set the ractangle colour
    rect(270, 350, 520, 100);                   // Box for distance graph
  } else {
    graphXPos++;
  }
}

// --------------------------------------------------
// Function for array manipulation
// --------------------------------------------------

/*
 * This function takes a float and inserts it in a float array at position 0. The value
 * in the last position of the array is overwritten.
 *
 * Parameter: array  - the float array in which to insert the user-input value
 * Parameter: insert - the float to insert at position 0
 */
void insertInArray(float array[], float insert) {
  for (int i = array.length - 1; i > 0; i--) {
    array[i] = array[i - 1];    // Place element i - 1 into position i
  }
  
  array[0] = insert;            // Place insert at beginning of array
}