define rgbank::db (
  $user,
  $password,
  $mock_sql_source = hiera('rgbank-mock-sql-path'),
) {
  $db_name = "rgbank-${name}"

  if $environment != 'production' {
    staging::deploy { "rgbank-${db_name}.sql":
      source => $mock_sql_source,
      target => "/var/lib/${db_name}/rgbank.sql",
    }
  }

  mysql::db { $db_name:
    user     => $user,
    password => $password,
    host     => '%',
    sql      => "/var/lib/${db_name}/rgbank.sql",
  }

  mysql_user { "${user}@localhost":
    ensure        => 'present',
    password_hash => mysql_password($password),
  }
}

Rgbank::Db produces Mysqldb {
  database => "rgbank-${name}",
  user     => $user,
  host     => $::hostname,
  password => $password
}
