#define V_PIN         A0          // Potentiometer output pin
#define INTERRUPT     2           // Interrup pin
#define DISPLAY_TIME  10000000L   // How long to display the signal in microseconds

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

volatile long start_time = -DISPLAY_TIME;
int val;

//----------------------------------------
// ADJUST FOR VARIOUS PRESCALER VALUES
//----------------------------------------
int prescale = PS_128;

void setup() {
  // Begin serial monitor depending on the prescaler selected

  Serial.begin(BAUD_128);
  
  pinMode(V_PIN,     INPUT );
  pinMode(INTERRUPT, OUTPUT);
  
  attachInterrupt(digitalPinToInterrupt(INTERRUPT), __isr__, CHANGE);

  ADCSRA &= ~PS_128;
  ADCSRA |= prescale;
}

void loop() {
  while (micros() - start_time < DISPLAY_TIME) {
    val = analogRead(V_PIN);
    Serial.write(val >> 8);
    Serial.write(val & 0xff);
  }

  Serial.println("Not reading voltage");
}

void __isr__(void) {
  start_time = micros();
}

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
