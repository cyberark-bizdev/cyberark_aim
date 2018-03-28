require 'spec_helper'

describe 'cyberark_aim::package' do 
    
    context 'AIM already installed' do
        
        let(:facts) {
             { installed_carkaim: "CARKaim-9.80-0.85.x86_64" } 
        }
        
        let(:params) {
            { cyberark_aim__ensure => 'present'  }
        }
        
        it { is_expected.to contain_package('CARKaim').with_ensure('installed') }
            
        
    end
end
