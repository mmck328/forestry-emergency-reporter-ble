require 'rubygems'
require 'serialport'
require 'fileutils'
require './logger'

$serial_port = '/dev/ttyUSB0'
#$serial_port = '/dev/ttyAMA0'
$serial_baudrate = 115200
$serial_databit = 8
$serial_stopbit = 1
$serial_paritycheck = 0
$serial_delimiter = "\r\n"

sp = SerialPort.new($serial_port, $serial_baudrate, $serial_databit, $serial_stopbit, $serial_paritycheck)
sp.read_timeout=1000 

logger = Logger.new('capture_log')

while true
  incoming = sp.gets("#{ $serial_delimiter }")
  if incoming
    logger.log(incoming)
  end
end

file.close
sp.close
