#define V_PIN         A0          // Potentiometer output pin
#define INTERRUPT     2           // Interrup pin
#define DISPLAY_TIME  10000000L   // How long to display the signal in microseconds

volatile long start_time;

void setup() {
  // put your setup code here, to run once:
  Serial.begin(9600);
  
  pinMode(V_PIN,     INPUT );
  pinMode(INTERRUPT, OUTPUT);
  
  attachInterrupt(digitalPinToInterrupt(INTERRUPT), __isr__, CHANGE);
}

void loop() {
  // put your main code here, to run repeatedly:  
  while (micros() - start_time < DISPLAY_TIME) {
    //printit(analogRead(V_PIN));
    Serial.println(analogRead(V_PIN));
  }
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
