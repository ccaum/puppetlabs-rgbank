class rgbank::web::docker::image {
  include dummy_service
  include profile::mysql::client
  include profile::apache

  $source = hiera('rgbank-build-path'),
  $version = hiera('rgbank-build-version'),
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
