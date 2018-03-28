require 'spec_helper'

describe 'cyberark_aim' do
  context 'AIM already installed' do
    let(:facts) do
      { installed_carkaim: 'CARKaim-9.80-0.85.x86_64' }
    end

    it { is_expected.to compile.with_all_deps }

    it { is_expected.to contain_class('cyberark_aim::package') }

    it { is_expected.to contain_class('cyberark_aim::environment') }

    it { is_expected.to contain_class('cyberark_aim::service') }

    describe 'with ensure = present' do
      let(:params) do
        { ensure: 'present' }
      end

      it { is_expected.to contain_notify('CyberArk AIM Package is already installed') }
    end

    describe 'with ensure = absent and no credentials' do
      let(:params) do
        { ensure: 'absent' }
      end

      it { is_expected.to raise_error(/Provide either admin_credential_aim_query or vault_username\/vault_password or use_shared_logon_authentication/) }
    end
  end
end
