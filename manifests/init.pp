# This class installs latest ssh server (though it almost always is already)
# Also triggers edits the config files per stanzas in hiera using augeas
class ssh(
  $sshd_config  = {},
  $ssh_config   = {},
  $install_mosh = true,
) {
  #require base  # doesn't actually require the base for anything

  # put this in a params class?  is that still a thing done with puppet?
  #  $package     = $ssh::params::package,
  #  $service     = $ssh::params::service,
  # i only use RHEL-clones and Ubuntu LTS at the moment
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

  package { $package:
    ensure  => 'latest',
  }
  service { $service:
    ensure  => 'running',
    enable  => true,
    require => Package[$package]
  }

  # these pull hash from hiera and dump it into augeas to edit config files
  # augeas will handle restart of sshd if file is updated
  create_resources(sshd_config, $sshd_config)
  create_resources(ssh_config, $ssh_config)

  # install mosh by default for more robust ssh
  if install_mosh {
    package { $mosh:
      ensure => 'latest',
    }
  }
}
