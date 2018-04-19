var bleno = require ('bleno');
var readline = require ('readline');
var rl = readline.createInterface({
  input:  process.stdin,
  output: process.stdout
});


var updateFromLoRaCallback = null;

var receivedNotificationCharacterictic = new bleno.Characteristic({
  uuid: '7F5D2112-0B9F-4188-9C4D-6AC4C161EC81', // Received Notification Characteristic
  properties: ['notify'],
  descriptors: [
    new bleno.Descriptor({
      uuid: '2901', // Characteristic User Description
      value: 'Notification when data received from LoRa'
    }),
    new bleno.Descriptor({
      uuid: '2904', // Characteristic Presentation Format
      value: new Buffer([25, 0x00, 0x27, 0x00, 1, 0x00, 0x00])
    })
  ],
  onSubscribe: (maxValueSize, updateValueCallback) => {
    console.log('subscribed');
    updateFromLoRaCallback = updateValueCallback;
  },
  onUnsubscribe: () => {
    console.log('unsubscribed');
    updateFromLoRaCallback = null;
  }
});

var received = '';

var receivedCharacterictic = new bleno.Characteristic({
  uuid: '060CCB44-9F41-43E7-8BE2-C711631D56E2', // Received Characteristic
  properties: ['read'],
  descriptors: [
    new bleno.Descriptor({
      uuid: '2901', // Characteristic User Description
      value: 'Received data from LoRa'
    }),
    new bleno.Descriptor({
      uuid: '2904', // Characteristic Presentation Format
      value: new Buffer([25, 0x00, 0x27, 0x00, 1, 0x00, 0x00])
    })
  ],
  onReadRequest: (offset, callback) => {
    let result;
    let data = new Buffer(received);
    if (offset > data.length) {
      result = this.RESULT_INVALID_OFFSET;
      data = null;
    } else {
      result = this.RESULT_SUCCESS;
      data = data.slice(offset);  
    }
    callback(result, data);
  }
});

var sendCharacteristic = new bleno.Characteristic({
  uuid: '3D161CC8-CFE4-4948-B582-672386BB41AB', // Send Characteristic
  properties: ['write'],
  descriptors: [
    new bleno.Descriptor({
      uuid: '2901', // Characteristic User Description
      value: 'Prepared data to send to LoRa'
    }),
    new bleno.Descriptor({
      uuid: '2904', // Characteristic Presentation Format
      value: new Buffer([25, 0x00, 0x27, 0x00, 1, 0x00, 0x00])
    })
  ],
  onWriteRequest: (data, offset, withoutResponse, callback) => {
    console.log('[From BLE] ' + data.toString());
    callback(this.RESULT_SUCCESS)
  }
});

rl.on('line', (line) => {
  received = line;
  if (updateFromLoRaCallback) {
    updateFromLoRaCallback(new Buffer([1]));
  }
});

var loraServiceUUID = '17CF6671-7A8C-4DDD-9547-4BFA6D3F1C49'

var loraService = new bleno.PrimaryService({
  uuid: loraServiceUUID,
  characteristics: [receivedNotificationCharacterictic, receivedCharacterictic, sendCharacteristic]
});

bleno.on('stateChange', function(state) {
  console.log('stateChange: ' + state);

  if (state === 'poweredOn') {
    bleno.startAdvertising('BLE-LoRa Gateway', [loraServiceUUID]);
  } else {
    bleno.stopAdvertising();
  } 
});

bleno.on('advertisingStart', function(error) {
  console.log('advertisingStart: ' + (error ? 'error ' + error : 'success'));

  if (!error) {
    bleno.setServices([loraService]);
  }
});
