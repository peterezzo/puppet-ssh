class ssh (
    $ssh_package = "openssh-server",
    $ssh_daemon  = "ssh",
    $ports = [ '22' ],
){
    # lets install ssh
    package { "$ssh_package":
        ensure => "present",
        before => File['/etc/ssh/sshd_config'],
   }

   file { '/etc/ssh/sshd_config':
        ensure  => file,
        mode    => 600,
        content => template('ssh/sshd_config.erb'),
   }

    service { "$ssh_daemon":
        ensure    => running,
        enable    => true,
        subscribe => File['/etc/ssh/sshd_config'],
   }

}
