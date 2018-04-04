require 'spec_helper'

describe 'cyberark_aim' do
  context 'AIM is installed' do
    let(:facts) do
      { installed_carkaim: 'CARKaim-9.80-0.85.x86_64' }
    end

    it { is_expected.to compile.with_all_deps }

    it { is_expected.to contain_class('cyberark_aim::package') }

    it { is_expected.to contain_class('cyberark_aim::environment') }

    it { is_expected.to contain_class('cyberark_aim::service') }
  end
end
