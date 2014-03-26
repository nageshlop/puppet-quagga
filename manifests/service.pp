# Class: quagga
#
# Quagga routing server.
#
# Parameters:
#  $service:
#    The name of the quagga service to enable
#  $content:
#    Content (typically using a template) for the ospfd.conf file.
#
# Sample Usage :
#  class { 'quagga':
#    ospfd_content => template('mymodule/quagga/ospfd.conf.erb'),
#  }
#
class quagga::service (
  $content = undef,
  $service = undef,
) {

  include quagga::params
  class { 'quagga::': }

  service { $service:
    ensure  => running,
    require => [ Service['zebra'], File["/etc/quagga/${service}.conf"] ],
    enable  => true,
  }
  file { "/etc/quagga/${service}.conf":
    content => $content,
    require => Package['quagga'],
    notify  => Service[$service],
  }

}

