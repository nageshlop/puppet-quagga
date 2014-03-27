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
  $owner_real = $owner ? {
    undef   => $::quagga::params::owner,
    default => $owner,
  }
  $group_real = $group ? {
    undef   => $::quagga::params::group,
    default => $group,
  }
  $mode_real = $mode ? {
    undef   => $::quagga::params::mode,
    default => $mode,
  }
  $content_real = $content ? {
    undef   => $::quagga::params::content,
    default => $content,
  }
  $enable_zebra_real = $enable_zebra ? {
    undef   => $::quagga::params::enable_zebra,
    default => $enable_zebra,
  }

  package { $::quagga::params::package:
    ensure => installed,
  }
  file { '/etc/quagga/zebra.conf':
    ensure  => present,
    owner   => $real_owner,
    group   => $real_group,
    mode    => $real_mode,
    content => $real_content,
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
  if $real_enable_zebra {
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

