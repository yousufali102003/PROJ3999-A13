
#include <Adafruit_Sensor.h>
#include <Adafruit_ADXL345_U.h>

#include <Wire.h> 
#include <LiquidCrystal_I2C.h>
#include <SoftwareSerial.h>
#include <TinyGPS++.h>

// Create an instance of the ADXL345 sensor
Adafruit_ADXL345_Unified accel = Adafruit_ADXL345_Unified(12345);

LiquidCrystal_I2C lcd(0x27, 16, 2); // Set the I2C address to 0x27, 16 columns, 2 rows

const int alcoholPin = 5;  // Digital output pin of the alcohol sensor
const char* apiKey = "HGMPJUEZVSQ10XG6";
const int irPin = 4;

const int m1 = 8;
const int m2 = 9;
int buzzer = 6;

SoftwareSerial uart(2, 3);
TinyGPSPlus gps;
String LAT, LON;

void setup() {
  Serial.begin(9600);
  uart.begin(9600);
  Serial.println("Initializing ADXL345...");

  // Initialize ADXL345
  if (!accel.begin()) {
    Serial.println("Could not find a valid ADXL345 sensor, check wiring!");
    while (1)
      ;  // Halt execution if the sensor is not found
  }

  Serial.println("ADXL345 ready");


  // Initialize alcohol sensor pin
  pinMode(alcoholPin, INPUT);
   pinMode(irPin, INPUT);
    pinMode(m1, OUTPUT);
    pinMode(m2, OUTPUT);
     pinMode(buzzer, OUTPUT);
lcd.begin(16, 2);//Defining 16 columns and 2 rows of lcd display
lcd.backlight();//To Power ON the back light
 digitalWrite(m1, HIGH);
 digitalWrite(m2, LOW);
 digitalWrite(buzzer, LOW);
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("Smart helmet");
  lcd.setCursor(0, 1);
  lcd.print("system");
  delay(2000);  // Display the initialization message for 2 seconds
  lcd.clear();
}

void loop() {
  smartDelay(1000);
 digitalWrite(m1, HIGH);
 digitalWrite(m2, LOW);
  // Check alcohol sensor
  int Alcohol_value = digitalRead(alcoholPin);
   int ir_value = digitalRead(irPin);
    
  String LAT = String(gps.location.lat(), 6);
  String LON = String(gps.location.lng(), 6);
  sensors_event_t event;
  accel.getEvent(&event);

  // Print ADXL345 values to Serial Monitor
  Serial.print("X: ");
  Serial.print(event.acceleration.x);
  Serial.print(" Y: ");
  Serial.print(event.acceleration.y);
  Serial.print(" Z: ");
  Serial.println(event.acceleration.z);

  // Update LCD with sensor values
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("X: ");
  lcd.print(event.acceleration.x);
  lcd.setCursor(0, 1);
  lcd.print("Y: ");
  lcd.print(event.acceleration.y);
  
  delay(2000);
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("IR: ");
  lcd.print(ir_value);
  lcd.setCursor(0, 1);
  lcd.print("A: ");
  lcd.print(Alcohol_value);
  delay(2000);


  // Detect accident based on ADXL345 data
  if (event.acceleration.x > 7 || event.acceleration.y > 7 || event.acceleration.x < -7 || event.acceleration.y < -7 || event.acceleration.z < 0) {
    digitalWrite(buzzer, HIGH);
    digitalWrite(m1, LOW);
 digitalWrite(m2, LOW);
    lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("Accident detect");
 
    delay(3000);
   
  digitalWrite(buzzer, LOW);
   delay(1000);
    sendSMS();
    delay(1000);
    digitalWrite(m1, HIGH);
 digitalWrite(m2, LOW);
  delay(500);

  } else if (Alcohol_value == LOW) {
     digitalWrite(buzzer, HIGH);
     digitalWrite(m1, LOW);
 digitalWrite(m2, LOW);
    lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("Alcohol Detected");
    delay(4000);  
    digitalWrite(buzzer, LOW);
     digitalWrite(m1, HIGH);
 digitalWrite(m2, LOW);
  } else if (ir_value == HIGH) {
    digitalWrite(buzzer, HIGH);
      digitalWrite(m1, LOW);
 digitalWrite(m2, LOW);
    lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("Helmet Not found");
    delay(4000);  // Display message for 2 seconds
    digitalWrite(buzzer, LOW);
         digitalWrite(m1, HIGH);
 digitalWrite(m2, LOW);
  } 
  


  
  // Print GPS data to Serial Monitor
  Serial.println(gps.location.lat(), 6);
  Serial.print("lng:");
  Serial.println(gps.location.lng(), 6);

  // Display GPS data on the LCD
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("LAT:");
  lcd.print(LAT);
  lcd.setCursor(0, 1);
  lcd.print("LNG:");
  lcd.print(LON);
  delay(1000);

   upload(event.acceleration.x, event.acceleration.y, Alcohol_value, ir_value, LAT, LON);

}

