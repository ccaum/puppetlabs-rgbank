define rgbank::infrastructure::web(
  $memory = 1024,
  $cpus   = 1,
  $template = '/opdx1/vm/carl/test',
) {
  vsphere_vm { "/opdx1/vm/carl/${title}":
    ensure         => present,
    memory         => $memory,
    cpus           => $cpus,
    source         => $template,
    source_type    => 'template',
    create_command => {
      command   => '/bin/curl',
      arguments => "-k https://10.32.161.83/packages/current/install.bash | sudo bash -s agent:certname=${name}",
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
