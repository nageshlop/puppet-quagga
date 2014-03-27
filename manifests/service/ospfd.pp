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

  $content_real = $content ? {
    undef   => $::quagga::params::ospfd_content,
    default => $content,
  }

  class { 'quagga::service':
    service  => 'ospfd',
    content  => $content_real,
  }
}

