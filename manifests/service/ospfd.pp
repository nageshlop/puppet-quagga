# Class: quagga::service::ospfd
#
# Quagga routing server.
#
# Parameters:
#  $content:
#    Content (typically using a template) for the ospfd.conf file.
#
# Sample Usage :
#  class { 'quagga::service::ospfd':
#    content => template('mymodule/quagga/ospfd.conf.erb'),
#  }
#
class quagga::service::ospfd (
  $content = undef,
) {

  include $::quagga::params
  unless $content {
    $content = $::quagga::params::ospfd_content
  }
  class { 'quagga::service':
    service  => 'ospfd',
    content  => $content
  }
}

