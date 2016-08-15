define rgbank::infrastructure::web() {
  vsphere_vm { "/opdx1/vm/carl/${name}":
    ensure         => present,
    memory         => 1024,
    cpus           => 1,
    source         => '/opdx1/vm/operations/templates/cento-7-x86_64',
    source_type    => 'template',
    create_command => {
      command   => '/bin/curl',
      arguments => '-k https://10.32.161.83/packages/current/install.bash | sudo bash',
      user      => 'root',
      password  => 'puppetlabs',
    }
  }
}

Rgbank::Infratructure produces Vinfrastructure { }
