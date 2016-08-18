define rgbank::web (
  $db_name,
  $db_host,
  $db_user,
  $db_password,
  $version = hiera('rgbank-build-version'),
  $source = hiera('rgbank-build-path'),
  $listen_port = '8060',
  $install_dir = undef,
  $image_tag = 'latest',
  $use_docker = false,
) {
  if $use_docker {
    rgbank::web::docker { $name:
      db_name     => $db_name,
      db_user     => $db_user,
      db_password => $db_password,
      db_host     => $db_host,
      image_tag   => $image_tag,
      listen_port => $listen_port,
    }
  } else {
    rgbank::web::base { $name:
      db_name     => $db_name,
      db_user     => $db_user,
      db_password => $db_password,
      db_host     => $db_host,
      version     => $version,
      source      => $source,
      listen_port => $listen_port,
      install_dir => $install_dir,
    }

    selinux::port { "allow-httpd-${listen_port}":
      context  => 'http_port_t',
      port     => $listen_port,
      protocol => 'tcp',
      before   => [Apache::Listen[$listen_port],Apache::Vhost[$::fqdn]],
    }

    selinux::boolean { 'httpd_can_network_connect':
      ensure     => true,
      persistent => true,
      before   => [Apache::Listen[$listen_port],Apache::Vhost[$::fqdn]],
    }
  }

  firewall { '000 accept rgbank web connections':
    dport  => $listen_port,
    proto  => tcp,
    action => accept,
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
