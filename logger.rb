require 'fileutils'
require 'time'

class Logger
  LOG_FILE = nil

  def initialize(log_name)
    FileUtils.makedirs("./log/" + log_name)
    log_filename = "./log/send_log/" + Time.now().strftime("%Y%m%d-%H%M%S") + ".log" 
    LOG_FILE = File.open(log_filename, 'a')
    ObjectSpace.define_finalizer(self, proc { LOG_FILE.close()})
  end
  
  def log(x)
    f = "[#{Time.new}] #{x}"
    p f
    LOG_FILE.puts(f)
  end
end
