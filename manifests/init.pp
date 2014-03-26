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
    notify  => Service['zebra'],
  }

  service { 'zebra':
    ensure  => running,
    enable  => true,
    require => [Package[ $::quagga::params::package ],
      File['/etc/quagga/zebra.conf'] ]
  }
}

