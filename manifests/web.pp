class rgbank::web (
  $site_name,
  $db_name,
  $db_host,
  $db_user,
  $db_password,
  $version = lookup('rgbank-build-version', String, first, 'master'),
  $source = lookup('rgbank-build-path', String, first, 'http://cdpe-carl-docker.delivery.puppetlabs.net/ccaum/rgbank'),
  $source_type = lookup('rgbank-build-source-type', String, first, 'vcs'),
  $artifactory_server = lookup('rgbank::artifactory_server') |$key| {  puppetdb_query('inventory[facts] { trusted.extensions.pp_role = "artifactory" }')[0]['facts']['fqdn'] },
  $listen_port = '8060',
  $install_dir = undef,
  $image_tag = 'latest',
  $enable_header = lookup('rgbank::web::enable_header', default => false),
  $use_docker = false,
) {
  if $use_docker {
    rgbank::web::base { $site_name:
      ensure => absent,
    }

    rgbank::web::docker { $site_name:
      db_name     => $db_name,
      db_user     => $db_user,
      db_password => $db_password,
      db_host     => $db_host,
      image_tag   => $image_tag,
      listen_port => $listen_port,
    }
  } else {
    rgbank::web::base { $site_name:
      db_name            => $db_name,
      db_user            => $db_user,
      db_password        => $db_password,
      db_host            => $db_host,
      version            => $version,
      source             => $source,
      source_type        => $source_type,
      listen_port        => $listen_port,
      install_dir        => $install_dir,
      enable_header      => $enable_header,
      artifactory_server => $artifactory_server,
    }

    if $::selinux == true {
      if (! defined(Selinux::Port["allow-httpd-${listen_port}"])) {
        selinux::port { "allow-httpd-${listen_port}":
          context  => 'http_port_t',
          port     => $listen_port,
          protocol => 'tcp',
          before   => [Rgbank::Web::Base[$site_name]],
        }
      }

      if (! defined(Selinux::Boolean['httpd_can_network_connect'])) {
        selinux::boolean { 'httpd_can_network_connect':
          ensure     => true,
          persistent => true,
          before     => [Rgbank::Web::Base[$site_name]],
        }
      }
    }
  }

  firewall { "000 accept rgbank web connections for ${site_name}":
    dport  => $listen_port,
    proto  => tcp,
    action => accept,
  }
}

#Rgbank::Web produces Http {
#  name => $site_name,
#  ip   => $::ipaddress,
#  port => $listen_port,
#  host => $::trusted['certname'],
#  path => '/',
#}
#
#Rgbank::Web consumes Database {
#  db_name     => $database,
#  db_host     => $host,
#  db_user     => $user,
#  db_password => $password,
#}
#
#Rgbank::Web consumes Vinfrastructure { }
