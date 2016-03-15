#define V_PIN         A0          // Potentiometer output pin
#define INTERRUPT     2           // Interrupt pin
#define DISPLAY_TIME  10000000L   // How long to display the signal in microseconds
#define NUM_SAMPLES   4096        // Number of smaples to take in order to find frequency

volatile long start_time;

// Define various ADC prescalers
// Arduin odocumentation does not recommend setting ADC clock to anything over 200kHz to preserve resolution,
//    however, the documentation states that a clock speed of 1MHz will not significantly degrade ADC resolution
// Source: http://www.microsmart.co.za/technical/2014/03/01/advanced-arduino-adc/
const unsigned char PS_16 = (1 << ADPS2);                                 // 1 MHz ADC clock speed
const unsigned char PS_32 = (1 << ADPS2) | (1 << ADPS0);                  // 500 kHz ADC clock speed
const unsigned char PS_64 = (1 << ADPS2) | (1 << ADPS1);                  // 250 kHz ADC clock speed
const unsigned char PS_128 = (1 << ADPS2) | (1 << ADPS1) | (1 << ADPS0);  // 125 kHz ADC clock speed

// Baud rate based on ADC prescaler
const int BAUD_16 = 57600;
const int BAUD_32 = 38400;
const int BAUD_64 = 19200;
const int BAUD_128 = 9600;

void setup() {
  Serial.begin(BAUD_16);

  pinMode(V_PIN, INPUT);
  pinMode(INTERRUPT, OUTPUT);

  attachInterrupt(digitalPinToInterrupt(INTERRUPT), __isr__, CHANGE);

  // set up the ADC
  ADCSRA &= ~PS_128;  // remove bits set by Arduino library
  ADCSRA |= PS_16;    // set our own prescaler to 64
}

void loop() {
  int val = analogRead(V_PIN);
  Serial.write(0xff);
  Serial.write(val >> 8);
  Serial.write(val & 0xff);
}

/*
 * This function is our intterupt service routing (ISR). This function
 * is run whenever the Arduino detects and interrupt from INTERRUPT pin
 */
void __isr__(void) {
  start_time = micros();
}

/*
 * This function calculates values needed to calibrate the "oscilloscope"
 * The values are:
 *    - Period
 *    - Amplitude
 *    - Sample rate
 *    
 * This function does not return anything. Rather, it sends data through
 * the serial monitor so Processing can use these values
 */
void calibrate_processing(void) {
  long frequency = 0;
  int i;

  for (i = 0; i < NUM_SAMPLES; i++)
  return;
}

//--------------------------------------------------
// CALIBRATION HELPER FUNCTIONS
//--------------------------------------------------

/*
 * This function measures the frequency of a signal.
 * This code is based on the FreqCounter library which
 * can be found here:
 *    http://interface.khm.de/index.php/lab/interfaces-advanced/arduino-frequency-counter-library/
 */
long getFrequency(void) {
  TIMSK &= ~(1 << TOIEO);   // Disable Timer0, millis and delay
  delayMicroseconds(50);    // Make sure the changes are made

  // Set up hardware counters
  TCCR1A = 0;               // Reset timer and counter1
  TCCR1B = 0;
  TCNT1 = 0;                // Set counter value to 0

  TCCR1B |= (1 << CS10) | (1 << CS11) | (1 << CS12);  // Set external clock sourse on T1 pin

  // Set up timer 2
  TCCR2A = 0;
  TCCR2B = 0;

  // Set timer 2 prescaler to 16
  return 0;
}
