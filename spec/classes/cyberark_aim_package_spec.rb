require 'spec_helper'

describe 'cyberark_aim::package' do
  context 'AIM already installed' do
    let(:facts) do
      { installed_carkaim: 'CARKaim-9.80-0.85.x86_64' }
    end

    let(:params) do
      { cyberark_aim__ensure => 'present' }
    end

    it { is_expected.to contain_package('CARKaim').with_ensure('installed') }
  end
end
