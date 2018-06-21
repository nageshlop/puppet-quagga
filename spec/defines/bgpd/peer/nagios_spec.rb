# frozen_string_literal: true

require 'spec_helper'

describe 'quagga::bgpd::peer::nagios' do
  let(:title) { '192.0.2.2' }
  let(:params) do
    {
      routes: ['192.0.2.0/24', '10.0.0.0/24'],
    }
  end
  let(:node) { 'foo.example.com' }

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }

      describe 'check default config' do
        subject { exported_resources }

        # add these two lines in a single test block to enable puppet and hiera debug mode
        # Puppet::Util::Log.level = :debug
        # Puppet::Util::Log.newdestination(:console)
        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to contain_nagios_service(
            'foo.example.com_BGP_NEIGHBOUR_192.0.2.2',
          ).with(
            check_command: 'check_nrpe_args!check_bgp!192.0.2.2!192.0.2.0/24 10.0.0.0/24',
            ensure: 'present',
            host_name: 'foo.example.com',
            service_description: 'BGP_NEIGHBOUR_192.0.2.2',
            use: 'generic-service',
          )
        end
      end

      # You will have to correct any values that should be bool
      describe 'check bad type' do
        context 'routes' do
          before(:each) { params.merge!(routes: false) }
          it { is_expected.to raise_error(Puppet::Error) }
        end
      end
    end
  end
end
