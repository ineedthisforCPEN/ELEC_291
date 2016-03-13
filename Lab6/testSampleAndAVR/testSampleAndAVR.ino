#define V_PIN         A0          // Potentiometer output pin
#define INTERRUPT     2           // Interrupt pin
#define DISPLAY_TIME  10000000L   // How long to display the signal in microseconds

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
int BAUD_16 = 57600;
int BAUD_32 = 38400;
int BAUD_64 = 19200;
int BAUD_128 = 9600;

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
  return;
}

/*
 * This function is our intterupt service routing (ISR). This function
 * is run whenever the Arduino detects and interrupt from INTERRUPT pin
 */
void __isr__(void) {
  start_time = micros();
}

