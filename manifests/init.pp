# Class: quagga
#
# Quagga routing server.
#
# Parameters:
#
# Sample Usage :
#  class { 'quagga':
#  }
#
class quagga (
  $owner        = $::quagga::params::owner,
  $group        = $::quagga::params::group,
  $mode         = $::quagga::params::mode,
  $content      = $::quagga::params::content,
  $package      = $::quagga::params::package,
  $enable_zebra = $::quagga::params::enable_zebra,
) inherits quagga::params {

  ensure_package($package)
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
    source => "puppet:///modules/quagga/vtysh.sh"
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
  if $enable_zebra {
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
  if defined(Class['::quagga::service::bgpd']) {
    ini_setting {
      'bgpd':
        setting => 'bgpd',
        value   => 'yes',
    }
  } else {
    ini_setting {
      'bgpd':
        setting => 'bgpd',
        value   => 'no',
    }
  }
  if defined(Class['::quagga::service::ospfd']) {
    ini_setting {
      'ospfd':
        setting => 'ospfd',
        value   => 'yes',
    }
  } else {
    ini_setting {
      'ospfd':
        setting => 'ospfd',
        value   => 'no',
    }
  }
}

