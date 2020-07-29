# Class: quagga::bgpd
#
class quagga::bgpd (
  Integer[1,4294967295]           $my_asn                   = undef,
  Stdlib::Ipv4                    $router_id                = undef,
  Boolean                         $enable                   = true,
  Boolean                         $stage_config             = false,
  Optional[Array[Tea::Ipv4_cidr]] $networks4                = [],
  Optional[Array[Tea::Ipv4_cidr]] $failsafe_networks4       = [],
  Optional[Array[Tea::Ipv6_cidr]] $networks6                = [],
  Optional[Array[Tea::Ipv6_cidr]] $failsafe_networks6       = [],
  Optional[Array[Tea::Ipv4_cidr]] $rejected_v4              = [],
  Optional[Array[Tea::Ipv6_cidr]] $rejected_v6              = [],
  Boolean                         $reject_bogons_v4         = true,
  Boolean                         $reject_bogons_v6         = true,
  Boolean                         $failover_server          = false,
  Boolean                         $enable_advertisements    = true,
  Boolean                         $enable_advertisements_v4 = true,
  Boolean                         $enable_advertisements_v6 = true,
  Boolean                         $manage_nagios            = false,
  Stdlib::Absolutepath            $conf_file                = '/etc/quagga/bgpd.conf',
  Stdlib::Absolutepath            $bgpd_cmd                 = '/usr/lib/quagga/bgpd',
  Optional[Array]                 $debug_bgp                = [],
  Boolean                         $log_stdout               = false,
  Quagga::Log_level               $log_stdout_level         = 'debugging',
  Boolean                         $log_file                 = false,
  Stdlib::Absolutepath            $log_file_path            = '/var/log/quagga/bgpd.log',
  Quagga::Log_level               $log_file_level           = 'debugging',
  Boolean                         $logrotate_enable         = false,
  Integer[1,100]                  $logrotate_rotate         = 5,
  String                          $logrotate_size           = '100M',
  Boolean                         $log_syslog               = false,
  Quagga::Log_level               $log_syslog_level         = 'debugging',
  Tea::Syslogfacility             $log_syslog_facility      = 'daemon',
  Boolean                         $log_monitor              = false,
  Quagga::Log_level               $log_monitor_level        = 'debugging',
  Boolean                         $log_record_priority      = false,
  Integer[0,6]                    $log_timestamp_precision  = 1,
  Boolean                         $fib_update               = true,
  Hash                            $peers                    = {},
) {

  include quagga

  Ini_setting {
    path    => '/etc/quagga/daemons',
    section => '',
    notify  => Service['quagga'],
    require => Package[ $::quagga::package ],
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
  # the quagga validate command runs without CAP_DAC_OVERRIDE
  # this means that even if running the command as root it cant
  # read files owned by !root
  # further to this the validate command is indeterminate. if the
  # file allready exists then the temp file created for the validate_cmd 
  # has the permissions of the original user.  if the file does not exits
  # then the temp file is created with root user permissions.  
  # As such we need this hack
  exec{ "/usr/bin/touch ${conf_file}":
    creates => $conf_file,
    user    => $::quagga::owner,
    before  => Concat[$conf_file],
  }
  if $stage_config {
    concat{$conf_file:
      require      => Package[ $::quagga::package ],
      owner        => $::quagga::owner,
      group        => $::quagga::group,
      validate_cmd => "${bgpd_cmd} -u ${quagga::owner} -C -f %",
    }
  } else {
    concat{$conf_file:
      require      => Package[ $::quagga::package ],
      notify       => Service['quagga'],
      owner        => $::quagga::owner,
      group        => $::quagga::group,
      validate_cmd => "${bgpd_cmd} -u ${quagga::owner} -C -f %",
    }
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
  if $log_file and $logrotate_enable {
    logrotate::rule {'quagga_bgp':
      path       => $log_file_path,
      rotate     => $logrotate_rotate,
      size       => $logrotate_size,
      compress   => true,
      postrotate => '/bin/kill -USR1 `cat /var/run/quagga/bgpd.pid 2> /dev/null` 2> /dev/null || true',
    }
  }
  create_resources(quagga::bgpd::peer, $peers)
}

