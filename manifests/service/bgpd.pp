# Class: quagga::service::bgpd
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

