require 'spec_helper_acceptance'

describe 'rgbank db define' do

  case fact('operatingsystemmajrelease')
  when '7'
    service = 'mariadb'
    package = 'mariadb'
  when '6'
    service = 'mysqld'
    package = 'mysql'
  end

  def pp_path
    base_path = File.dirname(__FILE__)
    File.join(base_path, 'fixtures')
  end

  def preconditions_puppet_module
    module_path = File.join(pp_path, 'db_pre.pp')
    File.read(module_path)
  end

  before(:all) do
    apply_manifest(preconditions_puppet_module, catch_failures: true)
  end

  context 'setup db' do

    # Using puppet_apply as a helper
    it 'should work idempotently with no errors' do
      pp = <<-EOS
      rgbank::db {"test":
        user => "test",
        password => "test"
      }
      EOS

      # Run it twice and test for idempotency
      apply_manifest(pp, :catch_failures => true)
      apply_manifest(pp, :catch_changes  => true)

    end
  end

  context 'should have database packages and services running' do
    describe package(package) do
      it { is_expected.to be_installed }
    end

    describe package("#{package}-server") do
      it { is_expected.to be_installed }
    end

    describe service(service) do
      it { is_expected.to be_enabled }
      it { is_expected.to be_running }
    end
  end

  context 'should be able to access database' do
    describe command('mysql -utest -ptest rgbank-test -e "select 1" &>/dev/null') do
      its(:exit_status) { should eq 0 }
    end
  end

  context 'should have database tables' do
    describe command('mysql -utest -ptest rgbank-test -e "show tables"') do
      its(:stdout) { should match /wp_/ }
      its(:exit_status) { should eq 0 }
    end
  end

end
