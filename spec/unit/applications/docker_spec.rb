require 'spec_helper'

describe 'rgbank', :type => :application do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts
      end

      # Set Facts
      facts['ec2_metadata'] = nil
      facts['networking'] = {
        'domain' => "localdomain",
        'fqdn' => "localhost.localdomain",
        'hostname' => "localhost",
        'interfaces' => {
          'eth0' => {
            'ip' => "10.0.2.15",
          }
        }
      }
      facts['staging_http_get'] = 'curl'
      facts['root_home'] = '/root'



      context "on a single node setup" do
        let(:title) { 'getting-started' }
        let(:node) { 'test.puppet.com' }

        let :params do
          {
            :use_docker => true,
            :nodes => {
              ref('Node', node) => [
                ref('Rgbank::Load', 'getting-started'),
                ref('Rgbank::Web', "#{node}_getting-started"),
                ref('Rgbank::Db', 'getting-started'),
              ]
            }
          }
        end

        context 'with docker' do
          let(:pre_condition){'
            include ::mysql::client
            class {"::mysql::bindings": php_enable => true, }
          '}
          it { should compile }
          it { should contain_rgbank(title).with(
                        'listen_port' => '80',
                        'db_username' => 'test',
                        'db_password' => 'test',
                        'use_docker' => true,
                      ) }
          it { should contain_rgbank__db('getting-started').with(
                        'user'            => 'test',
                        'password'        => 'test',
                        'port'            => '3306',
                        'mock_sql_source' => 'https://raw.githubusercontent.com/puppetlabs/rgbank/master/rgbank.sql',
                      ) }
          it { should contain_rgbank__load('getting-started').with(
                        'port' => '80',
                      ) }

          it { should contain_file('/var/lib/rgbank-getting-started').with(
                        'ensure' => 'directory',
                      ) }

          it { should contain_firewall('000 accept rgbank getting-started load balanced connections') }
          it { should contain_firewall('000 accept rgbank web connections for test.puppet.com_getting-started') }
          it { should contain_mysql_user('test@localhost') }

          # Check for service resources
          it { should contain_database('getting-started') }
          it { should contain_http('getting-started') }
          it { should contain_http('rgbank-web-test.puppet.com_getting-started') }

          # Check for  defines (these are tested in their own modules so just validating they are present)
          it { should contain_haproxy__balancermember('foo.example.com') }
          it { should contain_haproxy__listen('rgbank-getting-started') }
          it { should contain_mysql__db('rgbank-getting-started') }
          it { should contain_selinux__port('allow-httpd-80') }
          it { should contain_staging__file('rgbank-rgbank-getting-started.sql') }

          it { should contain_rgbank__web__docker('test.puppet.com_getting-started').with(
            'db_host'           => '10.0.2.15',
            'db_name'           => 'rgbank-getting-started',
            'db_user'           => 'test',
            'db_password'       => 'test',
            'listen_port'       => '80',
            'image_tag'         => 'latest',
          ) }

          it { should contain_docker__image('ccaum/rgbank-web') }
          it { should contain_docker__run('rgbank-web') }
          it { should contain_package('device-mapper').with( 'ensure' => 'present', )}
          it { should contain_package('docker').with( 'ensure' => 'present', )}

        end
      end
    end
  end
end

