# Class: quagga::bgpd
#
class quagga::bgpd (
  $my_asn                   = undef,
  $router_id                = undef,
  $enable                   = true,
  $networks4                = [],
  $failsafe_networks4       = [],
  $networks6                = [],
  $failsafe_networks6       = [],
  $failover_server          = false,
  $enable_advertisements    = true,
  $enable_advertisements_v4 = true,
  $enable_advertisements_v6 = true,
  $manage_nagios            = false,
  $conf_file                = '/etc/quagga/bgpd.conf',
  $peers                    = {},
) {

  include quagga

  validate_integer($my_asn)
  validate_ip_address($router_id)
  validate_bool($enable)
  validate_array($networks4)
  validate_array($failsafe_networks4)
  validate_array($networks6)
  validate_array($failsafe_networks6)
  validate_bool($failover_server)
  validate_bool($enable_advertisements)
  validate_bool($enable_advertisements_v4)
  validate_bool($enable_advertisements_v6)
  validate_bool($manage_nagios)
  validate_absolute_path($conf_file)
  validate_hash($peers)

  Ini_setting {
    path    => '/etc/quagga/daemons',
    section => '',
    notify  => Service['quagga'],
  }
  if $enable {
    ini_setting {'bgpd':
      setting => 'bgpd',
      value   => 'yes',
    }
  } else {
    ini_setting {'bgpd':
      setting => 'bgpd',
      value   => 'no',
    }
  }
  concat{$conf_file:
    require => Package[ $::quagga::package ],
    notify  => Service['quagga'],
  }
  concat::fragment{ 'quagga_bgpd_head':
    target  => $conf_file,
    content => template('quagga/bgpd.conf.head.erb'),
    order   => '01',
  }
  concat::fragment{ 'quagga_bgpd_v6head':
    target  => $conf_file,
    content => "!\n address-family ipv6\n",
    order   => '30',
  }
  concat::fragment{ 'quagga_bgpd_v6foot':
    target  => $conf_file,
    content => template('quagga/bgpd.conf.v6foot.erb'),
    order   => '50',
  }
  concat::fragment{ 'quagga_bgpd_acl':
    target  => $conf_file,
    content => template('quagga/bgpd.conf.acl.erb'),
    order   => '80',
  }
  concat::fragment{ 'quagga_bgpd_foot':
    target  => $conf_file,
    content => "line vty\n!\n",
    order   => '99',
  }
  create_resources(quagga::bgpd::peer, $peers)
}

