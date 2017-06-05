class rgbank::web::docker::image {
  include dummy_service
  include git
  include mysql::client
  include mysql::bindings::php

  class { 'php': 
    composer                 => false,
  }
  class { 'nginx': 
    require => Class['php']
  }

  package { 'wget': ensure =>  installed }

  file { '/entrypoint':
    mode   => '0755',
    source => 'puppet:///rgbank/entrypoint',
  }

  $version = hiera('rgbank-build-path', 'master')
  $source = hiera('rgbank-build-version', 'http://gitlab.inf.puppet.vm/rgbank/rgbank-web.git')
  $source_type = hiera('rgbank-build-source-type', 'vcs')
  $artifactory_server = hiera('rgbank::artifactory_server', '')
  $install_dir = "/opt/rgbank-web"
  $listen_port = '8060'

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
