define rgbank::web::base(
  $version,
  $source,
  $source_type,
  $listen_port,
  $install_dir,
  $db_name = undef,
  $db_user = undef,
  $db_password = undef,
  $db_host = undef,
  $custom_wp_config = undef,
  $artifactory_server = puppetdb_query('inventory[facts] { trusted.extensions.pp_role = "artifactory" }')[0]['facts']['fqdn'],
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

  case $source_type {
    'vcs': {

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
        before  => File["${install_dir_real}/wp-content/uploads"],
      }
    }

    'artifactory': {
      archive::artifactory { "rgbank-build-${version}.tar.gz":
        ensure       => present,
        url          => "http://${artifactory_server}/artifactory/rgbank-web/rgbank-build-${version}.tar.gz",
        archive_path => "${install_dir_real}/artifactory/rgbank-${version}",
        require      => File["${install_dir_real}/artifactory/rgbank-${version}"],
      }

      #artifactory::fetch_artifact { "rgbank-build":
      #  version      => $version,
      #  project      => "rgbank-web",
      #  format       => 'tar.gz',
      #  install_path => "${install_dir_real}/artifactory/rgbank-${version}",
      #  server       => "http://${artifactory_server}",
      #  filename     => "rgbank-build-${version}.tar.gz",
      #  notify       => Exec['unpack rgbank build'],
      #  require      => File["${install_dir_real}/artifactory/rgbank-${version}"],
      #}

      #exec { 'unpack rgbank build':
      #  command     => "/bin/tar -C ${install_dir_real}/artifactory/rgbank -xzf rgbank-build-${version}.tar.gz",
      #  refreshonly => true,
      #}

      file { "${install_dir_real}/artifactory":
        ensure => directory,
        owner  => root,
        group  => root,
        mode   => '0755',
        purge  => true,
        force  => true,
      }

      file { "${install_dir_real}/artifactory/rgbank-${version}":
        ensure => directory,
        owner  => root,
        group  => root,
        mode   => '0755',
      }

      file { "${install_dir_real}/wp-content/themes/rgbank":
        ensure  => link,
        target  => "${install_dir_real}/artifactory/rgbank-${version}",
        require => [
          Exec['unpack rgbank build'],
          Wordpress::Instance::App["rgbank_${name}"],
        ],
        before  => File["${install_dir_real}/wp-content/uploads"],
      }

    }

    'http': {
      archive { "rgbank-build-${version}-${name}":
        ensure     => present,
        url        => $source,
        target     => "${install_dir_real}/wp-content/themes/rgbank",
        checksum   => false,
        src_target => '/tmp',
        root_dir   => '.',
        require    => Wordpress::Instance::App["rgbank_${name}"],
        before     => File["${install_dir_real}/wp-content/uploads"],
      }
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
      require     => File["${install_dir_real}/wp-content/uploads"],
      refreshonly => true,
    }
  }

  nginx::resource::location { "${name}_root":
    ensure      => present,
    server      => "${::fqdn}-${name}",
    location    => '~ \.php$',
    index_files => ['index.php'],
    fastcgi     => "127.0.0.1:9000",
    www_root    => $install_dir_real,
    fastcgi_script  => undef,
  }

  nginx::resource::server { "${::fqdn}-${name}":
    listen_port    => $listen_port,
    www_root       => $install_dir_real,
    index_files    => [ 'index.php' ],
    fastcgi_script => undef,
  }
}
