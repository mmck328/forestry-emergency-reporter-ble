var bleno = require ('bleno');
var rl = readline.createInterface({
  input:  process.stdin,
  output: process.stdout
});

var fromLoRaPayload = '';
var toLoRaPayload = '';

var updateToLoRaCallback = null;

rl.on('line', (line) => {
  fromLoRaPayload = line.trim();
});

var PrimaryService = bleno.PrimaryService;
var Characteristic = bleno.Characteristic;

console.log('ble-lora service');

var loraServiceUUID = '17CF6671-7A8C-4DDD-9547-4BFA6D3F1C49'


var fromLoRaCharacteristic = new Characteristic({
  uuid: '7F5D2112-0B9F-4188-9C4D-6AC4C161EC81',
  properties: ['read', 'notify'],
  value: new Buffer(0),
  onSubscribe: (maxValueSize, updateValueCallback) => {
    console.log('subscribed');
    updateValueCallback(this.value);
  },
  onUnsubscribe: () => {
    console.log('unsubscribed');
  }
});

var toLoRaCharacteristic

var loraService = new PrimaryService({
  uuid: loraServiceUUID,
  characteristics: [
    fromLoRaCharacteristic,
    toLoRaCharacteristic
  ]
});

bleno.on('stateChange', function(state) {
  console.log('on -> stateChange: ' + state);

  if (state === 'poweredOn') {
    bleno.startAdvertising('BLE-LoRa Gateway', ['ec00']);
  } else {
    bleno.stopAdvertising();
  } 
});

bleno.on('advertisingStart', function(error) {
  console.log('on -> advertisingStart: ' + (error ? 'error ' + error : 'success'));

  if (!error) {
    bleno.setServices([
      new BlenoPrimaryService({
        uuid: 'ec00',
        characteristics: [
          new EchoCharacteristic()
        ]
      })
    ]);
  }
});
