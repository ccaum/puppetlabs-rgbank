define rgbank::web::base(
  $version,
  $source,
  $listen_port,
  $install_dir,
  $db_name = undef,
  $db_user = undef,
  $db_password = undef,
  $db_host = undef,
  $custom_wp_config = undef,
) {

  if $install_dir {
    $install_dir_real = $install_dir
  } else {
    $install_dir_real = "/opt/rgbank-${name}"
  }

  wordpress::instance::app { "rgbank_${name}":
    install_dir          => $install_dir_real,
    install_url          => 'http://wordpress.org',
    version              => '4.3.6',
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
    notify               => Service['nginx'],
  }

  if $source =~ /^https:\/\/github.com/ {

    file { "${install_dir_real}/git":
      ensure => directory,
      owner  => root,
      group  => root,
      mode   => '0755',
    }

    vcsrepo { "${install_dir_real}/git/rgbank":
      ensure   => present,
      provider => git,
      source   => $source,
      revision => $version,
      require  => File["${install_dir_real}/git"],
    }

    file { "${install_dir_real}/wp-content/themes/rgbank":
      ensure  => link,
      target  => "${install_dir_real}/git/rgbank/src",
      require => [
        Vcsrepo["${install_dir_real}/git/rgbank"],
        Wordpress::Instance::App["rgbank_${name}"],
      ],
    }

  } else {
    archive { "rgbank-build-${version}-${name}":
      ensure     => present,
      url        => $source,
      target     => "${install_dir_real}/wp-content/themes/rgbank",
      checksum   => false,
      src_target => '/tmp',
      require    => [
        Wordpress::Instance::App["rgbank_${name}"],
      ],
    }
  }

  file { "${install_dir_real}/wp-content/uploads":
    ensure  => directory,
    owner   => $::nginx::config::global_owner,
    group   => $::nginx::config::global_group,
    recurse => true,
    require => Wordpress::Instance::App["rgbank_${name}"],
  }

  if $::selinux == true {
    exec{"selinux-update-${install_dir_real}":
      path        => $::path,
      command     => "chcon -R system_u:object_r:usr_t:s0 ${install_dir_real}",
      subscribe   => Wordpress::Instance::App["rgbank_${name}"],
      refreshonly => true,
      require     => File["${install_dir_real}/wp-content/uploads"],
    }
  }

  nginx::resource::location { "${name}_root":
    ensure      => present,
    vhost       => "${::fqdn}-${name}",
    location    => '~ \.php$',
    index_files => ['index.php'],
    fastcgi     => "127.0.0.1:9000",
    www_root    => $install_dir_real,
    fastcgi_script  => undef,
  }

  nginx::resource::vhost { "${::fqdn}-${name}":
    listen_port    => $listen_port,
    www_root       => $install_dir_real,
    index_files    => [ 'index.php' ],
    fastcgi_script => undef,
  }
}
