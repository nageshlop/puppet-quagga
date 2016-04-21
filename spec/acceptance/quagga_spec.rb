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
end
