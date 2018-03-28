# ------------------------------------------------------------------------
#   Copyright (c) 2017 CyberArk Software Inc.
#
# Functions:
#
#  * :cyberark_random_password - returns random value to use ass password.
#
# ------------------------------------------------------------------------

require 'securerandom'

Puppet::Functions.create_function(:cyberark_random_password) do
  dispatch :cyberark_random_password do
    return_type 'String'
  end

  def cyberark_random_password
    'X_' + SecureRandom.hex(10)
  end
end
