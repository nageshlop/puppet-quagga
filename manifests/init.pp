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
  $owner   = undef,
  $group   = undef,
  $mode    = undef,
  $content = undef,
  $enable_zebra = undef,
) {

  include $::quagga::params
  unless $owner {
    $owner   = $::quagga::params::owner
  }
  unless $group {
    $group   = $::quagga::params::group
  }
  unless $mode {
    $mode    = $::quagga::params::mode
  }
  unless $content {
    $content = $::quagga::params::quagga_content
  }
  unless $enable_zebra {
    $enable_zebra = $::quagga::params::enable_zebra
  }

  package { $::quagga::params::package:
    ensure => installed,
  }
  file { '/etc/quagga/zebra.conf':
    ensure  => present,
    owner   => $owner,
    group   => $group,
    mode    => $mode,
    content => $content,
    require => Package[ $::quagga::params::package ],
    notify  => Service['quagga'],
  }
  file {'/usr/local/bin/quagga_status.sh':
    ensure  => present,
    mode    => '0555',
    content => template('quagga/quagga_status.sh.erb'),
  }

  service { 'quagga':
    ensure    => running,
    enable    => true,
    hasstatus => false,
    status    => '/usr/local/bin/quagga_status.sh',
    require   => [Package[ $::quagga::params::package ],
      File['/etc/quagga/zebra.conf', '/usr/local/bin/quagga_status.sh'] ]
  }
  Ini_setting {
    ensure  => present,
    path    => '/etc/quagga/daemons',
    section => '',
    require => Package[ $::quagga::params::package ],
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

