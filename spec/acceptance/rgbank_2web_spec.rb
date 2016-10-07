require 'spec_helper_acceptance'

describe 'rgbank web define' do

		context 'setup web' do
      # Using puppet_apply as a helper
      it 'should work idempotently with no errors' do
        pp = <<-EOS
        package {'wget': ensure => present, }
        class { 'php': composer => false, }
        class { 'nginx': }
        class {'::mysql::client': }
        class {'::mysql::bindings': php_enable => true }
        package {'git': ensure => present, }
        rgbank::web {"test": db_name => "rgbank-test", db_host => "localhost", db_user => "test", db_password => "test", }
        EOS

        # Run it twice and test for idempotency
        apply_manifest(pp, :catch_failures => true)
        apply_manifest(pp, :catch_changes  => true)
      end


      describe port(8060) do
          it { should be_listening }
      end

      describe command('curl --silent http://localhost:8060') do
          its(:stdout) { should match /rgbank/ }
      end

  end

end