void sendSMS() {
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("msg sending...");
  Serial.print("msg sending...");
  uart.println("AT");
  delay(1000);
  uart.println("ATE0");
  delay(500);
  uart.println("AT+CMGF=1");
  delay(500);
  uart.println("AT+CMGS=\"+918332082982\"");  // Replace with your phone number
  delay(500);
  uart.println("Abnormal condition occured, Location:");
  delay(500);
  uart.print("https://www.google.com/maps/place/" + String(gps.location.lat(), 6) + "," + String(gps.location.lng(), 6));
  uart.println((char)26);
  delay(500);
  uart.write(26);
  delay(15000);
  Serial.println("msg sent");
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("msg sent");
  delay(2000);
}

static void smartDelay(unsigned long ms) {
  unsigned long start = millis();
  do {
    while (uart.available())
      gps.encode(uart.read());
  } while (millis() - start < ms);
}
void upload(float accelX, float accelY, int Alcohol_value, int ir_value, String LAT, String LON) {
  uart.println("AT");
  delay(1000);
  uart.println("AT+CPIN?");
  delay(1000);
 uart.println("AT+CREG?");
  delay(1000);
  uart.println("AT+CGATT?");
  delay(1000);
  uart.println("AT+CIPSHUT");
  delay(1000);
 uart.println("AT+CIPSTATUS");
  delay(2000);
  uart.println("AT+CIPMUX=0");
  delay(2000);
  uart.println("AT+CSTT=\"Airtel Internet\"");  // Start task and set the APN
  delay(1000);
  uart.println("AT+CIICR");  // Bring up wireless connection
  delay(6000);
  uart.println("AT+CIFSR");  // Get local IP address
  delay(1000);
 uart.println("AT+CIPSPRT=0");
  delay(3000);
  uart.println("AT+CIPSTART=\"TCP\",\"api.thingspeak.com\",\"80\"");  // Start the connection
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("data sending...");
  lcd.setCursor(0, 1);
  lcd.print("to server");
  delay(5000);
  uart.println("AT+CIPSEND");  // Begin sending data to the remote server
  delay(1000);

  String str = "GET /update?api_key=";
  str += apiKey;
  str += "&field1=" + String(accelX);
  str += "&field2=" + String(accelY);
  str += "&field3=" + String(Alcohol_value);
  str += "&field4=" + String(ir_value);
  str += "&field5=" + LAT;
  str += "&field6=" + LON;

  uart.println(str);  // Send data to the server
  delay(6000);
  uart.write(26);  // End of the transmission
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("DATA SENT");
  lcd.setCursor(0, 1);
  lcd.print("TO SERVER");
  delay(2000);
  lcd.clear();
 uart.println();
  uart.println("AT+CIPSHUT");  // Close the connection
  delay(1000);
}

