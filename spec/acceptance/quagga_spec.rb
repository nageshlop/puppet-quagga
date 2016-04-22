require 'spec_helper_acceptance'

describe 'quagga class' do
  context 'defaults' do
    it 'should work with no errors' do 
      pp = 'class {\'::quagga\': }'
      apply_manifest(pp ,  :catch_failures => true)
      expect(apply_manifest(pp,  :catch_failures => true).exit_code).to eq 0
    end
    describe service('quagga') do
      it { is_expected.to be_running }
    end
  end
  context 'basic IPv4 peer' do
    it 'should work with no errors' do 
      pp = <<-EOF
    class { '::quagga': }
    class { '::quagga::bgpd': 
      my_asn => 64496,
      router_id => 192.0.2.1,
      networks4 => [ '192.0.2.0/24'],
      peers => {
        '64497' => {
          'addr4' => ['192.0.2.2'],
          'desc'  => 'TEST Network'
          }
      }
    }
    EOF
      apply_manifest(pp ,  :catch_failures => true)
      expect(apply_manifest(pp,  :catch_failures => true).exit_code).to eq 0
    end
    describe service('quagga') do
      it { is_expected.to be_running }
    end
    describe process('bgpd') do
      its(:user) { should eq 'quagga' }
      it { is_expected.to be_running }
    end
    describe command('vtysh -c \'show ip bgp sum\' | awk \'$1=="192.0.2.2" && $3=="64497" {print $NF}\'') do
      its(:stdout) { should match /Active/ }
    end
  end
end
