# ------------------------------------------------------------------------
#   Copyright (c) 2017 CyberArk Software Inc.
#
#  calogger: Function to initialize CyberArk logger.
# ------------------------------------------------------------------------

require 'logger'

Puppet::Functions.create_function(:calogger) do
  def calogger(fname, max_size)
    if fname == ''
      logger = Logger.new(STDOUT)
    else
      File.delete(fname) if File.file?(fname) &&
                            File.stat(fname).size > max_size
      logger = Logger.new(File.open(fname, 'a'))
    end
    logger.debug('******** Started CyberArk Logger *******')
    logger.close
  end
end
