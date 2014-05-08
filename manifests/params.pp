# Class: quagga::params
#
class quagga::params {
  $owner          = 'quagga'
  $group          = 'quagga'
  $mode           = '0664'
  $quagga_content = "hostname ${::fqdn}"
  $ospfd_content  = template('quagga/ospfd.conf.erb')
  $bgpd_content   = 'quagga/bgpd.conf.erb'
  $enable_zebra   = true
  $package = 'quagga'
}

