# frozen_string_literal: true

require 'spec_helper_acceptance'

describe 'quagga class ACLs ' do
  router1 = find_host_with_role(:router1)
  router2 = find_host_with_role(:router2)
  router1_ip = fact_on(router1, 'ipaddress')
  router1_ip6 = '2001:db8:1::1'
  router1_asn = '64496'
  router2_ip = fact_on(router2, 'ipaddress')
  router2_ip6 = '2001:db8:1::2'
  router2_asn = '64497'
  ipv6_network = '2001:db8:1::/48'
  ipv4_network = router1_ip.sub(%r{\d+$}, '0/24')
  additional_v4_network1 = '192.0.2.0/24'
  additional_v6_network1 = '2001:db8:2::/48'
  additional_v4_network2 = '198.51.100.0/24'
  additional_v6_network2 = '2001:db8:3::/48'
  on(router1, 'sysctl net.ipv6.conf.all.disable_ipv6=0')
  on(router2, 'sysctl net.ipv6.conf.all.disable_ipv6=0')
  on(router1, "ip -6 addr add #{router1_ip6}/64 dev eth0", acceptable_exit_codes: [0, 2])
  on(router2, "ip -6 addr add #{router2_ip6}/64 dev eth0", acceptable_exit_codes: [0, 2])
  context 'basic' do
    pp1 = <<-EOF
    class { '::quagga': }
    class { '::quagga::bgpd':
      my_asn => #{router1_asn},
      router_id => '#{router1_ip}',
      reject_bogons_v4 => false,
      reject_bogons_v6 => false,
      peers => {
        '#{router2_asn}' => {
          'addr4'          => ['#{router2_ip}'],
          'addr6'          => ['#{router2_ip6}'],
          'desc'           => 'TEST Network',
          'inbound_routes' => 'none',
          }
      }
    }
    EOF
    pp2 = <<-EOF
    class { '::quagga': }
    class { '::quagga::bgpd':
      my_asn => #{router2_asn},
      router_id => '#{router2_ip}',
      reject_bogons_v4 => false,
      reject_bogons_v6 => false,
      networks4 => [
        '#{ipv4_network}',
        '#{additional_v4_network1}',
        '#{additional_v4_network2}',
        ],
      networks6 => [
        '#{ipv6_network}',
        '#{additional_v6_network1}',
        '#{additional_v6_network2}'
        ],
      peers => {
        '#{router1_asn}' => {
          'addr4'             => ['#{router1_ip}'],
          'addr6'             => ['#{router1_ip6}'],
          'desc'              => 'TEST Network',
          'default_originate' => true,
          }
      }
    }
    EOF
    it 'work with no errors' do
      apply_manifest(pp1, catch_failures: true)
      apply_manifest_on(router2, pp2, catch_failures: true)
    end
    it 'r1 clean puppet run' do
      expect(apply_manifest(pp1, catch_failures: true).exit_code).to eq 0
    end
    it 'r2 clean puppet run' do
      expect(apply_manifest_on(router2, pp2, catch_failures: true).exit_code).to eq 0
      # allow peers to configure and establish
      sleep(10)
    end
    describe command('cat /etc/quagga/bgpd.conf 2>&1') do
      its(:stdout) { is_expected.to match(%r{}) }
    end
    describe service('quagga') do
      it { is_expected.to be_running }
    end
    describe process('bgpd') do
      its(:user) { is_expected.to eq 'quagga' }
      it { is_expected.to be_running }
    end
    describe port(179) do
      it { is_expected.to be_listening }
    end
    describe command("ping -c 1 #{router2_ip}") do
      its(:exit_status) { is_expected.to eq 0 }
    end
    describe command("ping6 -I eth0 -c 1 #{router2_ip6}") do
      its(:exit_status) { is_expected.to eq 0 }
    end
    describe command('vtysh -c \'show ip bgp sum\'') do
      its(:stdout) { is_expected.to match(%r{#{router2_ip}\s+4\s+#{router2_asn}}) }
    end
    describe command("vtysh -c \'show ip bgp neighbors #{router2_ip}\'") do
      its(:stdout) { is_expected.to match(%r{BGP state = Established}) }
    end
    describe command('vtysh -c \'show ip bgp \'') do
      its(:stdout) { is_expected.not_to match(%r{192.0.2.0}) }
      its(:stdout) { is_expected.not_to match(%r{198.51.100.0}) }
      its(:stdout) { is_expected.not_to match(%r{0.0.0.0}) }
    end
    describe command('vtysh -c \'show ipv6 bgp sum\'') do
      its(:stdout) { is_expected.to match(%r{#{router2_ip6}\s+4\s+#{router2_asn}}i) }
    end
    describe command("vtysh -c \'show ip bgp neighbors #{router2_ip6}\'") do
      its(:stdout) { is_expected.to match(%r{BGP state = Established}) }
    end
    describe command('vtysh -c \'show ipv6 bgp\'') do
      its(:stdout) { is_expected.not_to match(%r{#{additional_v6_network1}}) }
      its(:stdout) { is_expected.not_to match(%r{#{additional_v6_network2}}) }
      its(:stdout) { is_expected.not_to match(%r{::\/0}) }
    end
  end
  context 'all' do
    pp1 = <<-EOF
    class { '::quagga': }
    class { '::quagga::bgpd':
      my_asn => #{router1_asn},
      router_id => '#{router1_ip}',
      reject_bogons_v4 => false,
      reject_bogons_v6 => false,
      peers => {
        '#{router2_asn}' => {
          'addr4'          => ['#{router2_ip}'],
          'addr6'          => ['#{router2_ip6}'],
          'desc'           => 'TEST Network',
          'inbound_routes' => 'all',
          }
      }
    }
    EOF
    it 'appling all acl' do
      apply_manifest(pp1, catch_failures: true)
    end
    it 'clean acl run' do
      expect(apply_manifest(pp1, catch_failures: true).exit_code).to eq 0
      # allow peers to configure and establish
      sleep(10)
    end
    describe command('vtysh -c \'show ip bgp \'') do
      its(:stdout) do
        is_expected.to match(
          %r{192.0.2.0\s+#{router2_ip}\s+\d+\s+\d+\s+#{router2_asn}},
        )
      end
      its(:stdout) do
        is_expected.to match(
          %r{198.51.100.0\s+#{router2_ip}\s+\d+\s+\d+\s+#{router2_asn}},
        )
      end
      its(:stdout) { is_expected.not_to match(%r{0.0.0.0}) }
    end
    describe command('vtysh -c \'show ipv6 bgp \'') do
      its(:stdout) do
        is_expected.to match(
          %r{#{additional_v6_network1}\s+#{router2_ip6}\s+\d+\s+\d+\s+#{router2_asn}},
        )
      end
      its(:stdout) do
        is_expected.to match(
          %r{#{additional_v6_network2}\s+#{router2_ip6}\s+\d+\s+\d+\s+#{router2_asn}},
        )
      end
      its(:stdout) { is_expected.not_to match(%r{::\/0}) }
    end
  end
  context 'all with rejected networks' do
    pp1 = <<-EOF
    class { '::quagga': }
    class { '::quagga::bgpd':
      my_asn => #{router1_asn},
      router_id => '#{router1_ip}',
      rejected_v4 => ['#{additional_v4_network1}'],
      rejected_v6 => ['#{additional_v6_network1}'],
      reject_bogons_v4 => false,
      reject_bogons_v6 => false,
      peers => {
        '#{router2_asn}' => {
          'addr4'          => ['#{router2_ip}'],
          'addr6'          => ['#{router2_ip6}'],
          'desc'           => 'TEST Network',
          'inbound_routes' => 'all',
          }
      }
    }
    EOF
    it 'appling all acl' do
      apply_manifest(pp1, catch_failures: true)
    end
    it 'clean acl run' do
      expect(apply_manifest(pp1, catch_failures: true).exit_code).to eq 0
      # allow peers to configure and establish
      sleep(10)
    end
    describe command('vtysh -c \'show ip bgp \'') do
      its(:stdout) { is_expected.not_to match(%r{192.0.2.0}) }
      its(:stdout) do
        is_expected.to match(
          %r{198.51.100.0\s+#{router2_ip}\s+\d+\s+\d+\s+#{router2_asn}},
        )
      end
      its(:stdout) { is_expected.not_to match(%r{0.0.0.0}) }
    end
    describe command('vtysh -c \'show ipv6 bgp \'') do
      its(:stdout) { is_expected.not_to match(%r{#{additional_v6_network1}}) }
      its(:stdout) do
        is_expected.to match(
          %r{#{additional_v6_network2}\s+#{router2_ip6}\s+\d+\s+\d+\s+#{router2_asn}},
        )
      end
      its(:stdout) { is_expected.not_to match(%r{::\/0}) }
    end
  end
  context 'default' do
    pp1 = <<-EOF
    class { '::quagga': }
    class { '::quagga::bgpd':
      my_asn => #{router1_asn},
      router_id => '#{router1_ip}',
      reject_bogons_v4 => false,
      reject_bogons_v6 => false,
      peers => {
        '#{router2_asn}' => {
          'addr4'          => ['#{router2_ip}'],
          'addr6'          => ['#{router2_ip6}'],
          'desc'           => 'TEST Network',
          'inbound_routes' => 'default',
          }
      }
    }
    EOF
    it 'appling default acl' do
      apply_manifest(pp1, catch_failures: true)
    end
    it 'clean acl run' do
      expect(apply_manifest(pp1, catch_failures: true).exit_code).to eq 0
      # allow peers to configure and establish
      sleep(10)
    end
    describe command("vtysh -c \'show ip bgp \'") do
      its(:stdout) { is_expected.not_to match(%r{192.0.2.0}) }
      its(:stdout) { is_expected.to match(%r{0.0.0.0\s+#{router2_ip}\s+\d+\s+#{router2_asn}}) }
    end
    describe command("vtysh -c \'show ipv6 bgp \'") do
      its(:stdout) { is_expected.not_to match(%r{#{additional_v6_network1}}) }
      its(:stdout) { is_expected.to match(%r{::\/0\s+#{router2_ip6}\s+\d+\s+#{router2_asn}}) }
    end
  end
end
