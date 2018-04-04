
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

class cyberark_aim::environment(
    String $ensure = 'present',
    String $vault_username = '',
    String $vault_password = '',
    String $admin_credential_aim_appid = $cyberark_aim::params::admin_credential_aim_appid,
    String $admin_credential_aim_query = $cyberark_aim::params::admin_credential_aim_query,
    Boolean $use_shared_logon_authentication = $cyberark_aim::params::use_shared_logon_authentication,
    String $aim_path_log_file = $cyberark_aim::params::aim_path_log_file,
    String $provider_user_location = $cyberark_aim::params::provider_user_location,
    String $provider_safe_config = $cyberark_aim::params::provider_safe_config,
    String $provider_username = $cyberark_aim::params::provider_username,
    String $provider_user_groups = $cyberark_aim::params::provider_user_groups,
    Optional[String] $webservices_certificate_file = $cyberark_aim::params::webservices_certificate_file,
    String $webservices_sdk_baseurl = $cyberark_aim::params::webservices_sdk_baseurl,
) inherits cyberark_aim::params {

    $get_admin_info = { 'appId' => $admin_credential_aim_appid,
                        'query' => $admin_credential_aim_query,
                      }

    if ($ensure == 'present') {

        if ($cyberark_aim::environment::package_is_installed == false) {

            if ($use_shared_logon_authentication == false and
                $admin_credential_aim_query != '') {
                # Retrieve administrative credential
                $user_and_pwd = cyberark_credential($get_admin_info, $aim_path_log_file)
                $session_id = cyberark_new_session_id()
            } elsif $vault_username != '' and $vault_password != '' {
                $user_and_pwd = [$vault_username, $vault_password]
                $session_id = 1
            } elsif ($use_shared_logon_authentication == false) {
                notify {'Provide either admin_credential_aim_query or vault_username/vault_password or use_shared_logon_authentication': }
                fail('Provide either admin_credential_aim_query or vault_username/vault_password or use_shared_logon_authentication')
            } else {
                $user_and_pwd = ['','']
                $session_id = 0
            }

            $prov_user_pwd = cyberark_random_password()

            # Ensure Provider User is created.
            cyberark_user { $provider_username:
                ensure                          => 'present',
                base_url                        => $webservices_sdk_baseurl,
                #webservices_certificate_file => $certificate_file,
                use_shared_logon_authentication => $use_shared_logon_authentication,
                connection_number               => $session_id,
                login_username                  => $user_and_pwd[0],
                login_password                  => $user_and_pwd[1],
                initial_password                => $prov_user_pwd,
                groups_to_be_added_to           => $provider_user_groups,
                user_type_name                  => 'AppProvider',
                location                        => $provider_user_location,
            }

            # Create credential file for the new provider
            exec { 'createcred_exec' :
                command => "/opt/CARKaim/bin/createcredfile /etc/opt/CARKaim/vault/appprovideruser.cred Password \
                            -Username ${provider_username} -Password ${prov_user_pwd} \
                            -apptype AppPrv -hostname -displayrestrictions",
                cwd     => '/opt/CARKaim/bin/',
            }

        }

    } elsif ($ensure == 'absent') {

        if ($cyberark_aim::environment::package_is_installed) {

            if ($use_shared_logon_authentication == false and
                $admin_credential_aim_query != '') {
                # Retrieve administrative credential
                $user_and_pwd = cyberark_credential($get_admin_info, $aim_path_log_file)
                $session_id = cyberark_new_session_id()
            } elsif $vault_username != '' and $vault_password != '' {
                $user_and_pwd = [$vault_username, $vault_password]
                $session_id = 1
            } elsif ($use_shared_logon_authentication == false) {
                notify { 'Provide either admin_credential_aim_query or vault_username/vault_password or use_shared_logon_authentication': }
                fail('Provide either admin_credential_aim_query or vault_username/vault_password or use_shared_logon_authentication')
            } else {
                $user_and_pwd = ['','']
                $session_id = 0
            }

            # Ensure Provider user is removed.
            cyberark_user { $provider_username:
                ensure                          => 'absent',
                base_url                        => $webservices_sdk_baseurl,
                #webservices_certificate_file => $webservices_certificate_file,
                use_shared_logon_authentication => $use_shared_logon_authentication,
                connection_number               => $session_id,
                login_username                  => $user_and_pwd[0],
                login_password                  => $user_and_pwd[1],
            }
        }
    }
}
