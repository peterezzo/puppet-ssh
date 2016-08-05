# This class installs latest ssh server and ensures it is running
# Also triggers edits the config files per stanzas in hiera using augeas
# these stanzas MUST be defined in hiera and are merged from multiple levels
# with hiera_hash call, not overwritten by most specific
# configure_sudo - install a file to use user's ssh agent via sudo
class ssh(
  $configure_sudo    = true,
  $file_sudoenv_path = '/etc/sudoers.d/ssh_agent'
) {
  #  $package     = $ssh::params::package,
  #  $service     = $ssh::params::service,
  # only support RHEL-clones and Ubuntu LTS at the moment
  case $::osfamily {
    'Debian': {
      $package = 'openssh-server'
      $service = 'ssh'
    }
    'RedHat': {
      $package = 'openssh-server'
      $service = 'sshd'
    }
    default: {
      fail("The ${module_name} module is not supported on an ${::osfamily} based system.")
    }
  }

  package { 'openssh-server':
    ensure => 'latest',
    name   => $package,
  }
  service { 'sshd':
    ensure  => 'running',
    name    => $service,
    enable  => true,
    require => Package['openssh-server']
  }

  # these pull hash from hiera and dump it into augeas to edit config files
  # augeas will handle restart of sshd if file is updated
  # TODO: make hiera optional
  $sshd_config = hiera_hash("${module_name}::sshd_config",{})
  create_resources(sshd_config, $sshd_config)
  $ssh_config = hiera_hash("${module_name}::ssh_config",{})
  create_resources(ssh_config, $ssh_config)

  # make sudo push work
  if $configure_sudo {
    file { $file_sudoenv_path:
      ensure => present,
      mode   => '0440',
      source => "puppet:///modules/${module_name}/sudoers-ssh_agent"
    }
  }
}
