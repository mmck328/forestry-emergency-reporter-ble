# forestry-emergency-reporter-ble

Bidirectional BLE-LoRa gateway for forestry-emergency-reporter

## usage
### Preparation
```
gem install serialport
cd ble
npm install
cd ../
```

### Command line
```
sudo ruby ble-lora.rb
```

### Auto-run on wakeup
```
$ crontab -e
```
and add
```
@reboot sudo /home/pi/forestry-emergency-reporter-ble/launch.sh
```