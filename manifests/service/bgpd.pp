# Class: quagga::service::bgpd
#
# BGPd for the Quagga routing server.
#
# Parameters:
#  $content:
#    Content (typically using a template) for the bgpd.conf file.
#  $router_id:
#    The router id to use
#  $networks4:
#    an array of ipv4 networks to advertise
#  $networks6:
#    an array of ipv6 networks to advertise
#  $hultihop:
#    the hop count for a multihop peering
#  $enable_advertisements:
#    boolean to indecate if we should advertise networks
#  $peers:
#    A hash of peers to configure of the form
#    AS_Number :
#        addr4:
#             - 1st ipv4 neighbour address
#             - 2nd ipv4 neighbour address
#        addr6:
#             - 1st ipv6 neighbour address
#             - 2nd ipv6 neighbour address
#        localpref: the local pref to assign prefix recived
#
# Sample Usage :
#  class { 'quagga::service::bgpd':
#    myasn                 => 65535,
#    router_id             => '192.0.2.1',
#    networks4             => ['192.0.2.0/24'],
#    networks6             => ['2001:DB8::/32'],
#    enable_advertisements => true,
#    peers                          => { 65536 => {
#                                   addr4 => ['192.0.2.2'],
#                                   addr6 => ['2001:DB8::1'],
#                                   multihop => 5,
#                                   localpref => 120 } }
#    content               => template('mymodule/quagga/bgpd.conf.erb'),
#  }
#
class quagga::service::bgpd (
  $my_asn                   = undef,
  $router_id                = undef,
  $networks4                = [],
  $failsafe_networks4       = [],
  $networks6                = [],
  $failsafe_networks6       = [],
  $failover_server          = false,
  $multihop                 = undef,
  $localpref                = undef,
  $community                = undef,
  $inbound_routes           = undef,
  $enable_advertisements    = true,
  $enable_advertisements_v4 = true,
  $enable_advertisements_v6 = true,
  $peers                    = undef,
  $content                  = undef,
) {

  include quagga::params

  $content_real = $content ? {
    undef   => $::quagga::params::bgpd_content,
    default => $content,
  }

  class { 'quagga::service':
    service  => 'bgpd',
    content  => template($content_real)
  }
}

