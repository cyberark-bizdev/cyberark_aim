# ------------------------------------------------------------------------------------------
#   Copyright (c) 2016 CyberArk Software Inc.
#
# Manifest of AIM module. It defines for puppet the steps that should be taken in order to
# (un)install the Credential Provider on the node.
# ------------------------------------------------------------------------------------------

# cyberark_aim::service
#
# The cyberark_aim::service class makes sure the service is running in case ensure == "present".
#

class cyberark_aim::service {

    if ($cyberark_aim::ensure == 'present') {

        service { 'aimprv':
            ensure   => running,
            provider => 'redhat',
        }

    }
}
