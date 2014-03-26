# Class: quagga::params
#
class quagga::params {

  $owner          = 'quagga'
  $group          = 'quaggavty'
  $mode           = '0664'
  $quagga_content = "hostname ${::fqdn}"
  $ospfd_content  = template('quagga/ospfd.conf.erb')
  $bgpd_content   = template('quagga/bgpd.conf.erb')

  case $::operatingsystem {
    'RedHat', 'Fedora', 'CentOS': {
      $package = 'quagga'
    }
    'Gentoo': {
      $package = 'net-misc/quagga'
    }
    default: {
      $package = 'quagga'
    }
  }

}

