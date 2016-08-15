define rgbank::infrastructure::web {
  vsphere_vm { "/opdx1/vm/carl/${name}":
    esnure   => present,
    memory   => 1024,
    cpus     => 1,
    source   => '/opdx1/vm/operations/templates/cento-7-x86_64',
  }
}

Rgbank::Infratructure produces Vinfrastructure { }
