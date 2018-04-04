require 'spec_helper'

describe 'cyberark_aim::environment' do
  context 'AIM is installed' do
    let(:facts) do
      { installed_carkaim: 'CARKaim-9.80-0.85.x86_64' }
    end

    describe 'with ensure = present' do
      let(:params) do
        { ensure: 'present' }
      end

      it { is_expected.to compile }
    end

    describe 'with ensure = absent' do
      let(:params) do
        { ensure: 'absent' }
      end

      context 'No credentials' do
        it { is_expected.to compile.and_raise_error(%r{Provide either admin_credential_aim_query or vault_username\/vault_password or use_shared_logon_authentication}) }
      end

      context 'with wrong app_id' do
        let(:params) do
          super().merge(
            admin_credential_aim_appid: 'yyyyyyyyyyyy-yyyyy',
            admin_credential_aim_query: 'Safe=yyyy;Folder=yyyy;Object=yyyy',
          )
        end

        it { is_expected.to compile.and_raise_error(%r{ITATS982E User yyyyyyyyyyyy-yyyyy is not defined}) }
      end

      context 'with right admin_credential_aim_query and app_id' do
        let(:params) do
          super().merge(
            admin_credential_aim_appid: 'PuppetTest',
            admin_credential_aim_query: 'Safe=CyberArk Passwords;Folder=Root;Object=AdminPass',
            provider_username: 'Prov_test',
          )
        end

        it { is_expected.to contain_cyberark_user('Prov_test').with_ensure('absent') }
      end
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

      context 'No credentials' do
        it { is_expected.to compile.and_raise_error(%r{Provide either admin_credential_aim_query or vault_username\/vault_password or use_shared_logon_authentication}) }
      end

      context 'with wrong app_id' do
        let(:params) do
          super().merge(
            admin_credential_aim_appid: 'xxxxxxxx-xxxxxx',
            admin_credential_aim_query: 'Safe=xxxx;Folder=xxxx;Object=xxxx',
          )
        end

        it { is_expected.to compile.and_raise_error(%r{ITATS982E User xxxxxxxx-xxxxxx is not defined}) }
      end

      context 'with wrong admin_credential_aim_query' do
        let(:params) do
          super().merge(
            admin_credential_aim_appid: 'PuppetTest',
            admin_credential_aim_query: 'Safe=xxxx;Folder=xxxx;Object=xxxx',
          )
        end

        it { is_expected.to compile.and_raise_error(%r{APPAP004E Password object matching query}) }
      end

      describe 'with right admin_credential_aim_query and app_id' do
        let(:params) do
          super().merge(
            admin_credential_aim_appid: 'PuppetTest',
            admin_credential_aim_query: 'Safe=CyberArk Passwords;Folder=Root;Object=AdminPass',
            provider_username: 'Prov_test',
          )
        end

        it { is_expected.to contain_cyberark_user('Prov_test').with_ensure('present') }
      end
    end
  end
end
