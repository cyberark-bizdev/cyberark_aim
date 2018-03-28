require 'spec_helper'

describe 'cyberark_aim' do 
    
    context 'with ensure => present' do
        
        let(:facts) { { is_virtual: false } }
        
        it {is_expected.to compile}
        
    end
end
