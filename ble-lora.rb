require 'rubygems'
require 'serialport'
require_relative './logger'
require 'thread'

$serial_port = '/dev/ttyUSB0'
#$serial_port = '/dev/ttyAMA0'
$serial_baudrate = 115200
$serial_databit = 8
$serial_stopbit = 1
$serial_paritycheck = 0
$serial_delimiter = "\r\n"

$sp = SerialPort.new($serial_port, $serial_baudrate, $serial_databit, $serial_stopbit, $serial_paritycheck)
$sp.read_timeout=100

DEVICE_CONF = {} #deviceid
File.foreach('device.conf') do |text|
    key = text.split('=')[0]
    val = text.split('=')[1].chomp
    DEVICE_CONF[key] = val
end
p DEVICE_CONF

PAN_ID = DEVICE_CONF['panid']
DEVICE_ID = DEVICE_CONF['deviceid']
GW_ID = '0000'

$logger = Logger.new('ble-lora_log')

def send(msg, count)
  pkttype = '0' # direction to cloud
  payload = pkttype + msg
  $logger.log "payload: #{payload}"
  
  $sp.write PAN_ID + GW_ID + payload + $serial_delimiter
end

threads = []
mutex = Mutex.new

threads << Thread.new do  
  loop do
    incoming = $sp.gets($serial_delimiter)
    if incoming
      $logger.log(incoming)
      if received
        panid = received[:panid]
        srcid = received[:srcid]
        dstid = received[:dstid]

        matched = incoming.match(/RSSI\(\-(?<rssi>\d+)dBm\)\:Receive Data\((?<payload>.*)\)\r\n/)

        if matched
          payload = matched[:payload]
          $logger.log("received payload: " + payload)

          $logger.log("Relay payload to smartphone")
          # BLEでスマホに送信
        end 
      end 
      received = incoming.match(/--> receive data info\[panid = (?<panid>[0-9A-F]{4}), srcid = (?<srcid>[0-9A-F]{4}), dstid = (?<dstid>[0-9A-F]{4}), length = (?<length>[0-9A-F]{2})\]/)
    end
  end
end

threads << Thread.new do
  loop do
    send(msg)
  end
end

threads.each { |thr| thr.join }
$sp.close

