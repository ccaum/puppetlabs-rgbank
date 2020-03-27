class rgbank::profile::web(
  $db_name = lookup('rgbank::profile::db::name', undef, undef, 'rgbank'),
  $db_user = lookup('rgbank::profile::db::user', undef, undef, 'rgbank'),
  $db_password = lookup('rgbank::profile::db::password', undef, undef, '*2470C0C06DEE42FD1618BB99005ADCA2EC9D1E19'),
  $db_host = 'localhost',
) {
  class { 'rgbank::web':
    site_name   => 'rgbank',
    db_name     => $db_name,
    db_user     => $db_user,
    db_password => $db_password,
    db_host     => $db_host,
  }
}
