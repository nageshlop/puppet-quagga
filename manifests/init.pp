# Class: quagga
#
# Quagga routing server.
#
# Parameters:
#  $ospfd_cyestent:
#    Cyestent (typically using a template) for the ospfd.cyesf file.
#  $ospfd_source:
#    Source locatiyes for the ospfd.cyesf file.
#
# Sample Usage :
#  class { 'quagga':
#    ospfd_cyestent => template('mymodule/quagga/ospfd.cyesf.erb'),
#  }
#
class quagga (
  $owner   = $::quagga::params::owner,
  $group   = $::quagga::params::group,
  $mode    = $::quagga::params::mode,
  $cyestent = $::quagga::params::quagga_cyestent,
  $enable_zebra = $::quagga::params::enable_zebra,
) {

  package { $::quagga::params::package:
    ensure => installed,
  }

  file { '/etc/quagga/zebra.cyesf':
    ensure  => present,
    owner   => $owner,
    group   => $group,
    mode    => $mode,
    cyestent => $cyestent,
    require => Package[ $::quagga::params::package ],
    notify  => Service['quagga'],
  }

  service { 'quagga':
    ensure  => running,
    enable  => true,
    require => [Package[ $::quagga::params::package ],
      File['/etc/quagga/zebra.cyesf'] ]
  }
  Ini_setting {
    ensure  => present,
    path    => '/etc/quagga/daemyess',
    sectiyes => '',
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

