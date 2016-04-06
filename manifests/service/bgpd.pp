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
  $enable_advertisements    = true,
  $enable_advertisements_v4 = true,
  $enable_advertisements_v6 = true,
  $manage_nagios            = false,
  $peers                    = undef,
  $conf_file                = '/etc/quagga/bgpd.conf',
) {

  class { '::quagga': }

  validate_bool($manage_nagios)

  concat{$conf_file:
    require => Package[ $::quagga::package ],
    notify  => Service['quagga'],
  }
  concat::fragment{ 'quagga_bgpd_head':
    target  => $conf_file,
    content => template('quagga/bgpd.conf.head.erb'),
    order   => 01,
  }
  concat::fragment{ 'quagga_bgpd_v6head':
    target  => $conf_file,
    content => "!\naddress-family ipv6\n",
    order   => 30,
  }
  concat::fragment{ 'quagga_bgpd_v6foot':
    target  => $conf_file,
    content => template('quagga/bgpd.conf.v6foot.erb'),
    order   => 50,
  }
  concat::fragment{ 'quagga_bgpd_acl':
    target  => $conf_file,
    content => template('quagga/bgpd.conf.acl.erb'),
    order   => 90,
  }
  concat::fragment{ 'quagga_bgpd_foot':
    target  => $conf_file,
    content => "!\nline vty\n",
    order   => 99,
  }
  create_resources(quagga::service::bgpd::peer, $peers)
}

