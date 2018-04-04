require 'spec_helper'

describe 'cyberark_aim::service' do
  context 'AIM is installed' do
    let(:facts) do
      { installed_carkaim: 'CARKaim-9.80-0.85.x86_64' }
    end

    describe 'with ensure = present' do
      let(:params) do
        { ensure: 'present' }
      end

      it { is_expected.to contain_service('aimprv').with_ensure('running') }
    end
  end

  context 'AIM is not installed' do
    let(:facts) do
      { installed_carkaim: 'package CARKaim is not installed' }
    end

    describe 'with ensure = present' do
      let(:params) do
        { ensure: 'present' }
      end

      it { is_expected.to contain_service('aimprv').with_ensure('running') }
    end
  end
end
