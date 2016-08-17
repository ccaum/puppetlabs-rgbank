define rgbank::web (
  $db_name,
  $db_host,
  $db_user,
  $db_password,
  $version = hiera('rgbank-build-version'),
  $source = hiera('rgbank-build-path'),
  $listen_port = '8060',
  $install_dir = undef,
) {
  include apache

  if $install_dir {
    $install_dir_real = $install_dir
  } else {
    $install_dir_real = "/opt/rgbank-${name}"
  }

  archive { "rgbank-build-${version}":
    ensure     => present,
    url        => $source,
    target     => "${install_dir_real}/wp-content/themes/rgbank",
    checksum   => false,
    src_target => '/tmp'
  }

  wordpress::instance::app { "rgbank_${name}":
    install_dir          => $install_dir_real,
    install_url          => 'http://wordpress.org',
    version              => '4.5.2',
    db_host              => $db_host,
    db_name              => $db_name,
    db_user              => $db_user,
    db_password          => $db_password,
    wp_owner             => 'root',
    wp_group             => '0',
    wp_lang              => '',
    wp_config_content    => undef,
    wp_plugin_dir        => 'DEFAULT',
    wp_additional_config => 'DEFAULT',
    wp_table_prefix      => 'wp_',
    wp_proxy_host        => '',
    wp_proxy_port        => '',
    wp_multisite         => false,
    wp_site_domain       => '',
    wp_debug             => false,
    wp_debug_log         => false,
    wp_debug_display     => false,
    notify               => Service['httpd'],
  }

  file { "${install_dir_real}/wp-content/uploads":
    ensure  => directory,
    owner   => apache,
    group   => apache,
    recurse => true,
    require => Wordpress::Instance::App["rgbank_${name}"],
  }

  firewall { '000 accept rgbank web connections':
    dport  => $listen_port,
    proto  => tcp,
    action => accept,
  }

  apache::listen { $listen_port: }

  apache::vhost { $::fqdn:
    docroot => $install_dir_real,
    port    => $listen_port,
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

Rgbank::Web consume Vinfrastructure { }
