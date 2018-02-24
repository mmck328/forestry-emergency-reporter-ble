require 'fileutils'
require 'time'

class Logger
  BASE_PATH = __dir__ + '/log/'
  def initialize(log_name)
    logging_file_name = Time.now().strftime("%Y%m%d-%H%M%S") + ".log" 
    logging_path = File.join(BASE_PATH, log_name, logging_file_name)

    FileUtils.makedirs(File.expand_path('..', logging_path))

    @log_file = File.open(logging_path, 'a')
    ObjectSpace.define_finalizer(self, proc { @log_file.close()})

    log "logging to #{logging_path}"
  end
  
  def log(x)
    t = Time.new.strftime("%F %T.%L")
    f = "[#{t}] #{x}"
    p f
    @log_file.puts(f)
  end
end
