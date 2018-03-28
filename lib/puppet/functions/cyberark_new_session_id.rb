# ------------------------------------------------------------------------
#   Copyright (c) 2017 CyberArk Software Inc.
#
# Functions:
#
#  * :cyberark_new_session_id - returns a new session id from 1-100
#
# ------------------------------------------------------------------------
Puppet::Functions.create_function(:cyberark_new_session_id) do
  dispatch :cyberark_new_session_id do
    return_type 'Integer'
  end

  def cyberark_new_session_id
    sid = 0
    # Use file lock mechanism for atomic sessionId allocation. Range is 1-100
    # (Some OSs might not support flock)
    File.open('/tmp/counter_aim_sessionid',
              File::RDWR | File::CREAT, 0o644) do |f|
      f.flock(File::LOCK_EX)
      sid = (f.read.to_i % 100) + 1
      f.rewind
      f.write("#{sid}\n")
      f.flush
      f.truncate(f.pos)
    end
    sid
  end
end
