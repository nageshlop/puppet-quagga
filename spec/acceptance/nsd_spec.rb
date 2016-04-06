require 'spec_helper_acceptance'

describe 'nsd class' do
  describe 'running puppet code' do
    it 'should work with no errors' do
      pp = 'class {\'::nsd\': }'
      apply_manifest(pp ,  :catch_failures => true)
      expect(apply_manifest(pp,  :catch_failures => true).exit_code).to eq 0
    end
    describe service('nsd') do
      it { is_expected.to be_enabled }
      it { is_expected.to be_running }
    end
  end
end
