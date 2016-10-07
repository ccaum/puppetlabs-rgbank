require 'beaker-rspec/spec_helper'
require 'beaker-rspec/helpers/serverspec'
require 'beaker/puppet_install_helper'

install_puppet_agent_on(hosts, :version => '1.7.0')

RSpec.configure do |c|
  # Project root
  proj_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))

  # Readable test descriptions
  c.formatter = :documentation

  # Configure all nodes in nodeset
  c.before :suite do
    # Install module and dependencies
    puppet_module_install(:source => proj_root, :module_name => 'rgbank')
    hosts.each do |host|
      on host, puppet('config', 'set', 'app_management', 'true'), { :acceptable_exit_codes => [0,1] }
      on host, puppet('module', 'install', 'puppetlabs-stdlib'), { :acceptable_exit_codes => [0,1] }
      on host, puppet('module', 'install', 'hunner-wordpress'), { :acceptable_exit_codes => [0,1] }
      on host, puppet('module', 'install', 'jfryman-selinux'), { :acceptable_exit_codes => [0,1] }
      on host, puppet('module', 'install', 'mayflower/php'), { :acceptable_exit_codes => [0,1] }
      on host, puppet('module', 'install', 'puppet/nginx'), { :acceptable_exit_codes => [0,1] }
      on host, puppet('module', 'install', 'puppetlabs-app_modeling'), { :acceptable_exit_codes => [0,1] }
      on host, puppet('module', 'install', 'puppetlabs-firewall'), { :acceptable_exit_codes => [0,1] }
      on host, puppet('module', 'install', 'puppetlabs-haproxy'), { :acceptable_exit_codes => [0,1] }
      on host, puppet('module', 'install', 'puppetlabs-mysql'), { :acceptable_exit_codes => [0,1] }
      on host, puppet('module', 'install', 'puppetlabs-vcsrepo'), { :acceptable_exit_codes => [0,1] }
      on host, puppet('module', 'install', 'gareth-docker'), { :acceptable_exit_codes => [0,1] }
    end
  end
end
