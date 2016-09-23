require 'spec_helper'

describe 'wlp::deploy_app', :type => :define do
 let(:pre_condition){
   '
    class {"wlp": install_src => "https://public.dhe.ibm.com/downloads/wlp/16.0.0.2/wlp-javaee7-16.0.0.2.zip" }
    wlp::server{"testserver": ensure => "present" };
   '
 }
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        let(:facts) do
          facts
        end
        let :title do
          'hello_world.war'
        end

        context "wlp::deploy_app as dropin" do
          let(:params) { { :type => 'dropin', :server => 'testserver', :install_src => '/vagrant/hello_world.war' } }
          it { is_expected.to compile.with_all_deps }
          it { is_expected.to contain_archive('hello_world.war').with({
            :path   => '/opt/ibm/wlp/usr/servers/testserver/dropins/hello_world.war',
            :source => '/vagrant/hello_world.war',
            :user   => 'wlp',
            :group  => 'wlp'
          }) }
        end

        context "wlp::deploy_app deleting dropin" do
          let(:params) { { :type => 'dropin', :server => 'testserver', :install_src => '/vagrant/hello_world.war', :ensure => 'absent' } }
          it { is_expected.to compile.with_all_deps }
          it { is_expected.to contain_file('/opt/ibm/wlp/usr/servers/testserver/dropins/hello_world.war').with({
            :ensure  => 'absent'
          }) }
        end

        context "wlp::deploy_app as static" do
          let(:params) { { :type => 'static', :server => 'testserver', :install_src => '/vagrant/hello_world.war' } }
          it { is_expected.to compile.with_all_deps }
          it { is_expected.to contain_archive('hello_world.war').with({
            :path   => '/opt/ibm/wlp/usr/servers/testserver/apps/hello_world.war',
            :source => '/vagrant/hello_world.war',
            :user   => 'wlp',
            :group  => 'wlp',
            :notify => 'Wlp_server_control[testserver]',
          }) }
        end

        context "wlp::deploy_app deleting static" do
          let(:params) { { :type => 'static', :server => 'testserver', :install_src => '/vagrant/hello_world.war', :ensure => 'absent' } }
          it { is_expected.to compile.with_all_deps }
          it { is_expected.to contain_file('/opt/ibm/wlp/usr/servers/testserver/apps/hello_world.war').with({
            :ensure  => 'absent',
            :notify => 'Wlp_server_control[testserver]',
          }) }
        end

        context "wlp::deploy_app invalid args dropin" do
          let(:params) { { :type => 'special', :server => 'testserver', :install_src => '/vagrant/hello_world.war' } }
          it { should compile.with_all_deps.and_raise_error(/No matching entry for selector parameter with value 'special'/) }
        end

      end
    end
  end
end
