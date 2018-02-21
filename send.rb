require 'rubygems'
require 'serialport'

$serial_port = '/dev/ttyUSB0'
#$serial_port = '/dev/ttyAMA0'
$serial_baudrate = 115200
$serial_databit = 8
$serial_stopbit = 1
$serial_paritycheck = 0
$serial_delimiter = "\r\n"

sp = SerialPort.new($serial_port, $serial_baudrate, $serial_databit, $serial_stopbit, $serial_paritycheck)
sp.read_timeout=-1 

pattern=/GNGGA/
file=File.open("/dev/ttyACM0")

INTERVAL = 5

DEVICE_CONF = {} #deviceid

File.foreach('device.conf') do |text|
    key = text.split('=')[0]
    val = text.split('=')[1].chomp
    DEVICE_CONF[key] = val
end
p DEVICE_CONF

PAN_ID = DEVICE_CONF['panid']
DEVICE_ID = DEVICE_CONF['deviceid']
NEXT_DEVICE_ID = format("%04X", (DEVICE_ID.to_i(base=16) - 1))

GW_ID = '0000'

count = 0
file.each_line do |text|
  if pattern =~ text
    if count % INTERVAL == 0
      a=text.split(",")
      msg=a[1]+","+(a[2].to_f/100.0).to_s+","+(a[4].to_f/100.0).to_s
      pktid = format("%04X", (count / INTERVAL) % 0xffff)
      payload = DEVICE_ID + GW_ID + pktid + msg
      p payload
      
      sp.write PAN_ID + NEXT_DEVICE_ID + payload + $serial_delimiter
    end
    count += 1
  end
  loop do
    str = sp.gets($serial_delimiter)
    break unless str 
    p str
  end
end

sp.close
