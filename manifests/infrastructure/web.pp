define rgbank::infrastructure::web(
  $memory = 1024,
  $cpus   = 1,
  $template = '/opdx1/vm/carl/centos-7-x86_64-puppet',
  $resource_pool = '/general1',
) {

  vsphere_vm { "/opdx1/vm/carl/${title}":
    ensure         => present,
    memory         => $memory,
    cpus           => $cpus,
    source         => $template,
    source_type    => 'template',
    resource_pool  => $resource_pool,
    create_command => {
      command   => '/bin/sleep',
      arguments => "30; /bin/curl -k https://10.32.161.83:8140/packages/puppet_provision.bash | bash -l -s appserver ${title} Sup3rs3cr3t",
      user      => 'root',
      password  => 'puppetlabs',
    }
  }
}

Rgbank::Infrastructure::Web produces Vinfrastructure {
  memory   => $memory,
  cpus     => $cpus,
  template => $template,
}
