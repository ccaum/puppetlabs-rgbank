class rgbank::db (
  $db_name,
  $user,
  $password,
  $port = '3306',
  $mock_sql_source = hiera('rgbank-mock-sql-path', 'https://raw.githubusercontent.com/puppetlabs/rgbank/master/rgbank.sql'),
) {
  file { "/var/lib/${db_name}":
    ensure => directory,
    mode   => '0755',
  }

  staging::file { "rgbank-${db_name}.sql":
    source => $mock_sql_source,
    target => "/var/lib/${db_name}/rgbank.sql",
  }

  mysql::db { $db_name:
    user     => $user,
    password => $password,
    host     => '%',
    sql      => "/var/lib/${db_name}/rgbank.sql",
  }

  if ! defined(Mysql_user["${user}@localhost"]) {
    mysql_user { "${user}@localhost":
      ensure        => 'present',
      password_hash => mysql_password($password),
    }
  }
}

Rgbank::Db produces Database {
  database => "rgbank-${name}",
  user     => $user,
  host     => $ec2_metadata ? {
    undef   => $::networking['interfaces'][$::networking['interfaces'].keys[0]]['ip'],
    default => $ec2_metadata['public-ipv4'],
  },
  password => $password,
  port     => $port,
}
