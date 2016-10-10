class rgbank::web::docker::image {
  include dummy_service
  include git
  include mysql::client
  include mysql::bindings::php

  class { 'php': 
    composer => false,
  }
  class { 'nginx': 
    require => Class['php']
  }

  $source = hiera('rgbank-build-path', 'master')
  $version = hiera('rgbank-build-version', 'https://github.com/puppetlabs/rgbank')
  $install_dir = "/opt/rgbank-web"
  $listen_port = '80'

  rgbank::web::base { 'docker-image':
    version          => $version,
    source           => $source,
    listen_port      => $listen_port,
    install_dir      => $install_dir,
    custom_wp_config => file('rgbank/wp-config.php.docker'),
  }
}
