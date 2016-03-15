#define V_PIN         A0          // Potentiometer output pin
#define INTERRUPT     2           // Interrup pin
#define DISPLAY_TIME  15000000L   // How long to display the signal in microseconds

// Define various ADC prescalers
// Arduin odocumentation does not recommend setting ADC clock to anything over 200kHz to preserve resolution,
//    however, the documentation states that a clock speed of 1MHz will not significantly degrade ADC resolution
// Source: http://www.microsmart.co.za/technical/2014/03/01/advanced-arduino-adc/
const unsigned char PS_16 = (1 << ADPS2);                                 // 1 MHz ADC clock speed
const unsigned char PS_32 = (1 << ADPS2) | (1 << ADPS0);                  // 500 kHz ADC clock speed
const unsigned char PS_64 = (1 << ADPS2) | (1 << ADPS1);                  // 250 kHz ADC clock speed
const unsigned char PS_128 = (1 << ADPS2) | (1 << ADPS1) | (1 << ADPS0);  // 125 kHz ADC clock speed

// Baud rate based on ADC prescaler
const int BAUD_16 = 57600;    // BAUD rate for PS_16
const int BAUD_32 = 38400;    // BAUD rate for PS_32
const int BAUD_64 = 19200;    // BAUD rate for PS_64
const int BAUD_128 = 9600;    // BAUD rate for PS_128

volatile long start_time;
int val;

//----------------------------------------
// ADJUST FOR VARIOUS PRESCALER VALUES
//----------------------------------------
int prescale = PS_128;    // The prescaler selected is PS_128 (i.e. 125kHz for the ADC clock)

void setup() {
  cli();  // Disable interrupts while setting up
  
  Serial.begin(BAUD_128);     // Because the prescaler is selected as PS_128, the baud rate should be set to BAUD_128
  
  pinMode(V_PIN,     INPUT ); // Set up oscilloscope output pin
  pinMode(INTERRUPT, OUTPUT); // Set up pushbutton interrup pin
  
  attachInterrupt(digitalPinToInterrupt(INTERRUPT), __isr__, CHANGE);   // Create the external interrupt
  start_time = -DISPLAY_TIME; // This is set in an attempt to prevent the Arduino from immediately sending oscilloscope data

  // Set up the prescaler
  ADCSRA &= ~PS_128;
  ADCSRA |= prescale;
  
  sei();  // Enable interrupt - the setup is complete
}

void loop() {
  // Only run in this loop is the start time has been set within DISPLAY_TIME microseconds of the current Arduino uptime
  while (micros() - start_time < DISPLAY_TIME) {
    val = analogRead(V_PIN);          // Read oscilloscope value
    Serial.write(0xff);               // Send initialization byte
    Serial.write((val >> 8) & 0xff);  // Send the two most significant bits of the 10-bit ADC value 
    Serial.write(val & 0xff);         // Send the eight least significant bits of the 10-bit ADC value
  }

  sei();                                  // Enable interrupts - they would have been disabled if the code entered
                                          // the while loop above
  //Serial.println("Not reading voltage");  // Useful debugging print statement
}

/*
 * This is the interrupt service routine used when the pushbutton connected to pin 2 is pushed. The ISR
 * allows the Arduino to enter a part of the code that sends oscilloscope readings for DISPLAY_TIME
 * microseconds
 */
void __isr__(void) {
  start_time = micros();  // Set start_time to current arduino uptime (in microseconds)
  cli();                  // Disable interrupts (so our interrupt code is not interrupted)
}

/*
 * The function below is not used, but it is helpful for debugging. It provides some visual aid
 * to the values read by the Arduino analog pin A0, as well as providing actual A0 readings
 */
/*
void printit(int x) {
  Serial.print(x);
  Serial.print("\t");
  while (x > 0) {
    Serial.print("-");
    x -= 64;
  }
  Serial.println();
}
*/
