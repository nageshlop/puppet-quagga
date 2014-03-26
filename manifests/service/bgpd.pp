# Class: quagga::service::bgpd
#
# Quagga routing server.
#
# Parameters:
#  $content:
#    Content (typically using a template) for the bgpd.conf file.
#
# Sample Usage :
#  class { 'quagga::service::bgpd':
#    content => template('mymodule/quagga/bgpd.conf.erb'),
#  }
#
class quagga::service::bgpd (
  $content = $::quagga::params::bgpd_content,
  $router_id = undef,
  $networks4 = undef,
  $networks6 = undef,
  $peers     = undef,
) {

  class { 'quagga::service':
    service  => 'bgpd',
    content  => $content
  }
}

