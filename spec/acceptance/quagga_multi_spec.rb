require 'spec_helper_acceptance'


describe 'quagga class multi router' do
  router1 = find_host_with_role(:router1)
  router2 = find_host_with_role(:router2)
  router1_ip = fact_on(router1, "ipaddress")
  router2_ip = fact_on(router2, "ipaddress")
  context 'basic' do
    it 'should work with no errors' do 
      pp1 = <<-EOF
    class { '::quagga': }
    class { '::quagga::bgpd': 
      my_asn => 64496,
      router_id => '#{router1_ip}',
      networks4 => [ '#{router1_ip.sub(/\d+$/,'0/24')}'],
      peers => {
        '64497' => {
          'addr4' => ['#{router2_ip}'],
          'desc'  => 'TEST Network'
          }
      }
    }
    EOF
      pp2 = <<-EOF
    class { '::quagga': }
    class { '::quagga::bgpd': 
      my_asn => 64497,
      router_id => '#{router2_ip}',
      networks4 => [ '#{router2_ip.sub(/\d+$/,'0/24')}'],
      peers => {
        '64496' => {
          'addr4' => ['#{router1_ip}'],
          'desc'  => 'TEST Network'
          }
      }
    }
    EOF
      apply_manifest(pp1 ,  :catch_failures => true)
      apply_manifest_on(router2, pp2 ,  :catch_failures => true)
      expect(apply_manifest(pp1,  :catch_failures => true).exit_code).to eq 0
      expect(apply_manifest_on(router2, pp2,  :catch_failures => true).exit_code).to eq 0
      #allow peers to configure and establish
      sleep(5)
    end
    describe service('quagga') do
      it { is_expected.to be_running }
    end
    describe process('bgpd') do
      its(:user) { should eq 'quagga' }
      it { is_expected.to be_running }
    end
    describe port(179) do
      it { is_expected.to be_listening }
    end
    describe command("ping -c 1 #{router2_ip}") do 
      its(:exit_status) { should eq 0 }
    end
    describe command('vtysh -c \'show ip bgp sum\'') do
      its(:stdout) { should match(/#{router2_ip}\s+4\s+64497/) }
    end
    describe command("vtysh -c \'show ip bgp neighbors #{router2_ip}\'") do
      its(:stdout) { should match(/BGP state = Established/) }
    end
  end
end
