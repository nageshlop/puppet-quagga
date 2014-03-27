# Class: quagga
#
# Quagga routing server.
#
# Parameters:
#  $ospfd_content:
#    Content (typically using a template) for the ospfd.conf file.
#  $ospfd_source:
#    Source location for the ospfd.conf file.
#
# Sample Usage :
#  class { 'quagga':
#    ospfd_content => template('mymodule/quagga/ospfd.conf.erb'),
#  }
#
class quagga (
  $owner   = $::quagga::params::owner,
  $group   = $::quagga::params::group,
  $mode    = $::quagga::params::mode,
  $content = $::quagga::params::quagga_content,
  $enable_zebra = $::quagga::params::enable_zebra,
) {

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

  service { 'quagga':
    ensure  => running,
    enable  => true,
    require => [Package[ $::quagga::params::package ],
      File['/etc/quagga/zebra.conf'] ]
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
        value   => 'on',
    }
  } else {
    ini_setting {
      'zebra':
        setting => 'zebra',
        value   => 'off',
    }
  }
  if defined(Class['::quagga::service::bgpd']) {
    ini_setting {
      'bgpd':
        setting => 'bgpd',
        value   => 'on',
    }
  } else {
    ini_setting {
      'bgpd':
        setting => 'bgpd',
        value   => 'off',
    }
  }
  if defined(Class['::quagga::service::ospfd']) {
    ini_setting {
      'ospfd':
        setting => 'ospfd',
        value   => 'on',
    }
  } else {
    ini_setting {
      'ospfd':
        setting => 'ospfd',
        value   => 'off',
    }
  }
}

