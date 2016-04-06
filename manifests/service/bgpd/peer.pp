# quagga::service::bgpd::peer
#
define quagga::service::bgpd::peer (
  $addr4          = [],
  $addr6          = [],
  $desc           = undef,
  $inbound_routes = 'none',
  $community      = undef,
  $localpref      = undef,
  $multihop       = undef,
  $password       = undef,
  $prepend        = undef,
) {
  validate_array($addr4)
  validate_array($addr6)
  validate_string($desc)
  validate_re($inbound_routes, '^(all|none|default)$')
  if $community { validate_array($community) }
  if $localpref { validate_integer($localpref) }
  if $multihop { validate_integer($multihop) }
  if $password { validate_string($password) }
  if $prepend { validate_integer($prepend) }
  $my_asn = $::quagga::service::bgpd::my_asn
  
  concat::fragment{"bgpd_peer_${name}":
    target  => $::quagga::service::bgpd::conf_file,
    content => template('quagga/bgpd.conf.peer.erb'),
    order   => 10,
  }
  concat::fragment{"bgpd_v6peer_${name}":
    target  => $::quagga::service::bgpd::conf_file,
    content => template('quagga/bgpd.conf.v6peer.erb'),
    order   => 40,
  }
  concat::fragment{ 'quagga_bgpd_routemap':
    target  => $conf_file,
    content => template('quagga/bgpd.conf.routemap.erb'),
    order   => 90,
  }
}
