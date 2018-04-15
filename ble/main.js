var bleno = require ('bleno');
var readline = require ('readline');
var rl = readline.createInterface({
  input:  process.stdin,
  output: process.stdout
});


var updateFromLoRaCallback = null;

var stringCharacteristic = new bleno.Characteristic({
  uuid: '2a3d', // String Characteristic
  properties: ['write', 'notify'],
  descriptors: [
    new bleno.Descriptor({
      uuid: '2901', // Characteristic User Description
      value: 'Send/Receive data to/from LoRa'
    })
  ],
  onWriteRequest: (data, offset, withoutResponse, callback) => {
    console.log('[From BLE] ' + data.toString());
    callback(this.RESULT_SUCCESS)
  },
  onSubscribe: (maxValueSize, updateValueCallback) => {
    console.log('subscribed');
    updateFromLoRaCallback = updateValueCallback;
  },
  onUnsubscribe: () => {
    console.log('unsubscribed');
    updateFromLoRaCallback = null;
  }
});

rl.on('line', (line) => {
  if (updateFromLoRaCallback) {
    updateFromLoRaCallback(new Buffer(line.trim()));
  }
});

var loraServiceUUID = '17CF6671-7A8C-4DDD-9547-4BFA6D3F1C49'

var loraService = new bleno.PrimaryService({
  uuid: loraServiceUUID,
  characteristics: [stringCharacteristic]
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
