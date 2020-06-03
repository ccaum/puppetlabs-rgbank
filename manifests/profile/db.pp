class rgbank::profile::db(
  $db_name = 'rgbank',
  $user = 'rgbank',
  $password = lookup('rgbank::profile::db::password', undef, undef, '*2470C0C06DEE42FD1618BB99005ADCA2EC9D1E19'),
) {
  class { 'rgbank::db':
    db_name  => $db_name,
    user     => $user,
    password => $password,
  }
}
