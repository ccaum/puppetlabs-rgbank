define rgbank::web::docker(
  $db_name,
  $db_host,
  $db_user,
  $db_password,
  $image_tag = 'latest',
  $listen_port = '80'
) {
  include docker

  docker::image {'ccaum/rgbank-web': }

  docker::run { 'rgbank-web':
    image   => 'ccaum/rgbank-web',
    ports   => ["${listen_port}:80"],
    env     => [
      "DB_NAME=${db_name}",
      "DB_PASSWORD=${db_password}",
      "DB_USER=${db_user}",
      "DB_HOST=${db_host}",
    ],
    command => 'apache2ctl -D FOREGROUND',
  }
}

Rgbank::Web produces Http {
  name => $name,
  ip   => $::networking['interfaces'][$::networking['interfaces'].keys[0]]['ip'],
  port => $listen_port,
  host => $::hostname,
}

Rgbank::Web consumes Mysqldb {
  db_name     => $database,
  db_host     => $host,
  db_user     => $user,
  db_password => $password,
}

Rgbank::Web consumes Vinfrastructure { }
