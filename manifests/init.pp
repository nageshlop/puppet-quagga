# Class: quagga
#
# Quagga routing server.
class quagga (
  String           $owner   = 'quagga',
  String           $group   = 'quagga',
  Pattern[/^\d+$/] $mode    = '0664',
  String           $package = 'quagga',
  Boolean          $enable  = true,
  String           $content = $::quagga::params::content,
) inherits ::quagga::params {

  ensure_packages([$package])
  file { '/etc/quagga/zebra.conf':
    ensure  => present,
    owner   => $owner,
    group   => $group,
    mode    => $mode,
    content => $content,
    require => Package[ $package ],
    notify  => Service['quagga'],
  }
  file {'/usr/local/bin/quagga_status.sh':
    ensure  => present,
    mode    => '0555',
    content => template('quagga/quagga_status.sh.erb'),
  }
  file {'/etc/profile.d/vtysh.sh':
    ensure => present,
    source => 'puppet:///modules/quagga/vtysh.sh'
  }

  service { 'quagga':
    ensure    => running,
    enable    => true,
    hasstatus => false,
    status    => '/usr/local/bin/quagga_status.sh',
    start     => '/etc/init.d/quagga restart',
    require   => [Package[ $package ],
      File['/etc/quagga/zebra.conf', '/usr/local/bin/quagga_status.sh'] ]
  }
  Ini_setting {
    ensure  => present,
    path    => '/etc/quagga/daemons',
    section => '',
    require => Package[ $package ],
    notify  => Service['quagga'],
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

