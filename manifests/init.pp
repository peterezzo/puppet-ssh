# This class installs latest ssh server and ensures it is running
# Also triggers edits the config files per stanzas in hiera using augeas
# these stanzas MUST be defined in hiera and are merged from multiple levels
# with hiera_hash call, not overwritten by most specific
class ssh(
  $install_mosh = true,
) {
  require base  # dns/proxy setup in base

  # put this in a params class?  is that still a thing done with puppet?
  #  $package     = $ssh::params::package,
  #  $service     = $ssh::params::service,
  # only support RHEL-clones and Ubuntu LTS at the moment
  case $::osfamily {
    'Debian': {
      $package = 'openssh-server'
      $service = 'ssh'
      $mosh    = 'mosh'
    }
    'RedHat': {
      $package = 'openssh-server'
      $service = 'sshd'
      $mosh    = 'mosh'
    }
    default: {
      fail("The ${module_name} module is not supported on an ${::osfamily} based system.")
    }
  }

  package { 'openssh-server':
    name    => $package,
    ensure  => 'latest',
  }
  service { 'sshd':
    name    => $service,
    ensure  => 'running',
    enable  => true,
    require => Package['openssh-server']
  }

  # these pull hash from hiera and dump it into augeas to edit config files
  # augeas will handle restart of sshd if file is updated
  $sshd_config = hiera_hash("${module_name}::sshd_config",{})
  $ssh_config = hiera_hash("${module_name}::ssh_config",{})
  create_resources(sshd_config, $sshd_config)
  create_resources(ssh_config, $ssh_config)

  # install mosh by default for more robust ssh
  if install_mosh {
    package { $mosh:
      ensure => 'latest',
    }
  }
}
