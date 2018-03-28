
include java

require 'securerandom'

# ------------------------------------------------------------------------------------------
#   Copyright (c) 2017 CyberArk Software Inc.
#
# Manifest of AIM module. It defines for puppet the steps that should be taken in order to
# (un)install the Credential Provider on the node.
# ------------------------------------------------------------------------------------------

# cyberark_aim::environment
#
# The aim::environment class makes sure the environment for the provider user is setup (if ensure == "present")
# by creating the user in CyberArk Vault with a random password and creating a credential file for it.
# It also makes sure the provider user is removed when ensure == "absent".
#

class cyberark_aim::environment {

    $get_admin_info = { 'appId' => $cyberark_aim::admin_credential_aim_appid,
                        'query' => $cyberark_aim::admin_credential_aim_query,
                      }

    if ($cyberark_aim::ensure == 'present') {

        if ($cyberark_aim::package_is_installed == false) {

            if ($cyberark_aim::use_shared_logon_authentication == false and
                $cyberark_aim::admin_credential_aim_query != '') {
                # Retrieve administrative credential
                $user_and_pwd = cyberark_credential($get_admin_info, $cyberark_aim::aim_path_log_file)
                $session_id = cyberark_new_session_id()
            } elsif $cyberark_aim::vault_username != '' and $cyberark_aim::vault_password != '' {
                $user_and_pwd = [$cyberark_aim::vault_username, $cyberark_aim::vault_password]
                $session_id = 1
            } elsif ($cyberark_aim::use_shared_logon_authentication == false) {
                notify {'Provide either admin_credential_aim_query or vault_username/vault_password or use_shared_logon_authentication': }
                fail('Provide either admin_credential_aim_query or vault_username/vault_password or use_shared_logon_authentication')
            } else {
                $user_and_pwd = ['','']
                $session_id = 0
            }

            $prov_user_pwd = cyberark_random_password()

            # Ensure Provider User is created.
            cyberark_user { $cyberark_aim::provider_username:
                base_url                        => $cyberark_aim::webservices_sdk_baseurl,
                #webservices_certificate_file => $cyberark_aim::certificate_file,
                use_shared_logon_authentication => $cyberark_aim::use_shared_logon_authentication,
                connection_number               => $session_id,
                login_username                  => $user_and_pwd[0],
                login_password                  => $user_and_pwd[1],
                initial_password                => $prov_user_pwd,
                groups_to_be_added_to           => $cyberark_aim::provider_user_groups,
                user_type_name                  => 'AppProvider',
                location                        => $cyberark_aim::provider_user_location,
            }

            # Create credential file for the new provider
            exec { 'createcred_exec' :
                command => "/opt/CARKaim/bin/createcredfile /etc/opt/CARKaim/vault/appprovideruser.cred Password \
                            -Username ${cyberark_aim::provider_username} -Password ${prov_user_pwd} \
                            -apptype AppPrv -hostname -displayrestrictions",
                cwd     => '/opt/CARKaim/bin/',
            }

        }

    } elsif ($cyberark_aim::ensure == 'absent') {

        if ($cyberark_aim::package_is_installed) {

            if ($cyberark_aim::use_shared_logon_authentication == false and
                $cyberark_aim::admin_credential_aim_query != '') {
                # Retrieve administrative credential
                $user_and_pwd = cyberark_credential($get_admin_info, $cyberark_aim::aim_path_log_file)
                $session_id = cyberark_new_session_id()
            } elsif $cyberark_aim::vault_username != '' and $cyberark_aim::vault_password != '' {
                $user_and_pwd = [$cyberark_aim::vault_username, $cyberark_aim::vault_password]
                $session_id = 1
            } elsif ($cyberark_aim::use_shared_logon_authentication == false) {
                notify { 'Provide either admin_credential_aim_query or vault_username/vault_password or use_shared_logon_authentication': }
                fail('Provide either admin_credential_aim_query or vault_username/vault_password or use_shared_logon_authentication')
            } else {
                $user_and_pwd = ['','']
                $session_id = 0
            }

            # Ensure Provider user is removed.
            cyberark_user { $cyberark_aim::provider_username:
                ensure                          => 'absent',
                base_url                        => $cyberark_aim::webservices_sdk_baseurl,
                #webservices_certificate_file => $cyberark_aim::webservices_certificate_file,
                use_shared_logon_authentication => $cyberark_aim::use_shared_logon_authentication,
                connection_number               => $session_id,
                login_username                  => $user_and_pwd[0],
                login_password                  => $user_and_pwd[1],
            }
        }
    }
}
