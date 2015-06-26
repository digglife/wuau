require 'spec_helper'
describe 'wuau' do

  context 'with defaults for all parameters' do
    it { should contain_class('wuau') }
  end
end
