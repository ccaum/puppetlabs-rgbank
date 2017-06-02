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

  $version = hiera('rgbank-build-path', 'master')
  $source = hiera('rgbank-build-version', 'https://gitlab.inf.puppet.vm/puppetlabs/rgbank')
  $source_type = hiera('rgbank-build-source-type', 'vcs')
  $artifactory_server = hiera('rgbank::artifactory_server', '')
  $install_dir = "/opt/rgbank-web"
  $listen_port = '80'

  rgbank::web::base { 'docker-image':
    version            => $version,
    source             => $source,
    source_type        => $source_type,
    listen_port        => $listen_port,
    install_dir        => $install_dir,
    artifactory_server => $artifactory_server,
    custom_wp_config   => file('rgbank/wp-config.php.docker'),
  }
}
