require 'spec_helper_acceptance'

describe 'rgbank load define' do

  context 'setup haproxy' do

    # Using puppet_apply as a helper
    it 'should work idempotently with no errors' do
      pp = <<-EOS
      rgbank::load{"test": balancermembers => [{ host => "localhost", ip => $::ipaddress, port => "8060" },] }
      EOS

      # Run it twice and test for idempotency
      apply_manifest(pp, :catch_failures => true)
      apply_manifest(pp, :catch_changes  => true)

    end
  end

  describe port(80) do
    it { should be_listening }
  end

  describe command('curl --silent http://localhost') do
    its(:stdout) { should match /rgbank/ }
  end

end
