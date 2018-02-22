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
sp.read_timeout=10 

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

GPS_PATTERN=/GNGGA/
GPS=File.open("/dev/ttyACM0")
INTERVAL = 5

FileUtils.makedirs("./log/send_log")
LOG_FILENAME = "./log/send_log/" + Time.now().strftime("%Y%m%d-%H%M%S") + ".log" 
LOG_FILE = File.open(LOG_FILENAME, 'a')

def log(text)
  p text
  LOG_FILE.puts(text)
end

def format_gps(text)
  a = text.split(',')
  lath, latm = a[2][0..1].to_i, a[2][2..8].to_f
  lngh, lngm = a[4][0..2].to_i, a[4][3..9].to_f
  lat = format("%.6f", lath + latm / 60)
  lng = format("%.6f", lngh + lngm / 60)
  msg = a[1] + "," + lat + "," + lng
end

count = 0
GPS.each_line do |text|
  if GPS_PATTERN =~ text
    if count % INTERVAL == 0
      msg = format_gps(text)
      pktid = format("%04X", (count / INTERVAL) % 0xffff)

      payload = DEVICE_ID + GW_ID + pktid + msg

      log payload
      sp.write PAN_ID + NEXT_DEVICE_ID + payload + $serial_delimiter
    end
    count += 1
  end
  loop do
    str = sp.gets($serial_delimiter)
    break unless str 
    log str
  end
end

sp.close
