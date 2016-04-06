# quagga::bgpd::peer
#
define quagga::bgpd::peer (
  $addr4          = [],
  $addr6          = [],
  $desc           = undef,
  $inbound_routes = 'none',
  $communities    = [],
  $localpref      = undef,
  $multihop       = undef,
  $password       = undef,
  $prepend        = undef,
) {
  validate_array($addr4)
  validate_array($addr6)
  validate_string($desc)
  validate_re($inbound_routes, '^(all|none|default)$')
  if $communities { validate_array($communities) }
  if $localpref { validate_integer($localpref) }
  if $multihop { validate_integer($multihop) }
  if $password { validate_string($password) }
  if $prepend { validate_integer($prepend) }
  $my_asn = $::quagga::bgpd::my_asn
  
  concat::fragment{"bgpd_peer_${name}":
    target  => $::quagga::bgpd::conf_file,
    content => template('quagga/bgpd.conf.peer.erb'),
    order   => 10,
  }
  concat::fragment{"bgpd_v6peer_${name}":
    target  => $::quagga::bgpd::conf_file,
    content => template('quagga/bgpd.conf.v6peer.erb'),
    order   => 40,
  }
  concat::fragment{ 'quagga_bgpd_routemap':
    target  => $::quagga::bgpd::conf_file,
    content => template('quagga/bgpd.conf.routemap.erb'),
    order   => 90,
  }
  if $::quagga::bgpd::manage_nagios {
    if $::quagga::bgpd::enable_advertisements {
      if $::quagga::bgpd::enable_advertisements_v4 {
        quagga::bgpd::peer::nagios {$addr4:
          routes => concat($::quagga::bgpd::networks4, $::quagga::bgpd::failsafe_networks4),
        }
      }
      if $::quagga::bgpd::enable_advertisements_v6 {
        quagga::bgpd::peer::nagios {$addr6:
          routes => concat($::quagga::bgpd::networks6, $::quagga::bgpd::failsafe_networks6),
        }
      }
    }
  }
}
