require 'spec_helper'
require 'shared_contexts'

describe 'quagga::bgpd' do
  # by default the hiera integration uses hiera data from the shared_contexts.rb file
  # but basically to mock hiera you first need to add a key/value pair
  # to the specific context in the spec/shared_contexts.rb file
  # Note: you can only use a single hiera context per describe/context block
  # rspec-puppet does not allow you to swap out hiera data on a per test block
  #include_context :hiera

  # below is the facts hash that gives you the ability to mock
  # facts on a per describe/context block.  If you use a fact in your
  # manifest you should mock the facts below.
  let(:params) do
    {
      :my_asn => 64496,
      :enable => true,
      :router_id => '192.0.2.1',
      :networks4 => ['192.0.2.0/25'],
      :failsafe_networks4 => ['192.0.2.0/24'],
      :networks6 => ['2001:DB8::/48'],
      :failsafe_networks6 => ['2001:DB8::/32'],
      :failover_server => false,
      :enable_advertisements => true,
      :enable_advertisements_v4 => true,
      :enable_advertisements_v6 => true,
      :manage_nagios => false,
      :conf_file => "/etc/quagga/bgpd.conf",
      :peers => {
        '64497' => {
            "addr4"          => ["192.0.2.2"],
            "addr6"          => ["2001:DB8::2"],
            "desc"           => "TEST Network",
            "inbound_routes" => "all",
            "communities"    => ["no-export", "64497:100" ],
            "multihop"       => 5,
            "password"       => "password",
            "prepend"        => 3,
        },
        '64498' => {
            "addr4"          => ["192.0.2.2"],
            "desc"           => "TEST 2 Network",
        },
      },
    }
  end
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts
      end
      # below is a list of the resource parameters that you can override.
      # By default all non-required parameters are commented out,
      # while all required parameters will require you to add a value
      describe 'standard check' do
        # add these two lines in a single test block to enable puppet and hiera debug mode
        # Puppet::Util::Log.level = :debug
        # Puppet::Util::Log.newdestination(:console)
        it do
          is_expected.to compile.with_all_deps
        end

        it { is_expected.to contain_class('Quagga') }
        it { is_expected.to contain_quagga__bgpd__peer('64497') }
        it { is_expected.to contain_quagga__bgpd__peer('64498') }
        it do
          is_expected.to contain_concat('/etc/quagga/bgpd.conf')
            .with(
          notify:  "Service[quagga]",
          require: "Package[quagga]",
        )
        end
        it do
          is_expected.to contain_concat__fragment('quagga_bgpd_head')
            .with(
          'order'   => '01',
          'target'  => '/etc/quagga/bgpd.conf'
        ).with_content(
          /router bgp 64496/
        ).with_content(
          /bgp router-id 192.0.2.1/
        ).with_content(
          /network 192.0.2.0\/25/
        ).with_content(
          /network 192.0.2.0\/24/
        )
        end
        it do
          is_expected.to contain_concat__fragment('quagga_bgpd_v6head')
            .with(
          'content' => /address-family ipv6/,
          'order'   => '30',
          'target'  => '/etc/quagga/bgpd.conf'
        )
        end
        it do
          is_expected.to contain_concat__fragment('quagga_bgpd_v6foot')
            .with(
          'order'   => '50',
          'target'  => '/etc/quagga/bgpd.conf'
          ).with_content(
            /network 2001:DB8::\/48/
          ).with_content(
            /network 2001:DB8::\/32/
          ).with_content(
            /exit-address-family/
          )
        end
        it do
          is_expected.to contain_concat__fragment('quagga_bgpd_acl')
            .with(
          'order'   => '80',
          'target'  => '/etc/quagga/bgpd.conf'
        ).with_content(
          /ip prefix-list default-route seq 1 permit 0.0.0.0\/0/
        ).with_content(
          /ip prefix-list deny seq 1 deny any/
        ).with_content(
          /ip prefix-list deny-default-route seq 1 deny 0.0.0.0\/0/
        ).with_content(
          /ip prefix-list deny-default-route seq 2 permit 0.0.0.0\/0 le 24/
        ).without_content(
          /ip prefix-list prefix-v4 seq 1 deny any/
        ).with_content(
          /ip prefix-list prefix-v4 seq 2 permit 192.0.2.0\/25/
        ).with_content(
          /ip prefix-list prefix-v4 seq 3 permit 192.0.2.0\/24/
        ).with_content(
          /ip prefix-list specific-v4 seq 1 permit 192.0.2.0\/25/
        ).with_content(
          /ipv6 prefix-list default-route seq 1 permit ::\/0/
        ).with_content(
          /ipv6 prefix-list deny seq 1 deny any/
        ).with_content(
          /ipv6 prefix-list deny-default-route seq 1 deny ::\/0/
        ).with_content(
          /ipv6 prefix-list deny-default-route seq 2 permit ::\/0 le 48/
        ).without_content(
          /ipv6 prefix-list prefix-v6 seq 1 deny any/
        ).with_content(
          /ipv6 prefix-list prefix-v6 seq 2 permit 2001:DB8::\/48/
        ).with_content(
          /ipv6 prefix-list prefix-v6 seq 3 permit 2001:DB8::\/32/
        ).with_content(
          /ipv6 prefix-list specific-v6 seq 1 permit 2001:DB8::\/48/
        )
        end
        it do
          is_expected.to contain_concat__fragment('quagga_bgpd_foot')
            .with(
          'content' => /line vty/,
          'order'   => '99',
          'target'  => '/etc/quagga/bgpd.conf'
        )
        end
        it do
          is_expected.to contain_ini_setting('bgpd')
            .with(
              'setting' => 'bgpd',
              'value'   => 'yes'
            )
        end
      end

      describe 'Change Defaults' do
        context 'networks4' do
          before { params.merge!(networks4: ['192.0.2.0/25','10.0.0.0/24']) }
          it { is_expected.to compile }
          it do
            is_expected.to contain_concat__fragment('quagga_bgpd_head')
              .with(
            'order'   => '01',
            'target'  => '/etc/quagga/bgpd.conf'
            ).with_content(
              /network 192.0.2.0\/25/
            ).with_content(
              /network 10.0.0.0\/24/
            ).with_content(
              /network 192.0.2.0\/24/
            )
          end
          it do
            is_expected.to contain_concat__fragment('quagga_bgpd_acl')
              .with(
            'order'   => '80',
            'target'  => '/etc/quagga/bgpd.conf'
            ).with_content(
              /ip prefix-list prefix-v4 seq 2 permit 192.0.2.0\/25/
            ).with_content(
              /ip prefix-list prefix-v4 seq 3 permit 10.0.0.0\/24/
            ).with_content(
              /ip prefix-list prefix-v4 seq 4 permit 192.0.2.0\/24/
            ).with_content(
              /ip prefix-list specific-v4 seq 1 permit 192.0.2.0\/25/
            ).with_content(
              /ip prefix-list specific-v4 seq 2 permit 10.0.0.0\/24/
            )
          end
        end
        context 'failsafe_networks4' do
          before { params.merge!(failsafe_networks4: ['192.0.2.0/24', '10.0.0.0/24'] )}
          it { is_expected.to compile }
          it do
            is_expected.to contain_concat__fragment('quagga_bgpd_head')
              .with(
            'order'   => '01',
            'target'  => '/etc/quagga/bgpd.conf'
            ).with_content(
              /network 192.0.2.0\/25/
            ).with_content(
              /network 10.0.0.0\/24/
            ).with_content(
              /network 192.0.2.0\/24/
            )
          end
          it do
            is_expected.to contain_concat__fragment('quagga_bgpd_acl')
              .with(
            'order'   => '80',
            'target'  => '/etc/quagga/bgpd.conf'
            ).with_content(
              /ip prefix-list prefix-v4 seq 2 permit 192.0.2.0\/25/
            ).with_content(
              /ip prefix-list prefix-v4 seq 3 permit 192.0.2.0\/24/
            ).with_content(
              /ip prefix-list prefix-v4 seq 4 permit 10.0.0.0\/24/
            ).with_content(
              /ip prefix-list specific-v4 seq 1 permit 192.0.2.0\/25/
            ).without_content(
              /ip prefix-list specific-v4 seq 2 permit 10.0.0.0\/24/
            )
          end
        end
        context 'networks6' do
          before { params.merge!(networks6: ['2001:DB8::/48', '2001:DC8::/48']) }
          it { is_expected.to compile }
          it do
            is_expected.to contain_concat__fragment('quagga_bgpd_v6foot')
              .with(
            'order'   => '50',
            'target'  => '/etc/quagga/bgpd.conf'
            ).with_content(
              /network 2001:DB8::\/48/
            ).with_content(
              /network 2001:DC8::\/48/
            ).with_content(
              /network 2001:DB8::\/32/
            )
          end
          it do
            is_expected.to contain_concat__fragment('quagga_bgpd_acl')
              .with(
            'order'   => '80',
            'target'  => '/etc/quagga/bgpd.conf'
            ).with_content(
              /ipv6 prefix-list prefix-v6 seq 2 permit 2001:DB8::\/48/
            ).with_content(
              /ipv6 prefix-list prefix-v6 seq 3 permit 2001:DC8::\/48/
            ).with_content(
              /ipv6 prefix-list prefix-v6 seq 4 permit 2001:DB8::\/32/
            ).with_content(
              /ipv6 prefix-list specific-v6 seq 1 permit 2001:DB8::\/48/
            )
          end
        end
        context 'failsafe_networks6' do
          before { params.merge!(failsafe_networks6: ['2001:DB8::/32', '2001:DC8::/48']) }
          it { is_expected.to compile }
          it do
            is_expected.to contain_concat__fragment('quagga_bgpd_v6foot')
              .with(
            'order'   => '50',
            'target'  => '/etc/quagga/bgpd.conf'
            ).with_content(
              /network 2001:DB8::\/48/
            ).with_content(
              /network 2001:DC8::\/48/
            ).with_content(
              /network 2001:DB8::\/32/
            )
          end
          it do
            is_expected.to contain_concat__fragment('quagga_bgpd_acl')
              .with(
            'order'   => '80',
            'target'  => '/etc/quagga/bgpd.conf'
            ).with_content(
              /ipv6 prefix-list prefix-v6 seq 2 permit 2001:DB8::\/48/
            ).with_content(
              /ipv6 prefix-list prefix-v6 seq 3 permit 2001:DB8::\/32/
            ).with_content(
              /ipv6 prefix-list prefix-v6 seq 4 permit 2001:DC8::\/48/
            ).with_content(
              /ipv6 prefix-list specific-v6 seq 1 permit 2001:DB8::\/48/
            )
          end
        end
        context 'failover_server' do
          before { params.merge!(failover_server: true) }
          it { is_expected.to compile }
          it do
            is_expected.to contain_concat__fragment('quagga_bgpd_acl')
              .with(
            'order'   => '80',
            'target'  => '/etc/quagga/bgpd.conf'
            ).without_content(
              /ipv6 prefix-list prefix-v6 seq 2 permit 2001:DB8::\/48/
            ).with_content(
              /ipv6 prefix-list prefix-v6 seq 2 permit 2001:DB8::\/32/
            ).without_content(
              /ip prefix-list prefix-v4 seq 2 permit 192.0.2.0\/25/
            ).with_content(
              /ip prefix-list prefix-v4 seq 2 permit 192.0.2.0\/24/
            )
          end
        end
        context 'enable_advertisements' do
          before { params.merge!(enable_advertisements: false) }
          it { is_expected.to compile }
          it do
            is_expected.to contain_concat__fragment('quagga_bgpd_acl')
              .with(
            'order'   => '80',
            'target'  => '/etc/quagga/bgpd.conf'
            ).with_content(
              /ip prefix-list prefix-v4 seq 1 deny any/
            ).with_content(
              /ipv6 prefix-list prefix-v6 seq 1 deny any/
            )
          end
        end
        context 'enable_advertisements_v4' do
          before { params.merge!(enable_advertisements_v4: false) }
          it { is_expected.to compile }
          it do
            is_expected.to contain_concat__fragment('quagga_bgpd_acl')
              .with(
            'order'   => '80',
            'target'  => '/etc/quagga/bgpd.conf'
            ).with_content(
              /ip prefix-list prefix-v4 seq 1 deny any/
            ).without_content(
              /ipv6 prefix-list prefix-v6 seq 1 deny any/
            )
          end
        end
        context 'enable_advertisements_v6' do
          before { params.merge!(enable_advertisements_v6: false) }
          it { is_expected.to compile }
          it do
            is_expected.to contain_concat__fragment('quagga_bgpd_acl')
              .with(
            'order'   => '80',
            'target'  => '/etc/quagga/bgpd.conf'
            ).without_content(
              /ip prefix-list prefix-v4 seq 1 deny any/
            ).with_content(
              /ipv6 prefix-list prefix-v6 seq 1 deny any/
            )
          end
        end
        context 'conf_file' do
          before { params.merge!(conf_file: '/etc/quagga/foo.conf') }
          it { is_expected.to compile }
          # Add Check to validate change was successful
          it do
            is_expected.to contain_concat('/etc/quagga/foo.conf')
              .with(
                'notify'  => 'Service[quagga]',
                'require' => 'Package[quagga]'

              )
          end
        end
        context 'disable' do
          before { params.merge!(enable: false) }
          it { is_expected.to compile }
          it do
            is_expected.to contain_ini_setting('bgpd')
              .with(
                'setting' => 'bgpd',
                'value'   => 'no'
              )
          end
        end
      end

      # You will have to correct any values that should be bool
      describe 'check bad type' do
        context 'my_asn' do
          before { params.merge!(my_asn: false) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'router_id' do
          before { params.merge!(router_id: false) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'networks4' do
          before { params.merge!(networks4: false) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'failsafe_networks4' do
          before { params.merge!(failsafe_networks4: false) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'networks6' do
          before { params.merge!(networks6: false) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'failsafe_networks6' do
          before { params.merge!(failsafe_networks6: false) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'failover_server' do
          before { params.merge!(failover_server: []) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'enable_advertisements' do
          before { params.merge!(enable_advertisements: []) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'enable_advertisements_v4' do
          before { params.merge!(enable_advertisements_v4: []) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'enable_advertisements_v6' do
          before { params.merge!(enable_advertisements_v6: []) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'manage_nagios' do
          before { params.merge!(manage_nagios: []) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'conf_file' do
          before { params.merge!(conf_file: false) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'peers' do
          before { params.merge!(peers: false)}
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'enable' do
          before { params.merge!(enable: [])}
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
      end
    end
  end
end
