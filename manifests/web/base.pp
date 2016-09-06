define rgbank::web::base(
  $db_name = undef,
  $db_user = undef,
  $db_password = undef,
  $db_host = undef,
  $version,
  $source,
  $listen_port,
  $install_dir,
  $custom_wp_config = undef,
) {
  include apache

  if $install_dir {
    $install_dir_real = $install_dir
  } else {
    $install_dir_real = "/opt/rgbank-${name}"
  }

  archive { "rgbank-build-${version}-${name}":
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
    wp_config_content    => $custom_wp_config,
    wp_plugin_dir        => 'DEFAULT',
    wp_additional_config => 'rgbank/wp-proxy-config.php.erb',
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

  apache::listen { $listen_port: }

  if (! defined(Apache::Vhost[$fqdn])) {
    apache::vhost { $::fqdn:
      docroot => $install_dir_real,
      port    => $listen_port,
    }
  }
}
