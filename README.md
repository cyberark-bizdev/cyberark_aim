# cyberark_aim

#### Table of Contents


1. [Module Description - What the module does and why it is useful](#module-description)
1. [Setup - The basics of getting started with aim::provider](#setup)
1. [Usage - Configuration options and additional functionality](#usage)
1. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
1. [Limitations - OS compatibility, etc.](#limitations)
1. [Development - Guide for contributing to the module](#development)


## Module description

The aim::provider module installs, configures, and manages the CyberArk AIM Credential Provider.
This includes the binary package, configuration file, service and provider user environment in CyberArk.

## Setup

### Beginning with aim::provider


## Usage


## Reference

### Classes

#### Public classes

* cyberark_aim: Main class, includes all other classes.

#### Private classes

* cyberark_aim::params - Defines the parameters and default values for the AIM module.
* cyberark_aim::package - Handles the AIM Povider package.
* cyberark_aim::environment - Handles the configuration environment in CyberArk vault.
* cyberark_aim::service -  Handles the AIM Provider (aimprv) service.

### Parameters

The following parameters are available in the ::aim:provider class:

## Limitations


## Development

Puppet modules on the Puppet Forge are open projects, and community contributions are essential for keeping them great. Please follow our guidelines when contributing changes.

For more information, see our [module contribution guide.](https://docs.puppetlabs.com/forge/contributing.html)

### Contributors

To see who's already involved, see the [list of contributors.](https://github.com/puppetlabs/puppetlabs-ntp/graphs/contributors)
