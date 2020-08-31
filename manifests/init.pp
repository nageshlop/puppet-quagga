# Class: quagga
#
# Quagga routing server.
class quagga (
  String                       $owner   = 'quagga',
  String                       $group   = 'quagga',
  Pattern[/^\d+$/]             $mode    = '0664',
  String                       $package = 'quagga',
  String                       $service = 'quagga',
  Boolean                      $enable  = true,
  String                       $content = $::quagga::params::content,
  Optional[Stdlib::Ip_address] $bgp_listenon = undef
) inherits ::quagga::params {

  ensure_packages([$package])
  file { '/etc/quagga/zebra.conf':
    ensure  => file,
    owner   => $owner,
    group   => $group,
    mode    => $mode,
    content => $content,
    require => Package[ $package ],
    notify  => Service[ $service ],
  }
  file { '/etc/quagga/debian.conf':
    ensure  => file,
    owner   => $owner,
    group   => $group,
    mode    => $mode,
    content => template('quagga/debian.conf.erb'),
    require => Package[ $package ],
    notify  => Service[ $service ],
  }
  file {'/usr/local/bin/quagga_status.sh':
    ensure  => file,
    mode    => '0555',
    content => template('quagga/quagga_status.sh.erb'),
  }
  file {'/etc/profile.d/vtysh.sh':
    ensure => file,
    source => 'puppet:///modules/quagga/vtysh.sh',
  }

  service { $service:
    ensure    => running,
    enable    => true,
    hasstatus => false,
    status    => '/usr/local/bin/quagga_status.sh',
    require   => [
      Package[ $package ],
      File['/etc/quagga/zebra.conf', '/usr/local/bin/quagga_status.sh']
      ],
  }
  Ini_setting {
    ensure  => present,
    path    => '/etc/quagga/daemons',
    section => '',
    require => Package[ $package ],
    notify  => Service[ $service ],
  }
  if $enable {
    ini_setting {
      'zebra':
        setting => 'zebra',
        value   => 'yes',
    }
  } else {
    ini_setting {
      'zebra':
        setting => 'zebra',
        value   => 'no',
    }
  }
}

