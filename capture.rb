require 'rubygems'
require 'serialport'
require 'fileutils'

$serial_port = '/dev/ttyUSB0'
#$serial_port = '/dev/ttyAMA0'
$serial_baudrate = 115200
$serial_databit = 8
$serial_stopbit = 1
$serial_paritycheck = 0
$serial_delimiter = "\r\n"

sp = SerialPort.new($serial_port, $serial_baudrate, $serial_databit, $serial_stopbit, $serial_paritycheck)
sp.read_timeout=1000 

FileUtils.makedirs("./log/capture_log")
filename = "./log/capture_log/" + Time.now().strftime("%Y%m%d-%H%M%S") + ".txt" 
file = File.open(filename, 'a')
while true
  incoming = sp.gets("#{ $serial_delimiter }")
  if incoming
    p incoming
    file.puts(incoming)
  end
end

file.close
sp.close
