class rgbank::web::docker {
  $install_dir = "/opt/rgbank-web"
  $listen_port = '80'
  
  archive { "rgbank-build-43":
    ensure     => present,
    url        => 'http://10.32.173.237/builds/rgbank-web-component/rgbank-build-43.tar.gz',
    target     => "${install_dir}/wp-content/themes/rgbank",
    checksum   => false,
    src_target => '/tmp',
    require    => Wordpress::Instance::App["rgbank_web"],
  }
  
  wordpress::instance::app { "rgbank_web":
    install_dir          => $install_dir,
    install_url          => 'http://wordpress.org',
    version              => '4.5.2',
    wp_owner             => 'root',
    wp_group             => '0',
    wp_config_content    => file('rgbank/wp-config.php.docker'),
  }
  
  file { "${install_dir}/wp-content/uploads":
    ensure  => directory,
    owner   => apache,
    group   => apache,
    recurse => true,
    require => Wordpress::Instance::App["rgbank_web"],
  }
  
  apache::listen { $listen_port: }
  
  apache::vhost { 'rgbank-web':
    docroot       => $install_dir,
    port          => $listen_port,
    default_vhost => true,
  }
}
