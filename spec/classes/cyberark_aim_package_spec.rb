require 'spec_helper'

describe 'cyberark_aim::package' do
  context 'AIM is installed' do
    let(:facts) do
      { installed_carkaim: 'CARKaim-9.80-0.85.x86_64' }
    end

    describe 'with ensure = present' do
      let(:params) do
        { ensure: 'present' }
      end

      it { is_expected.to contain_notify('CyberArk AIM Package is already installed') }
    end

    describe 'with ensure = absent' do
      let(:params) do
        { ensure: 'absent' }
      end

      it { is_expected.to contain_package('CARKaim').with_ensure('absent') }
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

      it { is_expected.to contain_package('CARKaim').with_ensure('installed') }
    end

    describe 'with ensure = absent' do
      let(:params) do
        { ensure: 'absent' }
      end

      it { is_expected.to contain_notify('CyberArk AIM Package is not installed') }
    end
  end
end
