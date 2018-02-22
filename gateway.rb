require 'rubygems'
require 'serialport'
require 'socket.io-client-simple'
require './logger'

$sp = SerialPort.new('/dev/ttyUSB0', 115200, 8, 1, 0)
$sp.read_timeout = 1000
$serial_delimiter = "\r\n"

url = 'http://ec2-54-199-199-19.ap-northeast-1.compute.amazonaws.com:3013'
socket = SocketIO::Client::Simple.connect(url)

socket.on :connect do
    puts 'connect'
end

socket.on :disconnect do
    puts 'disconnect'
end

socket.on 'from server' do |data|
    puts 'on_response ' + data
end

$logger = Logger.new('gateway_log')

received = nil

def send_rssi(matched, panid, srcid)
    $logger.log("Return RSSI to origin:#{srcid}")
    $sp.write(panid + srcid + "ACK:-" + matched[:rssi] + "dBm" + $serial_delimiter)
    response = $sp.gets($serial_selimiter)
    if response
        $logger.log(response)
        sleep(0.2)
    end
end

loop do
    incoming = $sp.gets($serial_delimiter)
    if incoming
        $logger.log(incoming)
     	if received
            socket.emit("chat message", received.string)
            socket.emit("chat message", incoming)

            panid = received[:panid]
            srcid = received[:srcid]
            dstid = received[:dstid]

            matched = incoming.match(/RSSI\(\-(?<rssi>\d+)dBm\)\:Receive Data\((?<payload>.*)\)\r\n/)

            if matched
                rssi = matched[:rssi]
                payload = matched[:payload]
                orgid = payload[0..3]
                send_rssi(matched, panid, srcid) if srcid == orgid # for measurement
            end
        end
        received = incoming.match(/--> receive data info\[panid = (?<panid>[0-9A-F]{4}), srcid = (?<srcid>[0-9A-F]{4}), dstid = (?<dstid>[0-9A-F]{4}), length = (?<length>[0-9A-F]{2})\]/)
    end
end

sp.close
