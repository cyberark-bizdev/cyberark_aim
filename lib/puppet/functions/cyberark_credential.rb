# ------------------------------------------------------------------------
#   Copyright (c) 2017 CyberArk Software Inc.
#
# Functions:
#
#  * :cyberark_credential - invokes CyberArk AIM CLI to retrieve
#                           credential with the passed parameters.
#
# ------------------------------------------------------------------------
require 'logger'
require 'open3'

Puppet::Functions.create_function(:cyberark_credential) do
  dispatch :cyberark_credential do
    param 'Hash', :pwd_admin_info
    param 'String', :full_log_file_name # optional
    return_type 'Array[String]'
  end

  def cyberark_credential(pwd_admin_info, full_log_file_name)
    @pwd_admin_info = pwd_admin_info

    @logger = if full_log_file_name == ''
                Logger.new(STDOUT)
              else
                Logger.new(full_log_file_name)
              end

    @logger.info('Retrieve administrative credential for deployment via CLIPASSWORDSDK with the following query:')

    @clipasswordsdk_cmd = ENV['AIM_CLIPASSWORDSDK_CMD'] || '/opt/CARKaim/sdk/clipasswordsdk'

    @query = ''

    if @pwd_admin_info.key? 'query'
      @query = @pwd_admin_info['query']
    else
      if @pwd_admin_info.key? 'safe'
        @query = 'safe=' + @pwd_admin_info['safe'] + ';'
      end
      if @pwd_admin_info.key? 'folder'
        @query = @query + 'folder=' + @pwd_admin_info['folder'] + ';'
      end
      if @pwd_admin_info.key? 'object'
        @query = @query + 'object=' + @pwd_admin_info['object'] + ';'
      end
    end

    @full_cmd = "#{@clipasswordsdk_cmd} GetPassword -p AppDescs.AppId=\"#{@pwd_admin_info['appId']}\" -p Query=\"#{@query}\" -o PassProps.UserName,Password"

    result = []

    begin
      @logger.info('To execute = ' + @full_cmd)
      #      Open3.popen3(@full_cmd) do |stdin, stdout, stderr, wait_thr|
      Open3.popen3(@clipasswordsdk_cmd,
                   'GetPassword',
                   '-p',
                   "AppDescs.AppId=#{@pwd_admin_info['appId']}",
                   '-p',
                   "Query=#{@query}",
                   '-o',
                   'PassProps.UserName,Password') do |_stdin, stdout, stderr, wait_thr|
        @logger.info('****')
        exit_status = wait_thr.value
        unless exit_status.success?
          error_msg = "#{@full_cmd}\n"
          stderr.each_line do |line|
            error_msg = "#{error_msg}\n#{line}"
          end
          abort error_msg
        end
        line = stdout.gets
        result = line.delete("\n").split(',')
      end

      @logger.debug(' Result = ' + result[0])

      return result
    rescue StandardError => e
      @logger.error('GetPass() : Got Exception on call to GetPassword :' + e.message)
      raise e
    end
  end
end
