
# ------------------------------------------------------------------------------------------
#   Copyright (c) 2017 CyberArk Software Inc.
#
# Manifest of AIM module. It defines for puppet the steps that should be taken in order to
# (un)install the Credential Provider on the node.
# ------------------------------------------------------------------------------------------

# cyberark_aim::test
#
#

class cyberark_aim::test inherits cyberark_aim::params {

    if ($cyberark_aim::test::package_is_installed == true) {
      $get_admin_info = { 'appId' => 'PuppetTest',
                          'query' => 'Safe=CyberArk Passwords;Folder=Root;Object=AdminPass',
                        }

      $user_and_pwd = cyberark_credential($get_admin_info, '/tmp/deployTest.log')

      notify { "***** User=${user_and_pwd[0]} and Password=${user_and_pwd[1]}": }
    } else {
      notify { 'AIM Package is not installed!': }
    }

}
