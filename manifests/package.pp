
# ------------------------------------------------------------------------------------------
#   Copyright (c) 2017 CyberArk Software Inc.
#
# Manifest of AIM module. It defines for puppet the steps that should be taken in order to
# (un)install the Credential Provider on the node.
# ------------------------------------------------------------------------------------------

# cyberark_aim::package
#
# The cyberark_aim::package class makes sure the AIM provider package (along with configuration files) is installed
# when ensure == "present", it will unzip distribution, setup parameters in configuration files, setup
# permissions on files, and installs the distribution package.
# In case of ensure == "absent", it will uninstall the CARKaim package and remove distribution folders.
#

class cyberark_aim::package(
    String $ensure = 'present',
    String $aim_distribution_file = $cyberark_aim::params::aim_distribution_file,
    String $aim_folder_within_distribution = $cyberark_aim::params::aim_folder_within_distribution,
    String $distribution_source_path = $cyberark_aim::params::distribution_source_path,
    String $aim_temp_install_path = $cyberark_aim::params::aim_temp_install_path,
    String $provider_safe_config = $cyberark_aim::params::provider_safe_config,
    String $main_app_provider_conf_file = $cyberark_aim::params::main_app_provider_conf_file,
    String $aim_rpm_to_install = $cyberark_aim::params::aim_rpm_to_install,
    String $vault_address = $cyberark_aim::params::vault_address,
    Integer $vault_port = $cyberark_aim::params::vault_port,
) inherits  cyberark_aim::params {

    # notify {"CyberArk package_is_installed [${package_is_installed}]": withpath => true}

    if ($ensure == 'present') {

        if ($cyberark_aim::package::package_is_installed == false) {


            if ($aim_folder_within_distribution == '') {
                $folder_within_archive = $aim_distribution_file.split('-')[0]
            } else {
                $folder_within_archive = $aim_folder_within_distribution
            }

            $tmp_directory = $aim_temp_install_path
            $aim_file_archive = $aim_distribution_file

            $full_path = "${tmp_directory}/${aim_file_archive}"

            # conditional logic with exec where if the folder exists then go to remove, and then straight to creation

            exec { 'remove_temp_folder_ifexists':
                path    => '/bin',
                command => "rm -fr ${tmp_directory} ",
                onlyif  => "test -d ${tmp_directory}",
            }

            # make dir temporary folder
            file {'create_directory':
                ensure  => 'directory',
                path    => $tmp_directory,
                require => Exec['remove_temp_folder_ifexists'],
            }

            file { 'deliver_file':
                path    => $full_path,
                mode    => '0700',
                owner   => root,
                group   => root,
                source  => "${distribution_source_path}/${aim_file_archive}",
                require => File['create_directory'],
            }

            archive { 'extract_install_files':
                path         => $full_path,
                extract      => true,
                extract_path => $tmp_directory,
                creates      => "${tmp_directory}/${folder_within_archive}",
                require      => File['deliver_file'],
            }

            # chmod CreateCredFile to executable
            file { 'change_createcredfile':
                path    => "${tmp_directory}/CreateCredFile",
                mode    => '0700',
                require => Archive['extract_install_files'],
            }

            file { 'copy_aimparms':
                ensure  => present,
                path    => '/var/tmp/aimparms',
                source  => "${tmp_directory}/${folder_within_archive}/aimparms.sample",
                require => File['change_createcredfile'],
            }

            # Changes to /var/tmp/aimparms
            ini_setting { 'AcceptCyberArkEULA':
                ensure  => present,
                section => 'Main',
                setting => 'AcceptCyberArkEULA',
                value   => 'Yes',
                path    => '/var/tmp/aimparms',
                require => File['copy_aimparms'],
            }

            # Changes to /var/tmp/aimparms
            ini_setting { 'LicensedProducts':
                ensure  => present,
                section => 'Main',
                setting => 'LicensedProducts',
                value   => 'AIM',
                path    => '/var/tmp/aimparms',
                require => File['copy_aimparms'],
            }

            # Changes to /var/tmp/aimparms
            ini_setting { 'CreateVaultEnvironment':
                ensure  => present,
                section => 'Main',
                setting => 'CreateVaultEnvironment',
                value   => 'No',
                path    => '/var/tmp/aimparms',
                require => File['copy_aimparms'],
            }

            # Changes to /var/tmp/aimparms
            ini_setting { 'VaultFilePath':
                ensure  => present,
                section => 'Main',
                setting => 'VaultFilePath',
                value   => "${tmp_directory}/${folder_within_archive}/Vault.ini",
                path    => '/var/tmp/aimparms',
                require => File['copy_aimparms'],
            }

            # Changes to /var/tmp/aimparms
            ini_setting { 'MainAppProviderConfFile':
                ensure  => present,
                section => 'Main',
                setting => 'MainAppProviderConfFile',
                value   => $main_app_provider_conf_file,
                path    => '/var/tmp/aimparms',
                require => File['copy_aimparms'],
            }

            # Install Package
            package { 'CARKaim':
                ensure   => installed,
                source   => "${tmp_directory}/${folder_within_archive}/${aim_rpm_to_install}",
                provider => 'rpm',
                require  => Ini_setting['VaultFilePath'],
            }

            # Copy file vault.ini to /etc/opt/CARKaim/vault
            file { 'CopyVaultConfigFileParams':
                ensure  => present,
                path    => '/etc/opt/CARKaim/vault/vault.ini',
                source  => "${tmp_directory}/${folder_within_archive}/Vault.ini",
                require => Package['CARKaim'],
            }


            # Changes to /etc/opt/CARKaim/vault/vault.ini
            ini_setting { 'UpdateVaultAddress':
                ensure  => present,
                section => '',
                setting => 'ADDRESS',
                value   => $vault_address,
                path    => '/etc/opt/CARKaim/vault/vault.ini',
                require => File['CopyVaultConfigFileParams'],
            }

            # Changes to /etc/opt/CARKaim/vault/vault.ini
            ini_setting { 'UpdateVaultPort':
                ensure  => present,
                section => '',
                setting => 'PORT',
                value   => $vault_port,
                path    => '/etc/opt/CARKaim/vault/vault.ini',
                require => File['CopyVaultConfigFileParams'],
            }

            if ($main_app_provider_conf_file != '') {
                # Changes to /etc/opt/CARKaim/conf/basic_appprovider.conf
                ini_setting { 'modifyBasicAppPrvConfig':
                    ensure  => present,
                    section => 'Main',
                    setting => 'AppProviderVaultParmsFile',
                    value   => $main_app_provider_conf_file,
                    path    => '/etc/opt/CARKaim/conf/basic_appprovider.conf',
                    require => File['CopyVaultConfigFileParams'],
                }
            }

            # delete unconditionally (no 'require') temporary folder
            exec {'remove_unconditionally_tmp_directory':
                command => "/bin/rm -rf ${tmp_directory}",
                cwd     =>'/tmp/',
                require => File['CopyVaultConfigFileParams'],
            }

        } else {
            # packaged is already installed
            notify {'CyberArk AIM Package is already installed': withpath => true}
        }

    } elsif ($ensure == 'absent') {

        if ($cyberark_aim::package::package_is_installed) {
            # Uninstall Package
            package { 'CARKaim':
                ensure   => 'absent',
                provider => 'rpm',
            }

            # delete unconditionally (no 'require') /etc/opt/CARKaim
            exec {'/bin/rm -rf /etc/opt/CARKaim  ':
                cwd     =>'/tmp/',
                require => Package['CARKaim'],
            }

            # delete unconditionally (no 'require') /var/opt/CARKaim
            exec {'/bin/rm -rf /var/opt/CARKaim  ':
                cwd     =>'/tmp/',
                require => Package['CARKaim'],
            }
        } else {
            # packaged is not installed
            notify {'CyberArk AIM Package is not installed': withpath => true}
        }

    }

}
