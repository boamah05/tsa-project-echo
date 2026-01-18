#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>

#define MOTOR_PIN 25

// BLE UUIDs
#define SERVICE_UUID        "12345678-1234-1234-1234-1234567890ab"
#define CHARACTERISTIC_UUID "abcd1234-5678-1234-5678-abcdef123456"

int urgency = 0;

class UrgencyCallback : public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic *pCharacteristic) {
    String value = pCharacteristic->getValue().c_str();
    urgency = value.toInt();
  }
};

void setup() {
  pinMode(MOTOR_PIN, OUTPUT);
  digitalWrite(MOTOR_PIN, LOW);

  BLEDevice::init("EchoWay-Band");
  BLEServer *pServer = BLEDevice::createServer();

  BLEService *pService = pServer->createService(SERVICE_UUID);
  BLECharacteristic *pCharacteristic =
    pService->createCharacteristic(
      CHARACTERISTIC_UUID,
      BLECharacteristic::PROPERTY_WRITE
    );

  pCharacteristic->setCallbacks(new UrgencyCallback());
  pService->start();

  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->start();
}

void loop() {
  if (urgency == 0) {
    digitalWrite(MOTOR_PIN, LOW);
  }
  else if (urgency == 1) {
    digitalWrite(MOTOR_PIN, HIGH);
    delay(500);
    digitalWrite(MOTOR_PIN, LOW);
    delay(1000);
  }
  else if (urgency == 2) {
    digitalWrite(MOTOR_PIN, HIGH);
    delay(200);
    digitalWrite(MOTOR_PIN, LOW);
    delay(200);
  }
}
