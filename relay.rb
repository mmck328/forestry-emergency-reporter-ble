require 'rubygems'
require 'serialport'
require 'fileutils'

$serial_port = '/dev/ttyUSB0'
#$serial_port = '/dev/ttyAMA0'
$serial_baudrate = 115200
serial_databit = 8
$serial_stopbit = 1
$serial_paritycheck = 0
$serial_delimiter = "\r\n"

sp = SerialPort.new($serial_port, $serial_baudrate, $serial_databit, $serial_stopbit, $serial_paritycheck)
sp.read_timeout=5000 

FileUtils.makedirs("./log/relay_log")
filename = "./log/relay_log/" + Time.now().strftime("%Y%m%d-%H%M%S") + ".log"
file = File.open(filename, 'a')

received = nil 

def log(text)
  p text
  file.puts(text)
end

def send_rssi(matched, panid, srcid)
  log("Return RSSI to origin:#{srcid}")
  sp.write(panid + srcid + "ACK:-" + matched[:rssi] + "dBm" + $serial_delimiter)  
  response = sp.gets($serial_selimiter)
  if response 
    log(response)
    sleep(0.2) 
  end
end

while true
  incoming = sp.gets($serial_delimiter)
  if incoming
    log(incoming)
    if received
      panid = received[:panid]
      srcid = received[:srcid]
      dstid = received[:dstid]

      matched = incoming.match(/RSSI\(\-(?<rssi>\d+)dBm\)\:Receive Data\((?<payload>.*)\)\r\n/)

      if matched && srcid.hex > dstid.hex
        nextid = format("%04X", [dstid.hex - 1, 0].max) 
        rssi = matched[:rssi]
        payload = matched[:payload]
        log("received payload: " + payload)

        orgid = payload[0..3]
        send_rssi(matched, panid, srcid) if srcid == orgid # for measurement

        log("Relay payload to next node:#{nextid}")
        sp.write(panid + nextid + payload + $serial_delimiter) 
      end 
    end 
    received = incoming.match(/--> receive data info\[panid = (?<panid>[0-9A-F]{4}), srcid = (?<srcid>[0-9A-F]{4}), dstid = (?<dstid>[0-9A-F]{4}), length = (?<length>[0-9A-F]{2})\]/)
  end
end

file.close
sp.close
